import Combine
import Foundation
import MosquittoC

@available(iOS 13.0,macOS 10.15, *)
public struct Artemisia {
    
    let pubsub: MosquittoPubSub
    let sharedPub: Publishers.Share<Publishers.Autoconnect<MosquittoPubSub>>
    let connected: AnyPublisher<Bool, Never>
    let mosquitto: Mosquitto
    
    public let combineIdentifier = CombineIdentifier()

    public init(host: String, port: Int32? = nil, version: Mosquitto.ProtocolVersion = .v311,
                username: String? = nil, password: String? = nil,
                clientId: String? = nil, cleanSession: Bool = true, keepAlive: Int32 = 60,
                receiveMaximum: Int32 = 20, sendMaximum: Int32 = 20, tlsCert: Mosquitto.TLSCert? = nil,
                connectProperties: CONNECTProperties = []) {
        mosquitto = Mosquitto(host:host, port: port, version: version,
                                   username: username, password: password,
                                   clientId: clientId, cleanSession: cleanSession,
                                   keepAlive: keepAlive, receiveMaximum: receiveMaximum,
                                   sendMaximum: sendMaximum, tlsCert: tlsCert)
        pubsub = MosquittoPubSub(mosquitto: mosquitto, connectProperties: connectProperties)
        connected = pubsub
            .compactMap { (event) -> Bool? in
                switch event{
                case .connect(let connack):
                    return connack.reasonCode == MQTT_RC_SUCCESS.rawValue
                case .disconnect(_):
                    return false
                default:
                    return nil
                }
            }
            .multicast(subject: CurrentValueSubject<Bool, Never>(false))
            .autoconnect()
            .eraseToAnyPublisher()
        sharedPub = pubsub.autoconnect().share()
        
    }
}

@available(iOS 13.0,macOS 10.15, *)
extension Artemisia: Subscriber {

    public func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    public func receive(_ input: Mosquitto.Message) -> Subscribers.Demand{
        connected.contains(true).map{_ in input}.subscribe(pubsub)
        return .unlimited
    }

    public func receive(completion: Subscribers.Completion<Never>) {
    }
    
}

@available(iOS 13.0,macOS 10.15, *)
extension Artemisia: Publisher {

    public typealias Output = Event
    public typealias Failure = Never
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Event == S.Input{
        sharedPub.receive(subscriber: subscriber)
    }

}

@available(iOS 13.0,macOS 10.15, *)
struct MosquittoPubSub: ConnectablePublisher, Subscriber {
    
    
    typealias Input = Mosquitto.Message
    typealias Output = Artemisia.Event
    typealias Failure = Never
    
    let combineIdentifier = CombineIdentifier()
    let mosquitto: Mosquitto
    let subject:PassthroughSubject<Artemisia.Event, Never>
    let connectProperties: CONNECTProperties


    init(mosquitto: Mosquitto, connectProperties: CONNECTProperties) {
        let subject = PassthroughSubject<Artemisia.Event, Never>()
        mosquitto.callbacks.onConnect = { (rc, flags, props) in
            subject.send(.connect(.init(props: UnsafeMutablePointer(mutating: props), reasonCode: rc, flag: flags)))
        }
        mosquitto.callbacks.onDisconnect = { (rc, props) in
            subject.send(.disconnect(.init(props: UnsafeMutablePointer(mutating: props), reasonCode: rc)))
        }
        mosquitto.callbacks.onSubscribe = { (mid, allQos, props) in
            subject.send(.subscribe(.init(props: UnsafeMutablePointer(mutating: props), messageId: mid, allQos: allQos)))
        }
        mosquitto.callbacks.onUnsubscribe = { (mid, props) in
            subject.send(.unsubscribe(.init(props: UnsafeMutablePointer(mutating: props), messageId: mid)))
        }
        mosquitto.callbacks.onPublish = { (rc, mid, props) in
            subject.send(.publish(.init(props: UnsafeMutablePointer(mutating: props), messageId: mid, reasonCode: rc)))
        }
        mosquitto.callbacks.onMessage = { (msg, props) in
            subject.send(.message(.init(payload: Data(bytes: msg.payload, count: Int(msg.payloadlen)),
                                        topic: String(cString: msg.topic),
                                        qos: msg.qos,
                                        retain: msg.retain,
                                        props: UnsafeMutablePointer(mutating: props),
                                        messageId: msg.mid)))
        }
        self.mosquitto = mosquitto
        self.subject = subject
        self.connectProperties = connectProperties
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Artemisia.Event == S.Input{
        subject.receive(subscriber: subscriber)
    }

    public func connect() -> Cancellable {
        mosquitto.connect(properties: connectProperties)
        return AnyCancellable{
            mosquitto.disconnect()
        }
    }

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
    }
    
    func receive(_ input: Mosquitto.Message) -> Subscribers.Demand {
        mosquitto.publish(message: input)
        return .unlimited
    }

}
