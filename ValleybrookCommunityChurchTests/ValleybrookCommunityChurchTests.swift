//
//  ValleybrookCommunityChurchTests.swift
//  ValleybrookCommunityChurchTests
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import XCTest
import Firebase
@testable import ValleybrookCommunityChurch

class ValleybrookCommunityChurchTests: XCTestCase {
    
    var peopleToTest: [Person]!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        peopleToTest = [
            Person(type: "Adult", name: "John", phone: "", email: "", birthOrder: 0, uid: ""),
            Person(type: "Child", name: "Ruby", phone: "", email: "", birthOrder: 1, uid: ""),
            Person(type: "Child", name: "James", phone: "", email: "", birthOrder: 2, uid: "")
        ]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        peopleToTest = nil
    }
    
    func testChildrenString() {
        let expected = "Ruby & James"
        let actual = GlobalFunctions.shared.getChildrenString(people: peopleToTest)
        XCTAssertEqual(actual, expected, "Children String is not what it should be.")
    }
    
    func testDownloadDirectory() {
        
        let expectation = XCTestExpectation(description: "Directory Downloaded")
        
        let ref = Database.database().reference()
        ref.child("Directories").child("-KuCWVVCotiP2DHPWhGm").observeSingleEvent(of: .value, with: { snapshot in
            XCTAssertNotNil(snapshot, "No data was downloaded")
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 10.0)
        
    }
    
    
    
}
