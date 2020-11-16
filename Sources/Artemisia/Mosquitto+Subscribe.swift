//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/13.
//

import MosquittoC

public extension Mosquitto{
    struct SubscribeOptions: ExpressibleByArrayLiteral {
        
        let qosVal: Int32?
        let buildProps: (inout UnsafeMutablePointer<mosquitto_property>?) -> Void
        let subOptions: UInt32
        private init(qos: Int32? = nil, subOptions: UInt32 = 0, build: @escaping (inout UnsafeMutablePointer<mosquitto_property>?) -> Void = {_ in}) {
            self.qosVal = qos
            self.buildProps = build
            self.subOptions = subOptions
        }
        
        public typealias ArrayLiteralElement = SubscribeOptions
        public init(arrayLiteral elements: ArrayLiteralElement...) {
            let qos = elements.reduce(nil, {$0 ?? $1.qosVal})
            let options = elements.reduce(0, {$0 | $1.subOptions})
            self.init(qos: qos, subOptions: options, build: { props in
                elements.forEach { $0.buildProps(&props) }
            })
        }
        
        public static func qos(_ q:Int32) -> SubscribeOptions{
            SubscribeOptions(qos: q)
        }
        
        var subscriptionIdentifier:UInt32? {
            var props:UnsafeMutablePointer<mosquitto_property>? = nil
            buildProps(&props)
            return MQTT_PROP_SUBSCRIPTION_IDENTIFIER.read_prop_value(from: props).first
        }
        
        public static func subscriptionIdentifier(_ id:UInt32) -> SubscribeOptions{
            SubscribeOptions(build:{
                MQTT_PROP_SUBSCRIPTION_IDENTIFIER.tryAdd(value: id, to: &$0)
            })
        }
        
        public static func userProperties(_ properties:[(String, String)]) -> SubscribeOptions{
            SubscribeOptions(build:{ props in
                properties.forEach { (p) in
                    MQTT_PROP_USER_PROPERTY.tryAdd(value: p, to: &props)
                }
            })
        }

        public static var noLocal: Self = SubscribeOptions(subOptions: MQTT_SUB_OPT_NO_LOCAL.rawValue)
        public static var retainAsPublished: Self = SubscribeOptions(subOptions: MQTT_SUB_OPT_RETAIN_AS_PUBLISHED.rawValue)
        public static var sendRetainAlways: Self = SubscribeOptions(subOptions: MQTT_SUB_OPT_SEND_RETAIN_ALWAYS.rawValue)
        public static var sendRetainNew: Self = SubscribeOptions(subOptions: MQTT_SUB_OPT_SEND_RETAIN_NEW.rawValue)
        public static var sendRetainNever: Self = SubscribeOptions(subOptions: MQTT_SUB_OPT_SEND_RETAIN_NEVER.rawValue)

    }
    
    func subscribe(topic: String, options: SubscribeOptions = [], getMessageId:((Int32)->Void)? = nil)
    {
        queue.async { [self] in
            var props: UnsafeMutablePointer<mosquitto_property>? = nil, mid: Int32 = 0
            if protocolVersion == .v5{
                options.buildProps(&props)
            }
            mosquitto_subscribe_v5(_mosq, &mid, topic, options.qosVal ?? 0, protocolVersion == .v5 ? Int32(options.subOptions) : 0, props)
            getMessageId?(mid)
        }
    }

}
