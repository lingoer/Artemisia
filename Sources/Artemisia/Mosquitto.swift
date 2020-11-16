//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/6.
//

import Foundation
import Combine
import MosquittoC

public protocol TransmittableByMQTT {
    func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message
    static func fromMessage(message: Mosquitto.Message) -> Self
}

extension Mosquitto.Message: TransmittableByMQTT{
    public func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message{
        self
    }
    public static func fromMessage(message: Mosquitto.Message) -> Self{
        message
    }
}

extension Data: TransmittableByMQTT{
    
    public func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message{
        .message(self, options: defaultOptions)
    }
    
    public static func fromMessage(message: Mosquitto.Message) -> Self{
        message.payload
    }
}

extension String: TransmittableByMQTT{
    public func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message{
        .message(data(using: .utf8)!, options: defaultOptions)
    }
    
    public static func fromMessage(message: Mosquitto.Message) -> Self{
        String(data: message.payload, encoding: .utf8)!
    }
}

public final class Mosquitto {
    
    public var host: String

    public var port: Int32

    public var username: String? = nil

    public var password: String? = nil

    public var clientId: String? = nil

    public var keepAlive: Int32 = 60

    public var cleanSession: Bool = true

    public var protocolVersion: ProtocolVersion = .v5

    public var receiveMaximum: Int32 = 20

    public var sendMaximum: Int32 = 20

    public var tlsCert: TLSCert? = nil

    public var tlsVersion: TLSVersion = .tlsv1_2

    public var tlsCiphers: String? = nil

    public var tlsClientCert: (certfile: String, keyfile: String)? = nil

    public var sslContext:UnsafeMutableRawPointer? = nil

    public var sslContextWithDefaults: Bool = true

    public var tlsOCSPRequired: Bool = false

    public var tlsEngine: String? = nil

    public var tlsKeyform: String? = nil

    public var tlsKeyPassSHA1: String? = nil

    public var tlsALPN: String? = nil

    // Debug Only
    public var tlsInsecure: Bool = false

    // Debug Only
    public var tlsCertRequired: Bool = true

    let _mosq: UnsafeMutablePointer<mosquitto>
    
    let queue = DispatchQueue(label: "Mosquitto.Serial")

    public init(host: String, port: Int32? = nil, version: ProtocolVersion = .v5, username: String? = nil, password: String? = nil,
                clientId: String? = nil, cleanSession: Bool = true, keepAlive: Int32 = 60,
                receiveMaximum: Int32 = 20, sendMaximum: Int32 = 20, tlsCert: TLSCert? = nil) {
        mosquitto_lib_init()
        self.protocolVersion = version
        self.receiveMaximum = receiveMaximum
        self.sendMaximum = sendMaximum
        self.host = host
        self.port = port ?? ((tlsCert == nil) ? 1883 : 8883)
        self.username = username
        self.password = password
        self.clientId = clientId
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.tlsCert = tlsCert
        self._mosq = mosquitto_new(clientId, cleanSession, &callbacks)

    }

    private func setupMosquitto() {
        mosquitto_int_option(_mosq, MOSQ_OPT_PROTOCOL_VERSION, protocolVersion.rawValue)
        if protocolVersion == .v5 {
            mosquitto_int_option(_mosq, MOSQ_OPT_SEND_MAXIMUM, sendMaximum)
            mosquitto_int_option(_mosq, MOSQ_OPT_RECEIVE_MAXIMUM, receiveMaximum)
        }
        if let tls = tlsCert {
            switch tls {
            case let .cafile(filepath):
                mosquitto_tls_set(_mosq, filepath, nil,
                                  tlsClientCert?.certfile,
                                  tlsClientCert?.keyfile,
                                  nil)
            case let .psk(psk, identity, ciphers):
                mosquitto_tls_psk_set(_mosq, psk,
                                      identity,
                                      ciphers)
            }
            sslContext.withValue{mosquitto_void_option(_mosq, MOSQ_OPT_SSL_CTX, $0)}
            mosquitto_int_option(_mosq, MOSQ_OPT_SSL_CTX_WITH_DEFAULTS, sslContextWithDefaults ? 1 : 0)
            mosquitto_int_option(_mosq, MOSQ_OPT_TLS_OCSP_REQUIRED, tlsOCSPRequired ? 1 : 0)
            tlsEngine.withValue{mosquitto_string_option(_mosq, MOSQ_OPT_TLS_ENGINE, $0)}
            tlsKeyform.withValue{mosquitto_string_option(_mosq, MOSQ_OPT_TLS_KEYFORM, $0)}
            tlsKeyPassSHA1.withValue{mosquitto_string_option(_mosq, MOSQ_OPT_TLS_ENGINE_KPASS_SHA1, $0)}
            tlsALPN.withValue{mosquitto_string_option(_mosq, MOSQ_OPT_TLS_ALPN, $0)}
            mosquitto_tls_insecure_set(_mosq, tlsInsecure)
            mosquitto_tls_opts_set(_mosq, tlsCertRequired ? 1 : 0, tlsVersion.rawValue, tlsCiphers)
        }
        mosquitto_loop_start(_mosq)
    }

    var callbacks = CallbackWrapper()
    var isInitialState: Bool {
        _mosq.pointee.state == mosq_cs_new
    }
    public var connected: Bool{
        callbacks.connected
    }
    
    class CallbackWrapper: NSObject {
        var connected: Bool = false
        
        var onDisconnect: ((_ rc: Int32, _ props: UnsafePointer<mosquitto_property>?) -> Void)?
        var onConnect:((_ rc: Int32, _ flag: Int32, _ props: UnsafePointer<mosquitto_property>?) -> Void)?
        var onPublish:((_ rc: Int32, _ mid: Int32, _ props: UnsafePointer<mosquitto_property>?) -> Void)?
        var onSubscribe:((_ mid: Int32, _ grantedQos: [Int32], _ props: UnsafePointer<mosquitto_property>?) -> Void)?
        var onUnsubscribe:((_ mid: Int32, _ props: UnsafePointer<mosquitto_property>?) -> Void)?
        var onMessage:((_ message: mosquitto_message, _ props: UnsafePointer<mosquitto_property>?) -> Void)?
    }

    private func setupCallbacks() {
        mosquitto_disconnect_v5_callback_set(_mosq) { (_, pointer, rc, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee{
                callbacks.connected = false
                callbacks.onDisconnect?(rc, props)
            }
        }
        mosquitto_connect_v5_callback_set(_mosq) { (_, pointer, rc, flag, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee{
                callbacks.connected = true
                callbacks.onConnect?(rc, flag, props)
            }
        }
        mosquitto_publish_v5_callback_set(_mosq) { (_, pointer, mid, rc, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee{
                callbacks.onPublish?(rc, mid, props)
            }
        }
        mosquitto_subscribe_v5_callback_set(_mosq) { (_, pointer, mid, qosCount, grantedQos, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee {
                let allQos = Array(UnsafeBufferPointer(start: grantedQos, count: Int(qosCount)))
                callbacks.onSubscribe?(mid, allQos, props)
            }
        }
        mosquitto_unsubscribe_v5_callback_set(_mosq) { (_, pointer, mid, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee {
                callbacks.onUnsubscribe?(mid, props)
            }
        }
        mosquitto_message_v5_callback_set(_mosq) { (_, pointer, msgP, props) in
            if let callbacks = pointer?.assumingMemoryBound(to: CallbackWrapper.self).pointee,
               let msg = msgP?.pointee {
                callbacks.onMessage?(msg, props)
            }
        }
    }

    public func connect(properties: CONNECTProperties = []) {
        queue.async { [self] in
            var props:UnsafeMutablePointer<mqtt5__property>? = nil
            if protocolVersion == .v5{
                properties.build(&props)
            }
            setupMosquitto()
            setupCallbacks()
            mosquitto_connect_bind_v5(_mosq, host, port, keepAlive, nil, props)
//            let thread = Thread{[weak self] in
//                var rc:Int32 = MOSQ_ERR_SUCCESS.rawValue
//                while rc == MOSQ_ERR_SUCCESS.rawValue{
//                    RunLoop.current.run()
//                    rc = mosquitto_loop(self?._mosq, -1, 1)
//                }
//                print("===========================")
//                print("rc:\(rc)")
//            }
//            thread.start()
        }
    }

    
    public struct Message: WithPayloadFormatIndicator, WithMessageExpiryInterval, WithContentType, WithResponseTopic, WithCorrelationData,
                           WithSubscriptionIdentifier, WithTopicAlias, WithUserProperty {
        public var payload: Data
        public var topic: String?
        public var qos: Int32
        public var retain: Bool
        public var props: UnsafeMutablePointer<mosquitto_property>?
        public var messageId: Int32

        init(payload: Data, topic: String? = nil, qos: Int32 = 0, retain: Bool = false,
             props: UnsafeMutablePointer<mosquitto_property>? = nil, messageId: Int32 = 0) {
            self.payload = payload
            self.topic = topic
            self.qos = qos
            self.retain = retain
            self.props = props
            self.messageId = messageId
        }
        
        public static func message(_ payload: Data, options: PublishOptions = []) -> Message {
            var props: UnsafeMutablePointer<mosquitto_property>?
            options.buildProps(&props)
            return Message(payload: payload, topic: options.topic, qos: options.qos ?? 0, retain: options.retain ?? false, props: props)
        }
    }
    
    public func setWill(_ payload: Data, topic: String?, qos: Int32 = 0,
                        retain: Bool = false, properties: WILLProperties = []){
        queue.async {[self] in
            var d = payload, props: UnsafeMutablePointer<mosquitto_property>? = nil
            if protocolVersion == .v5{
                properties.build(&props)
            }
            mosquitto_will_set_v5(_mosq, topic, Int32(d.count), &d, qos, retain, props)
        }
    }
    
    public func clearWill(){
        queue.async {[self] in
            mosquitto_will_clear(_mosq)
        }
    }

    public func disconnect(reasonCode: Int32 = 0, sessionExpiryInterval: UInt32? = nil, userProperties: [(String, String)]? = nil) {
        queue.async {[self] in
            var props: UnsafeMutablePointer<mosquitto_property>? = nil
            if protocolVersion == .v5{
                userProperties?.forEach({ (prop) in
                    MQTT_PROP_USER_PROPERTY.tryAdd(value: prop, to: &props)
                })
                MQTT_PROP_SESSION_EXPIRY_INTERVAL.tryAdd(value: sessionExpiryInterval, to: &props)
            }
            mosquitto_disconnect_v5(_mosq, protocolVersion == .v5 ? reasonCode : 0, props)
        }
    }

    public func unsubscribe(topic: String, userProperties:[(String, String)]?) {
        queue.async {[self] in
            var mid: Int32 = 0, props: UnsafeMutablePointer<mosquitto_property>? = nil
            if protocolVersion == .v5{
                userProperties?.forEach({ (prop) in
                    MQTT_PROP_USER_PROPERTY.tryAdd(value: prop, to: &props)
                })
            }
            mosquitto_unsubscribe_v5(_mosq, &mid, topic, props)
        }
    }

    var deinitCalled:(()->Void)?
    
    deinit {
        deinitCalled?()
        mosquitto_destroy(_mosq)
    }
}

public extension Mosquitto{
    enum ProtocolVersion: Int32 {
        case v31 = 3
        case v311 = 4
        case v5 = 5
    }

    enum TLSCert {
        case cafile(String)
        case psk(psk: String, identity: String, ciphers: String?)
    }

    enum QOS: Int32 {
        case q0 = 0
        case q1 = 1
        case q2 = 2
    }

    enum TLSVersion: String {
        case tlsv1      = "tlsv1"
        case tlsv1_1    = "tlsv1.1"
        case tlsv1_2    = "tlsv1.2"
    }
}

private extension Optional{
    func withValue(_ f: ((Wrapped) -> Void)) {
        if case let .some(value) = self {
            f(value)
        }
    }
}

