import XCTest
import Combine
import MosquittoC
@testable import Artemisia


@available(iOS 13.0, *)
final class ArtemisiaTests: XCTestCase {

    func testE2E() {
        let expectMosquittoDeinit = expectation(description: "Inner mosquitto instance should deinit after artemisia went out of scpoe")
        let topic = topicHelper()
        scoped {
            let expectE2EPubSub = expectation(description: "Normal end to end pub sub should work against test.mosquitto.org:1883")
            let message = "Test Message".data(using: .utf8)!
            let art = Artemisia(host:"test.mosquitto.org")
            var bag:[AnyCancellable] = []
            art.mosquitto.deinitCalled = {
                expectMosquittoDeinit.fulfill()
            }
            art.sink { (event) in
                if case .message(let m) = event {
                    XCTAssertEqual(m.payload, message)
                    expectE2EPubSub.fulfill()
                }
            }.store(in: &bag)
            art.mosquitto.subscribe(topic: topic)
            Just(message)
                .map{.message($0, options: .topic(topic))}
                .subscribe(art)
            wait(for: [expectE2EPubSub], timeout: 20)
        }
        wait(for: [expectMosquittoDeinit], timeout: 20)
    }

    func testSub() {
        let exp = expectation(description: "Normal end to end pub sub of Topic should work against test.mosquitto.org:1883")
        let message = "Test Message"
        let art = Artemisia(host:"test.mosquitto.org")
        let topic = topicHelper()
        art[topic].subscribe(exp.assertEqualOnce(val: message))
        Just(message).subscribe(art[topic])
        wait(for: [exp], timeout: 20)
    }
//
    func testMultiPub() {
        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 2
        exp.assertForOverFulfill = true
        let message = "MESSAGE"
        let art = Artemisia(host:"test.mosquitto.org")
        let topic = topicHelper()
        art.print("VV").sink { (_) in
            print("xx")
        }.cancel()
        art[topic + "/any", subscribeOptions: .subscriptionIdentifier(1)].subscribe(exp.assertEqualOnce(val: message))
        art[topic + "/+"].subscribe(exp.assertEqualOnce(val: message))
        Just(message).subscribe(art[topic + "/any"])
        wait(for: [exp], timeout: 20)
    }
//
//    static var allTests = [
//        ("testE2E", testE2E),
//    ]
}

