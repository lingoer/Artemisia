import XCTest
import Combine
import MosquittoC
@testable import Artemisia


@available(iOS 13.0, *)
final class ArtemisiaTests: XCTestCase {
    
    func testPubSub() {
        let exp = expectation(description: "Assure no refrence cycle")
        scoped {
            let message = "Test Message"
            let expectRecv = expectation(description: "we should receive message from pub")
            let client = Artemisia.connect(host:"test.mosquitto.org")
            let topic = topicHelper()
            let scopedCancel = client[topic].sink(receiveValue: expectRecv.fulfill(onEqual: message))
            defer{ scopedCancel.cancel() }
            client[topic].publish(message: message)
            client.mosquitto.deinitCalled = exp.fulfill
            wait(for: [expectRecv], timeout: 20)
        }
        wait(for: [exp], timeout: 20)
    }
    

    func testMultiPub() {
        let exp1 = expectation(description: "with v5 subscriptionIdentifier")
        let exp2 = expectation(description: "without v5 subscriptionIdentifier")
        let message = "MESSAGE"
        let client = Artemisia.connect(host:"test.mosquitto.org", version: .v5)
        let topic = topicHelper()
        var bag:[AnyCancellable] = []
        client[topic + "/any", subscribeOptions: .subscriptionIdentifier(1)].sink(receiveValue: exp1.fulfill(onEqual: message)).store(in: &bag)
        client[topic + "/+"].sink(receiveValue: exp2.fulfill(onEqual: message)).store(in: &bag)
        client.publish(message: message, options: .topic(topic + "/any"))
        wait(for: [exp1, exp2], timeout: 20)
    }

    static var allTests = [
        ("testPubSub", testPubSub),
        ("testMultiPub", testMultiPub)
    ]
}

