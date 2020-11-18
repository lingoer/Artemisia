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

//extension XCTestCase{
//    func expectEqual<T>(_ val: T, description: String) -> ExpectEqual<T> {
//        return ExpectEqual(val, description: description)
//    }
//}
extension XCTestExpectation{
    @available(iOS 13.0, *)
    func fulfill<T:Equatable>(onEqual val:T) -> (T)->Void {
        {
            XCTAssertEqual($0, val)
            self.fulfill()
        }
    }
}
