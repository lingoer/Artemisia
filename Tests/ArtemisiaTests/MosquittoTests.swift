import XCTest
import MosquittoC
@testable import Artemisia


@available(iOS 13.0, *)
final class MosquittoTests: XCTestCase {

    let uuid = UUID().uuidString
    
    func testConnect() {
        let exp = expectation(description: "onConnect callback should be called with rc == 0 after connect()")
        exp.expectedFulfillmentCount = 2
        let mosquitto = Mosquitto(host: "test.mosquitto.org")

        mosquitto.callbacks.onConnect = { (rc, flags, props) in
            if rc == 0 {
                exp.fulfill()
            }
        }
        mosquitto.callbacks.onDisconnect = { (rc, props) in
            XCTAssert(false, "This callback should not be called")
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(5)) {
            exp.fulfill()
        }
        mosquitto.connect()
        wait(for: [exp], timeout: 20)
    }

    func testPubSub() {
        let expectation = XCTestExpectation(description: "E2E PubSub test")
        let mosquitto = Mosquitto(host: "test.mosquitto.org")
        let message = "Test Message".data(using: .utf8)!
        let topic = topicHelper()
        mosquitto.connect()
        mosquitto.callbacks.onMessage = { (msg, props) in
            XCTAssertEqual(message, Data(bytes: msg.payload, count: Int(msg.payloadlen)))
            expectation.fulfill()
        }
        mosquitto.subscribe(topic: topic)
        mosquitto.publish(payload: message, topic: topic)
        wait(for: [expectation], timeout: 20)
    }

    func testIntersectedWildcardTopic() {
        let expectation = XCTestExpectation(description: "PubSub with wildcard topic should be working")
        expectation.expectedFulfillmentCount = 2
        let mosquitto = Mosquitto(host: "test.mosquitto.org")
        let topic = topicHelper()
        let message = "Test Message".data(using: .utf8)!
        mosquitto.connect()
        mosquitto.callbacks.onMessage = { (msg, props) in
            XCTAssertEqual(message, Data(bytes: msg.payload, count: Int(msg.payloadlen)))
            expectation.fulfill()
        }
        mosquitto.subscribe(topic: topic + "/+", options: .qos(1))
        mosquitto.subscribe(topic: topic + "/some_topic", options: .qos(1))
        mosquitto.publish(message: .message(message, options: .topic(topic +  "/some_topic")))
        wait(for: [expectation], timeout: 20)
    }

    func testWill() {
        let expectWill = expectation(description: "Will should be published")
        let expectConnected = expectation(description: "")
        let topic = topicHelper()
        let mos = Mosquitto(host: "test.mosquitto.org")
        let message = "Test Message".data(using: .utf8)!
        mos.callbacks.onConnect = {_, _, _ in
            expectConnected.fulfill()
        }
        mos.connect()
        mos.callbacks.onMessage = { (msg, props) in
            XCTAssertEqual(message, Data(bytes: msg.payload, count: Int(msg.payloadlen)))
            expectWill.fulfill()
        }
        mos.subscribe(topic: topic)
        wait(for: [expectConnected], timeout: 10)
        scoped {
            let expectConnected = expectation(description: "deinit should be called")
            let willMos = Mosquitto(host: "test.mosquitto.org")
            willMos.callbacks.onConnect = { _, _, _ in
                expectConnected.fulfill()
            }
            willMos.setWill(message, topic: topic)
            willMos.connect()
            wait(for: [expectConnected], timeout: 20)
        }
        wait(for: [expectWill], timeout: 20)
    }

    static var allTests = [
        ("testConnect", testConnect),
        ("testPubSub", testPubSub),
        ("testIntersectedWildcardTopic", testIntersectedWildcardTopic),
        ("testWill", testWill)
    ]
}
