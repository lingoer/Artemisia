//
//  File.swift
//  
//
//  Created by Aemaeth on 2020/11/10.
//

import XCTest
import Combine

func topicHelper(file:NSString = #file, function: String = #function) -> String {
    "artemisia_testing/" + UUID().uuidString + "/" + file.lastPathComponent + "/" + function
}

extension XCTestCase{
    func scoped(closure: ()->Void) {
        closure()
    }
}
extension XCTestExpectation{
    @available(iOS 13.0, *)
    func assertEqualOnce<T:Equatable>(val:T) -> AnySubscriber<T, Never> {
        AnySubscriber(receiveSubscription:{
            $0.request(.unlimited)
        }, receiveValue: {
            XCTAssertEqual(val, $0)
            self.fulfill()
            return .none
        })
    }
}
