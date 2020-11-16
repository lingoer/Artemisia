//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/6.
//

import Foundation
import MosquittoC

@available(iOS 13, OSX 10.15, *)
public extension Artemisia {

    enum Event {
        case connect(Connect)
        case disconnect(Disconnect)
        case publish(Publish)
        case subscribe(Subscribe)
        case unsubscribe(Unsubscribe)
        case message(Mosquitto.Message)

        public struct Unsubscribe: WithUserProperty, WithReasonString {
            public var props: UnsafeMutablePointer<mosquitto_property>?
            public var messageId: Int32
        }

        public struct Subscribe: WithUserProperty, WithReasonString {
            public var props: UnsafeMutablePointer<mosquitto_property>?
            public var messageId: Int32
            public var allQos: [Int32]

        }

        public struct Publish: WithUserProperty, WithReasonString{
            public var props: UnsafeMutablePointer<mosquitto_property>?
            public var messageId: Int32
            public var reasonCode: Int32
        }

        public struct Disconnect: WithSessionExpiryInterval, WithServerReference, WithReasonString, WithUserProperty {
            public var props: UnsafeMutablePointer<mosquitto_property>?
            public var reasonCode: Int32
        }

        // these should be CONNACK?
        public struct Connect: WithSessionExpiryInterval,WithAssignedClientIdentifier,WithServerKeepAlive,WithAuthenticationData,WithAuthenticationMethod,
                               WithResponseInformation,WithServerReference,WithReasonString,WithReceiveMaximum,WithTopicAliasMaximum,
                               WithRetainAvailable,WithUserProperty,WithMaximumPacketSize,WithSubscriptionIdAvailable,WithSharedSubAvailable{
            public var props: UnsafeMutablePointer<mosquitto_property>?
            public var reasonCode: Int32
            public var flag: Int32
        }
    }
}

public protocol WithPayloadFormatIndicator: WithMQTTProps{ }
public extension WithPayloadFormatIndicator {
    var payloadFormatIndicator: UInt8? {
        MQTT_PROP_PAYLOAD_FORMAT_INDICATOR.read_prop_value(from: props).first
    }
}
public protocol WithMessageExpiryInterval: WithMQTTProps{ }
public extension WithMessageExpiryInterval {
    var messageExpiryInterval: UInt32? {
        MQTT_PROP_MESSAGE_EXPIRY_INTERVAL.read_prop_value(from: props).first
    }
}
public protocol WithContentType: WithMQTTProps{ }
public extension WithContentType {
    var contentType: String? {
        MQTT_PROP_CONTENT_TYPE.read_prop_value(from: props).first
    }
}
public protocol WithResponseTopic: WithMQTTProps{ }
public extension WithResponseTopic {
    var responseTopic: String? {
        MQTT_PROP_RESPONSE_TOPIC.read_prop_value(from: props).first
    }
}
public protocol WithCorrelationData: WithMQTTProps{ }
public extension WithCorrelationData {
    var correlationData: Data? {
        MQTT_PROP_CORRELATION_DATA.read_prop_value(from: props).first
    }
}
public protocol WithSubscriptionIdentifier: WithMQTTProps{ }
public extension WithSubscriptionIdentifier {
    var subscriptionIdentifier: UInt32? {
        MQTT_PROP_SUBSCRIPTION_IDENTIFIER.read_prop_value(from: props).first
    }
}
public protocol WithSessionExpiryInterval: WithMQTTProps{ }
public extension WithSessionExpiryInterval {
    var sessionExpiryInterval: UInt32? {
        MQTT_PROP_SESSION_EXPIRY_INTERVAL.read_prop_value(from: props).first
    }
}
public protocol WithAssignedClientIdentifier: WithMQTTProps{ }
public extension WithAssignedClientIdentifier {
    var assignedClientIdentifier: String? {
        MQTT_PROP_ASSIGNED_CLIENT_IDENTIFIER.read_prop_value(from: props).first
    }
}
public protocol WithServerKeepAlive: WithMQTTProps{ }
public extension WithServerKeepAlive {
    var serverKeepAlive: UInt16? {
        MQTT_PROP_SERVER_KEEP_ALIVE.read_prop_value(from: props).first
    }
}
public protocol WithAuthenticationMethod: WithMQTTProps{ }
public extension WithAuthenticationMethod {
    var authenticationMethod: String? {
        MQTT_PROP_AUTHENTICATION_METHOD.read_prop_value(from: props).first
    }
}
public protocol WithAuthenticationData: WithMQTTProps{ }
public extension WithAuthenticationData {
    var authenticationData: Data? {
        MQTT_PROP_AUTHENTICATION_DATA.read_prop_value(from: props).first
    }
}
public protocol WithRequestProblemInformation: WithMQTTProps{ }
public extension WithRequestProblemInformation {
    var requestProblemInformation: UInt8? {
        MQTT_PROP_REQUEST_PROBLEM_INFORMATION.read_prop_value(from: props).first
    }
}
public protocol WithWillDelayInterval: WithMQTTProps{ }
public extension WithWillDelayInterval {
    var willDelayInterval: UInt32? {
        MQTT_PROP_WILL_DELAY_INTERVAL.read_prop_value(from: props).first
    }
}
public protocol WithRequestResponseInformation: WithMQTTProps{ }
public extension WithRequestResponseInformation {
    var requestResponseInformation: UInt8? {
        MQTT_PROP_REQUEST_RESPONSE_INFORMATION.read_prop_value(from: props).first
    }
}
public protocol WithResponseInformation: WithMQTTProps{ }
public extension WithResponseInformation {
    var responseInformation: String? {
        MQTT_PROP_RESPONSE_INFORMATION.read_prop_value(from: props).first
    }
}
public protocol WithServerReference: WithMQTTProps{ }
public extension WithServerReference {
    var serverReference: String? {
        MQTT_PROP_SERVER_REFERENCE.read_prop_value(from: props).first
    }
}
public protocol WithReasonString: WithMQTTProps{ }
public extension WithReasonString {
    var reasonString: String? {
        MQTT_PROP_REASON_STRING.read_prop_value(from: props).first
    }
}
public protocol WithReceiveMaximum: WithMQTTProps{ }
public extension WithReceiveMaximum {
    var receiveMaximum: UInt16? {
        MQTT_PROP_RECEIVE_MAXIMUM.read_prop_value(from: props).first
    }
}
 protocol WithTopicAliasMaximum: WithMQTTProps{ }
 extension WithTopicAliasMaximum {
    public var topicAliasMaximum: UInt16? {
        MQTT_PROP_TOPIC_ALIAS_MAXIMUM.read_prop_value(from: props).first
    }
}
public protocol WithTopicAlias: WithMQTTProps{ }
public extension WithTopicAlias {
    var topicAlias: UInt16? {
        MQTT_PROP_TOPIC_ALIAS.read_prop_value(from: props).first
    }
}
public protocol WithMaximumQos: WithMQTTProps{ }
public extension WithMaximumQos {
    var maximumQos: UInt8? {
        MQTT_PROP_MAXIMUM_QOS.read_prop_value(from: props).first
    }
}
public protocol WithRetainAvailable: WithMQTTProps{ }
public extension WithRetainAvailable {
    var retainAvailable: UInt8? {
        MQTT_PROP_RETAIN_AVAILABLE.read_prop_value(from: props).first
    }
}
public protocol WithUserProperty: WithMQTTProps{ }
public extension WithUserProperty {
    var userProperty: [(String, String)] {
        MQTT_PROP_USER_PROPERTY.read_prop_value(from: props)
    }
}
public protocol WithMaximumPacketSize: WithMQTTProps{ }
public extension WithMaximumPacketSize {
    var maximumPacketSize: UInt32? {
        MQTT_PROP_MAXIMUM_PACKET_SIZE.read_prop_value(from: props).first
    }
}
public protocol WithWildcardSubAvailable: WithMQTTProps{ }
public extension WithWildcardSubAvailable {
    var wildcardSubAvailable: UInt8? {
        MQTT_PROP_WILDCARD_SUB_AVAILABLE.read_prop_value(from: props).first
    }
}
public protocol WithSubscriptionIdAvailable: WithMQTTProps{ }
public extension WithSubscriptionIdAvailable {
    var subscriptionIdAvailable: UInt8? {
        MQTT_PROP_SUBSCRIPTION_ID_AVAILABLE.read_prop_value(from: props).first
    }
}
public protocol WithSharedSubAvailable: WithMQTTProps{ }
public extension WithSharedSubAvailable {
    var sharedSubAvailable: UInt8? {
        MQTT_PROP_SHARED_SUB_AVAILABLE.read_prop_value(from: props).first
    }
}

public protocol WithMQTTProps {
    var props: UnsafeMutablePointer<mosquitto_property>? { get }
}
