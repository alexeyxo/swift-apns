//
//  UnitTest.swift
//  UnitTest
//
//  Created by Alexey Khokhlov on 31.01.16.
//  Copyright © 2016 Alexey Khokhlov. All rights reserved.
//

import XCTest
import APNS
class UnitTest: XCTestCase {
    var expectation:XCTestExpectation = XCTestExpectation()
    override func setUp() {
        super.setUp()
        self.expectation = self.expectation(description:"server response")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testSendProtobuf() {
//        let providerData = Apple.Apns.ProviderData.Builder()
//        providerData.bundle = "com.advisa.voipservice"
//        providerData.serviceIdentity = Apple.Apns.ProviderData.Identity.Development
//        providerData.priority = 10
//        providerData.certificatePath = NSBundle(forClass:UnitTest.self).pathForResource("push", ofType: "p12")!
//        providerData.certificatePassphrase = "123456"
//        providerData.token = "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe"
//        
//        let aps = Apple.Apns.Push.Aps.Builder()
//        aps.badge = 1
//        aps.contentAvailable = 1
//        aps.sound = "default"
//        aps.alert = "testSendProtobuf()"
//        do {
//            let payload = try Apple.Apns.Push.Builder().setAps(aps.build()).build()
//            providerData.payload = payload
//            try APNSNetwork().sendPush(providerData.build(), responseBlock: { (response) -> () in
//                print(response)
//                XCTAssertTrue(response.statusCode == 200)
//                self.expectation.fulfill()
//
//            })
//            self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
//                if (error != nil) {
//                    XCTFail("Timeout error: \(error)")
//                }
//            })
//        } catch {
//            
//        }
//    }
    
    
    func testPush() {
        
        let aps = ["sound":"default", "alert":"testPush()"]
        let payload = ["aps":aps]
        let str = Bundle(for:UnitTest.self).path(forResource: "cert", ofType: "p12")!
        var mess = ApplePushMessage(topic: "com.123.123",
                             priority: 10,
                             payload: payload,
                             deviceToken: "e86ba7b98a8bbc2725481caed7c2b2d906dae1f11339bb11a6918095d6d14933",
                             certificatePath:str,
                             passphrase: "123456")
        
        mess.responseBlock = { response in
            XCTAssertTrue(response.serviceStatus.0 == 200)
            self.expectation.fulfill()
        }
        
        mess.networkError = { err in
            if (err != nil) {
                XCTFail("Timeout error: \(err)")
            }

        }
        _ = try! mess.send()
        
        self.waitForExpectations(timeout: 5, handler: { (error) -> Void in
            if (error != nil) {
                XCTFail("Timeout error: \(error)")
            }
        })

    }
    
    func testPushFails() {
        
        let aps = ["sound":"default", "alert":"testPush()"]
        let payload = ["aps":aps]
        let str = Bundle(for:UnitTest.self).path(forResource: "cert", ofType: "p12")!
        var mess = ApplePushMessage(topic: "com.123.123",
                                    priority: 10,
                                    payload: payload,
                                    deviceToken: "e86ba7b98a8bbc27254ddd81caed7c2b2d906dae1f11339bb11a6918095d6d14933",
                                    certificatePath:str,
                                    passphrase: "123456")
        
        mess.responseBlock = { response in
            XCTAssertTrue(response.serviceStatus.1 == APNServiceStatus.badRequest)
            self.expectation.fulfill()
        }
        
        mess.networkError = { err in
            if (err != nil) {
                XCTFail("Timeout error: \(err)")
            }
            
        }
        _ = try! mess.send()
        
        self.waitForExpectations(timeout: 5, handler: { (error) -> Void in
            if (error != nil) {
                XCTFail("Timeout error: \(error)")
            }
        })
        
    }
    
}
