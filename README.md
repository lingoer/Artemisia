# Artemisia

[![Build Status](https://travis-ci.org/lingoer/Artemisia.svg?branch=main)](https://travis-ci.org/lingoer/Artemisia)

Artemisia is a MQTT5 client in Swift. (based on libmosquitto)
As far as I know, currently its possibly the only one library supports MQTT5 on iOS/Macos platforms.
#### Features:
  - MQTT version 5.0 supported. (as well as 3.1 & 3.1.1)
  - TLS supported.
  - Easy to use interfaces with Combine. (and RxSwift, WIP)
  - iOS / Macos / Linux (No Combine interfaces on linux)

#### Usage:
with Combine:
```swift
let client = Artemisia.connect(host:"test.mosquitto.org")
// client["topic"] gives you a Publisher<T> where T: MQTTTransmittable. You can add this conformance to your own model so that you can get your model directly from the publisher
client["awesome/topic"].sink{ (msg: String) in
    print(msg)
}.store(in: bag)
client["awesome/topic"].publish(message: "some message")
```
without Combine:
```swift
let mosquitto = Mosquitto(host: "test.mosquitto.org")
mosquitto.connect()
mosquitto.callbacks.onMessage = { (msg) in
    // you get the mqtt message
}
mosquitto.subscribe(topic: "awesome/+/topic", options: .qos(1))
mosquitto.publish(message: .message(data, options: [.topic("awesome/+/topic", .qos(1)])))

```
A demo project is inside ArtemisiaExample directory to show the basic usage.
#### TODOs:
* Documentation
* RxSwift supports
