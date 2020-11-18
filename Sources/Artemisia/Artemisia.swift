import Combine
import Foundation
import MosquittoC

@available(iOS 13.0,macOS 10.15, *)
public class Artemisia {

    let subject: PassthroughSubject<Artemisia.Event, Never>
    let mosquitto: Mosquitto

    // TODO: reconnect intervals
    public static func connect(host: String, port: Int32? = nil, version: Mosquitto.ProtocolVersion = .v5,
                               username: String? = nil, password: String? = nil,
                               clientId: String? = nil, cleanSession: Bool = true, keepAlive: Int32 = 60,
                               tlsCert: Mosquitto.TLSCert? = nil, properties: CONNECTProperties = []) -> Artemisia{
        return Artemisia(host: host, port: port, version: version, username: username,
                         password: password, clientId: clientId, cleanSession: cleanSession,
                         keepAlive: keepAlive, tlsCert: tlsCert, connectProperties: properties)
    }

    private init(host: String, port: Int32? = nil, version: Mosquitto.ProtocolVersion = .v5,
                username: String? = nil, password: String? = nil,
                clientId: String? = nil, cleanSession: Bool = true, keepAlive: Int32 = 60,
                tlsCert: Mosquitto.TLSCert? = nil, connectProperties: CONNECTProperties = []) {
        mosquitto = Mosquitto(host:host, port: port, version: version,
                              username: username, password: password,
                              clientId: clientId, cleanSession: cleanSession,
                              keepAlive: keepAlive, tlsCert: tlsCert)
        let subject = PassthroughSubject<Artemisia.Event, Never>()
        mosquitto.callbacks.onConnect = {
            subject.send(.connect($0))
        }
        mosquitto.callbacks.onDisconnect = {
            subject.send(.disconnect($0))
        }
        mosquitto.callbacks.onSubscribe = {
            subject.send(.subscribe($0))
        }
        mosquitto.callbacks.onUnsubscribe = {
            subject.send(.unsubscribe($0))
        }
        mosquitto.callbacks.onPublish = {
            subject.send(.publish($0))
        }
        mosquitto.callbacks.onMessage = {
            subject.send(.message($0))
        }
        self.subject = subject
        mosquitto.connect(properties: connectProperties)
    }

    public func publish<T:MQTTTransmittable>(message: T, options: Mosquitto.PublishOptions = []) {
        mosquitto.publish(message: message.toMessage(options: options))
    }

}

@available(iOS 13, OSX 10.15, *)
public extension Artemisia {

    enum Event {
        case connect(Mosquitto.MQTTConnact)
        case disconnect(Mosquitto.MQTTDisconnect)
        case publish(Mosquitto.MQTTPublish)
        case subscribe(Mosquitto.MQTTSubscribe)
        case unsubscribe(Mosquitto.MQTTUnsubscribe)
        case message(Mosquitto.Message)
    }
    
}

@available(iOS 13.0, macOS 10.15, *)
public extension Artemisia {

    subscript<T:MQTTTransmittable>(pattern: String,
                                     ofType type:T.Type = T.self,
                                     subscribeOptions subscribeOptions:Mosquitto.SubscribeOptions = [],
                                     publishOptions publishOptions: Mosquitto.PublishOptions = []) -> Topic<T> {
        return Topic(pattern: pattern, subscribeOptions: subscribeOptions, publishOptions: publishOptions, artemisia: self)
    }

    struct Topic<T:MQTTTransmittable> {

        public let pattern: String
        public let artemisia: Artemisia
        public var subscribeOptions: Mosquitto.SubscribeOptions
        public var publishOptions: Mosquitto.PublishOptions
        public let combineIdentifier = CombineIdentifier()

        init(pattern: String, subscribeOptions: Mosquitto.SubscribeOptions, publishOptions: Mosquitto.PublishOptions, artemisia: Artemisia) {
            self.pattern = pattern
            self.subscribeOptions = subscribeOptions
            self.publishOptions = [publishOptions, .topic(pattern)]
            self.artemisia = artemisia
        }

        public func publish(message: T) {
            artemisia.mosquitto.publish(message: message.toMessage(options: publishOptions))
        }
    }
}

@available(iOS 13.0,macOS 10.15, *)
extension Artemisia.Topic: Publisher{
    public typealias Failure = Never
    public typealias Output = T

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input{
        artemisia.subject
            .compactMap({ (event) -> Mosquitto.Message? in
                var result = false
                guard case let .message(msg) = event,
                      0 == mosquitto_topic_matches_sub(pattern, msg.topic, &result),
                      result
                else{ return nil }
                if artemisia.mosquitto.protocolVersion == .v5 && msg.subscriptionIdentifier != subscribeOptions.subscriptionIdentifier{
                    return nil
                }
                return msg
            })
            .map(T.fromMessage)
            .receive(subscriber: subscriber)
        artemisia.mosquitto.subscribe(topic: pattern, options: subscribeOptions)
    }
}

