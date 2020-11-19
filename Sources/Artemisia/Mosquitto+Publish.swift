//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/13.
//
import Foundation
import MosquittoC

public extension Mosquitto{
    
    struct PublishOptions: ExpressibleByArrayLiteral {
        public let topic: String?
        public let qos: Int32?
        public let retain: Bool?
        let buildProps: (inout UnsafeMutablePointer<mosquitto_property>?) -> Void
        
        public typealias ArrayLiteralElement = Self
        init(topic: String? = nil, qos: Int32? = nil, retain: Bool? = nil, build: @escaping (inout UnsafeMutablePointer<mosquitto_property>?) -> Void) {
            self.topic = topic
            self.qos = qos
            self.retain = retain
            self.buildProps = build
        }
        
        public init(arrayLiteral elements: ArrayLiteralElement...) {
            let topic = elements.reduce(nil, {$0 ?? $1.topic})
            let qos = elements.reduce(nil, {$0 ?? $1.qos})
            let retain = elements.reduce(nil, {$0 ?? $1.retain})
            self.init(topic: topic, qos: qos, retain: retain, build: { props in
                elements.forEach { $0.buildProps(&props) }
            })
        }
        
        public static func topic(_ topic: String) -> Self {
            PublishOptions(topic: topic) {_ in}
        }
        
        public static func qos(_ qos: Int32) -> Self {
            PublishOptions(qos: qos) {_ in}
        }
        
        public static func retain(_ retain: Bool) -> Self {
            PublishOptions(retain: retain) {_ in}
        }
        
        public static func messageExpiryInterval(_ value: UInt32) -> Self {
            Self.init { (props) in
                MQTT_PROP_MESSAGE_EXPIRY_INTERVAL.tryAdd(value: value, to: &props)
            }
        }
        public static func contentType(_ value: String) -> Self {
            Self.init { (props) in
                MQTT_PROP_CONTENT_TYPE.tryAdd(value: value, to: &props)
            }
        }
        public static func responseTopic(_ value: String) -> Self {
            Self.init { (props) in
                MQTT_PROP_RESPONSE_TOPIC.tryAdd(value: value, to: &props)
            }
        }
        public static func correlationData(_ value: Data) -> Self {
            Self.init { (props) in
                MQTT_PROP_CORRELATION_DATA.tryAdd(value: value, to: &props)
            }
        }
        public static func subscriptionIdentifier(_ value: UInt32) -> Self {
            Self.init { (props) in
                MQTT_PROP_SUBSCRIPTION_IDENTIFIER.tryAdd(value: value, to: &props)
            }
        }
        public static func topicAlias(_ value: UInt16) -> Self {
            Self.init { (props) in
                MQTT_PROP_TOPIC_ALIAS.tryAdd(value: value, to: &props)
            }
        }
        public static func userProperties(_ value: [(String, String)]) -> Self {
            Self.init { (props) in
                value.forEach { (p) in
                    MQTT_PROP_USER_PROPERTY.tryAdd(value: p, to: &props)
                }
            }
        }
        public static func payloadFormatIndicator(_ value: UInt8) -> Self{
            Self.init { (props) in
                MQTT_PROP_PAYLOAD_FORMAT_INDICATOR.tryAdd(value: value, to: &props)
            }
        }


    }

    func publish(message:Message) {
        publish(payload: message.payload, topic: message.topic, qos: message.qos, retain: message.retain,
                payloadFormatIndicator: message.payloadFormatIndicator, messageExpiryInterval: message.messageExpiryInterval,
                contentType: message.contentType, responseTopic: message.responseTopic, correlationData: message.correlationData,
                subscriptionIdentifier: message.subscriptionIdentifier, topicAlias: message.topicAlias, userProperties: message.userProperty)
    }
    
    func publish(payload: Data, topic: String?, qos: Int32 = 0, retain: Bool = false, payloadFormatIndicator: UInt8? = nil,
                        messageExpiryInterval: UInt32? = nil, contentType: String? = nil, responseTopic: String? = nil, correlationData: Data? = nil,
                        subscriptionIdentifier: UInt32? = nil, topicAlias: UInt16? = nil, userProperties: [(String, String)]? = nil,
                        getMessageId:((Int32)->Void)? = nil) {
        queue.async {[self] in
            var mid: Int32 = 0, props: UnsafeMutablePointer<mosquitto_property>? = nil
            if protocolVersion == .v5{
                MQTT_PROP_PAYLOAD_FORMAT_INDICATOR.tryAdd(value: payloadFormatIndicator, to: &props)
                MQTT_PROP_MESSAGE_EXPIRY_INTERVAL.tryAdd(value: messageExpiryInterval, to: &props)
                MQTT_PROP_CONTENT_TYPE.tryAdd(value: contentType, to: &props)
                MQTT_PROP_RESPONSE_TOPIC.tryAdd(value: responseTopic, to: &props)
                MQTT_PROP_CORRELATION_DATA.tryAdd(value: correlationData, to: &props)
                MQTT_PROP_SUBSCRIPTION_IDENTIFIER.tryAdd(value: subscriptionIdentifier, to: &props)
                MQTT_PROP_TOPIC_ALIAS.tryAdd(value: topicAlias, to: &props)
                userProperties?.forEach({ (prop) in
                    MQTT_PROP_USER_PROPERTY.tryAdd(value: prop, to: &props)
                })
            }
            _ = payload.withUnsafeBytes {
                mosquitto_publish_v5(_mosq, &mid, topic, Int32($0.count), $0.baseAddress, qos, retain, props)
            }
            getMessageId?(mid)
        }
    }
}
