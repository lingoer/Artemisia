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

        mosquitto.callbacks.onConnect = {
            if $0.reasonCode == 0 {
                exp.fulfill()
            }
        }
        mosquitto.callbacks.onDisconnect = {_ in
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
        mosquitto.callbacks.onMessage = {
            XCTAssertEqual(message, $0.payload)
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
        mosquitto.callbacks.onMessage = {
            XCTAssertEqual(message, $0.payload)
            expectation.fulfill()
        }
        mosquitto.subscribe(topic: topic + "/+", options: .qos(1))
        mosquitto.subscribe(topic: topic + "/some_topic", options: .qos(1))
        mosquitto.publish(message: .message(message, options: .topic(topic +  "/some_topic")))
        wait(for: [expectation], timeout: 20)
    }
    
    func testDisconnect() {
        let expectDisconn = expectation(description: "Will should be published")
        let mos = Mosquitto(host: "test.mosquitto.org")
        mos.callbacks.onDisconnect = {_ in
            expectDisconn.fulfill()
        }
        mos.callbacks.onConnect = {_ in
            mos.disconnect()
        }
        mos.connect()
        wait(for: [expectDisconn], timeout: 20)
    }

    static var allTests = [
        ("testConnect", testConnect),
        ("testPubSub", testPubSub),
        ("testIntersectedWildcardTopic", testIntersectedWildcardTopic),
    ]
}
