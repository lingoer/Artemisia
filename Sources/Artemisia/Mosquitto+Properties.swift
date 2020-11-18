//
//  Events.swift
//  Artemisia
//
//  Created by Aemaeth on 2020/10/27.
//

import Foundation
import MosquittoC


public struct WILLProperties: ExpressibleByArrayLiteral{
    public typealias ArrayLiteralElement = WILLProperties

    let build: (inout UnsafeMutablePointer<mosquitto_property>?) -> Void

    init(build: @escaping (inout UnsafeMutablePointer<mosquitto_property>?) -> Void) {
        self.build = build
    }
    
    public init(arrayLiteral elements: WILLProperties...) {
        self.init(build: { props in
            elements.forEach { $0.build(&props) }
        })
    }
    static func messageExpiryInterval(value: UInt32) -> Self {
        Self.init { (props) in
            MQTT_PROP_MESSAGE_EXPIRY_INTERVAL.tryAdd(value: value, to: &props)
        }
    }
    static func contentType(value: String) -> Self {
        Self.init { (props) in
            MQTT_PROP_CONTENT_TYPE.tryAdd(value: value, to: &props)
        }
    }
    static func responseTopic(value: String) -> Self {
        Self.init { (props) in
            MQTT_PROP_RESPONSE_TOPIC.tryAdd(value: value, to: &props)
        }
    }
    static func correlationData(value: Data) -> Self {
        Self.init { (props) in
            MQTT_PROP_CORRELATION_DATA.tryAdd(value: value, to: &props)
        }
    }
    static func subscriptionIdentifier(value: UInt32) -> Self {
        Self.init { (props) in
            MQTT_PROP_SUBSCRIPTION_IDENTIFIER.tryAdd(value: value, to: &props)
        }
    }
    static func willDelayInterval(value: UInt32) -> Self {
        Self.init { (props) in
            MQTT_PROP_WILL_DELAY_INTERVAL.tryAdd(value: value, to: &props)
        }
    }
    static func userProperties(value: [(String, String)]) -> Self {
        Self.init { (props) in
            value.forEach { (p) in
                MQTT_PROP_USER_PROPERTY.tryAdd(value: p, to: &props)
            }
        }
    }
    static func payloadFormatIndicator(value: UInt8) -> Self {
        Self.init { (props) in
            MQTT_PROP_PAYLOAD_FORMAT_INDICATOR.tryAdd(value: value, to: &props)
        }
    }
}

public struct CONNECTProperties: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = CONNECTProperties
    let build: (inout UnsafeMutablePointer<mosquitto_property>?) -> Void
    
    init(build: @escaping (inout UnsafeMutablePointer<mosquitto_property>?) -> Void) {
        self.build = build
    }
    
    public init(arrayLiteral elements: CONNECTProperties...) {
        self.init(build: { props in
            elements.forEach { $0.build(&props) }
        })
    }

    static func sessionExpiryInterval(value: UInt32) -> Self{
        Self.init { (props) in
            MQTT_PROP_SESSION_EXPIRY_INTERVAL.tryAdd(value: value, to: &props)
        }
    }
    static func authenticationMethod(value: String) -> Self{
        Self.init { (props) in
            MQTT_PROP_AUTHENTICATION_METHOD.tryAdd(value: value, to: &props)
        }
    }
    static func authenticationData(value: Data) -> Self{
        Self.init { (props) in
            MQTT_PROP_AUTHENTICATION_DATA.tryAdd(value: value, to: &props)
        }
    }
    static func requestProblemInformation(value: UInt8) -> Self {
        Self.init { (props) in
            MQTT_PROP_REQUEST_PROBLEM_INFORMATION.tryAdd(value: value, to: &props)
        }
    }
    static func requestResponseInformation(value: UInt8) -> Self {
        Self.init { (props) in
            MQTT_PROP_REQUEST_RESPONSE_INFORMATION.tryAdd(value: value, to: &props)
        }
    }
    static func receiveMaximum(value: UInt16) -> Self {
        Self.init { (props) in
            MQTT_PROP_RECEIVE_MAXIMUM.tryAdd(value: value, to: &props)
        }
    }
    static func topicAliasMaximum(value: UInt16) -> Self {
        Self.init { (props) in
            MQTT_PROP_TOPIC_ALIAS_MAXIMUM.tryAdd(value: value, to: &props)
        }
    }
    static func userProperties(value: [(String, String)]) -> Self {
        Self.init { (props) in
            value.forEach { (prop) in
                MQTT_PROP_USER_PROPERTY.tryAdd(value: prop, to: &props)
            }
        }
    }
}

protocol PropertyId {
    associatedtype ValueType
    var code: Int32 { get }
    func read_prop_value(from: UnsafeMutablePointer<mosquitto_property>?) -> [ValueType]
    func add_prop_value(_ value: ValueType, to:inout UnsafeMutablePointer<mosquitto_property>?) throws
}

extension PropertyId{
    func tryAdd(value: ValueType?, to props: inout UnsafeMutablePointer<mosquitto_property>?) {
        guard let val = value else { return }
        try? add_prop_value(val, to: &props)
    }
}

protocol ValueBasedPropertyId: PropertyId {
    var reader: ((UnsafePointer<mosquitto_property>?, Int32, UnsafeMutablePointer<ValueType>?, Bool) -> UnsafePointer<mosquitto_property>?) { get }
    var writter: ((_ proplist: UnsafeMutablePointer<UnsafeMutablePointer<mosquitto_property>?>?, _ identifier: Int32, _ value: ValueType) -> Int32) { get }
}

extension ValueBasedPropertyId where ValueType: ExpressibleByIntegerLiteral{
    func read_prop_value(from: UnsafeMutablePointer<mosquitto_property>?) -> [ValueType] {
        var values: [ValueType] = [],
            buff: ValueType = 0,
            next: UnsafePointer<mosquitto_property>? = reader(from, code, &buff, false)
        while next != nil {
            values.append(buff)
            next = reader(from, code, &buff, true)
        }
        return values
    }
    
    func add_prop_value(_ value: ValueType, to: inout UnsafeMutablePointer<mosquitto_property>?) throws {
        let rc = writter(&to, code, value)
        guard rc == 0 else { throw NSError(domain: "MQTT5PropertyError", code: Int(rc)) }
    }
}

struct ByteId: ValueBasedPropertyId {
    typealias ValueType = UInt8
    let code: Int32
    let reader = mosquitto_property_read_byte
    let writter = mosquitto_property_add_byte
}

struct UInt16Id: ValueBasedPropertyId {
    typealias ValueType = UInt16
    let code: Int32
    let reader = mosquitto_property_read_int16
    let writter = mosquitto_property_add_int16
    static let MQTT_PROP_TOPIC_ALIAS = UInt16Id(code: 18)
}

struct UInt32Id: ValueBasedPropertyId {
    typealias ValueType = UInt32
    let code: Int32
    let reader = mosquitto_property_read_int32
    let writter = mosquitto_property_add_int32
}

struct VarIntId: ValueBasedPropertyId {
    typealias ValueType = UInt32
    let code: Int32
    let reader = mosquitto_property_read_varint
    let writter = mosquitto_property_add_varint
}

struct StringPairId: PropertyId {
    typealias ValueType = (String, String)
    var code: Int32
    func read_prop_value(from: UnsafeMutablePointer<mosquitto_property>?) -> [(String, String)] {
        var values: [(String, String)] = [],
            nameBuff:UnsafeMutablePointer<Int8>? = nil,
            valueBuff:UnsafeMutablePointer<Int8>? = nil,
            next = mosquitto_property_read_string_pair(from, code, &nameBuff, &valueBuff, false)
        while next != nil {
            values.append((String(cString: nameBuff!), String(cString: valueBuff!)))
            nameBuff!.deallocate()
            nameBuff = nil
            valueBuff!.deallocate()
            valueBuff = nil
            next = mosquitto_property_read_string_pair(from, code, &nameBuff, &valueBuff, true)
        }
        return values
    }
    func add_prop_value(_ value: (String, String), to: inout UnsafeMutablePointer<mosquitto_property>?) throws {
        let rc = mosquitto_property_add_string_pair(&to, code, value.0, value.1)
        guard rc == 0 else { throw NSError(domain: "MQTT5PropertyError", code: Int(rc)) }
    }
}

struct StringId: PropertyId {
    typealias ValueType = String
    var code: Int32

    func read_prop_value(from: UnsafeMutablePointer<mosquitto_property>?) -> [String] {
        var values: [String] = [],
            buff:UnsafeMutablePointer<Int8>? = nil,
            next = mosquitto_property_read_string(from, code, &buff, false)
        while next != nil {
            values.append(String(cString: buff!))
            buff!.deallocate()
            buff = nil
            next = mosquitto_property_read_string(from, code, &buff, true)
        }
        return values
    }

    func add_prop_value(_ value: String, to: inout UnsafeMutablePointer<mosquitto_property>?) throws {
        let rc = mosquitto_property_add_string(&to, code, value)
        guard rc == 0 else { throw NSError(domain: "MQTT5PropertyError", code: Int(rc)) }
    }
}

struct BinaryId: PropertyId {
    typealias ValueType = Data
    var code: Int32
    
    func read_prop_value(from: UnsafeMutablePointer<mosquitto_property>?) -> [Data] {
        var values: [Data] = [],
            buff:UnsafeMutableRawPointer? = nil,
            len:UInt16 = 0,
            next = mosquitto_property_read_binary(from, code, &buff, &len, false)
        while next != nil {
            values.append(Data(bytes: buff!, count: Int(len)))
            buff!.deallocate()
            buff = nil
            len = 0
            next = mosquitto_property_read_binary(from, code, &buff, &len, true)
        }
        return values
    }
    
    func add_prop_value(_ value: Data, to: inout UnsafeMutablePointer<mosquitto_property>?) throws {
        var data = value
        let rc = mosquitto_property_add_binary(&to, code, &data, UInt16(value.count))
        guard rc == 0 else { throw NSError(domain: "MQTT5PropertyError", code: Int(rc)) }
    }
}

let MQTT_PROP_PAYLOAD_FORMAT_INDICATOR = ByteId(code: 1)        /* Byte :                PUBLISH, Will Properties */
let MQTT_PROP_MESSAGE_EXPIRY_INTERVAL = UInt32Id(code: 2)       /* 4 byte int :          PUBLISH, Will Properties */
let MQTT_PROP_CONTENT_TYPE = StringId(code: 3)                  /* UTF-8 string :        PUBLISH, Will Properties */
let MQTT_PROP_RESPONSE_TOPIC = StringId(code: 8)                /* UTF-8 string :        PUBLISH, Will Properties */
let MQTT_PROP_CORRELATION_DATA = BinaryId(code: 9)              /* Binary Data :         PUBLISH, Will Properties */
let MQTT_PROP_SUBSCRIPTION_IDENTIFIER = VarIntId(code: 11)      /* Variable byte int :   PUBLISH, SUBSCRIBE */
let MQTT_PROP_SESSION_EXPIRY_INTERVAL = UInt32Id(code: 17)      /* 4 byte int :          CONNECT, CONNACK, DISCONNECT */
let MQTT_PROP_ASSIGNED_CLIENT_IDENTIFIER = StringId(code: 18)   /* UTF-8 string :        CONNACK */
let MQTT_PROP_SERVER_KEEP_ALIVE = UInt16Id(code: 19)            /* 2 byte int :          CONNACK */
let MQTT_PROP_AUTHENTICATION_METHOD = StringId(code: 21)        /* UTF-8 string :        CONNECT, CONNACK, AUTH */
let MQTT_PROP_AUTHENTICATION_DATA = BinaryId(code: 22)          /* Binary Data :     `   CONNECT, CONNACK, AUTH */
let MQTT_PROP_REQUEST_PROBLEM_INFORMATION = ByteId(code: 23)    /* Byte :                CONNECT */
let MQTT_PROP_WILL_DELAY_INTERVAL = UInt32Id(code: 24)          /* 4 byte int :    `     Will properties */
let MQTT_PROP_REQUEST_RESPONSE_INFORMATION = ByteId(code: 25)   /* Byte :                CONNECT */
let MQTT_PROP_RESPONSE_INFORMATION = StringId(code: 26)         /* UTF-8 string :        CONNACK */
let MQTT_PROP_SERVER_REFERENCE = StringId(code: 28)             /* UTF-8 string :        CONNACK, DISCONNECT */
let MQTT_PROP_REASON_STRING = StringId(code: 31)                /* UTF-8 string :        All except Will properties */
let MQTT_PROP_RECEIVE_MAXIMUM = UInt16Id(code: 33)              /* 2 byte int :          CONNECT, CONNACK */
let MQTT_PROP_TOPIC_ALIAS_MAXIMUM = UInt16Id(code: 34)          /* 2 byte int :          CONNECT, CONNACK */
let MQTT_PROP_TOPIC_ALIAS = UInt16Id(code: 35)                  /* 2 byte int :          PUBLISH */
let MQTT_PROP_MAXIMUM_QOS = ByteId(code: 36)                    /* Byte :                CONNACK */
let MQTT_PROP_RETAIN_AVAILABLE = ByteId(code: 37)               /* Byte :                CONNACK */
let MQTT_PROP_USER_PROPERTY = StringPairId(code: 38)            /* UTF-8 string pair :   All */
let MQTT_PROP_MAXIMUM_PACKET_SIZE = UInt32Id(code: 39)          /* 4 byte int :          CONNECT, CONNACK */
let MQTT_PROP_WILDCARD_SUB_AVAILABLE = ByteId(code: 40)         /* Byte :                CONNACK */
let MQTT_PROP_SUBSCRIPTION_ID_AVAILABLE = ByteId(code: 41)      /* Byte :                CONNACK */
let MQTT_PROP_SHARED_SUB_AVAILABLE = ByteId(code: 42)           /* Byte :                CONNACK */

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
