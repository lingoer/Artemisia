//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/7.
//

import Combine
import Foundation
import MosquittoC


@available(iOS 13.0, macOS 10.15, *)
public extension Artemisia {

    subscript<T:TransmittableByMQTT>(pattern: String,
                                     ofType type:T.Type = T.self,
                                     subscribeOptions subscribeOptions:Mosquitto.SubscribeOptions = [],
                                     publishOptions publishOptions: Mosquitto.PublishOptions = []) -> Topic<T> {
        return Topic(pattern: pattern, subscribeOptions: subscribeOptions, publishOptions: publishOptions, artemisia: self)
    }

    struct Topic<T:TransmittableByMQTT> {
        public let pattern: String
        public let artemisia: Artemisia
        public var subscribeOptions: Mosquitto.SubscribeOptions
        public var publishOptions: Mosquitto.PublishOptions
        public let combineIdentifier = CombineIdentifier()

        init(pattern: String, subscribeOptions: Mosquitto.SubscribeOptions, publishOptions: Mosquitto.PublishOptions, artemisia: Artemisia) {
            self.pattern = pattern
            self.subscribeOptions = subscribeOptions
            self.publishOptions = publishOptions
            self.artemisia = artemisia
        }
    }
}

@available(iOS 13.0,macOS 10.15, *)
extension Artemisia.Topic: Publisher{
    public typealias Failure = Never
    public typealias Output = T

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input{
        artemisia
            .compactMap({ (event) -> Mosquitto.Message? in
                var result = false
                guard case let .message(msg) = event,
                      msg.subscriptionIdentifier == subscribeOptions.subscriptionIdentifier,
                      0 == mosquitto_topic_matches_sub(pattern, msg.topic, &result),
                      result
                else{ return nil }
                return msg
            })
            .map(T.fromMessage)
            .receive(subscriber: subscriber)
        artemisia.mosquitto.subscribe(topic: pattern, options: subscribeOptions)
    }
}

@available(iOS 13.0,macOS 10.15, *)
extension Artemisia.Topic: Subscriber{

    public func receive(subscription: Subscription) {
        artemisia.receive(subscription: subscription)
    }

    public func receive(_ input: T) -> Subscribers.Demand {
        let msg = input.toMessage(options: [publishOptions, .topic(pattern)])
        return artemisia.receive(msg)
    }

    public func receive(completion: Subscribers.Completion<Never>) {
        artemisia.receive(completion: completion)
    }

}

