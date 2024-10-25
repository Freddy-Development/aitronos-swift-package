//
//  aitronos_swift_packageTests.swift
//  aitronos_swift_packageTests
//
//  Created by Phillip Loacker on 24.09.2024.
//

import XCTest
@testable import aitronos

final class aitronos_swift_packageTests: XCTestCase {
    
    func testInitWithLogin() async throws {
        // 1. Load test credentials from the config file
        let email = Config.testEmail
        let password = Config.testPassword
        
        // 2. Create an expectation for the async login process
        let expectation = expectation(description: "Login completes and API key is set.")
        
        // 3. Initialize Aitronos with username and password
        do {
            let api = try await Aitronos(username: email, password: password)
            
        } catch {
            XCTFail("Login failed with error: \(error)")
        }
        
        // 4. Simulate an asynchronous delay to ensure the login completes
//        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
//            if !api.userToken.isEmpty {
//                print("API Key after login: \(api.userToken)")
//                expectation.fulfill()  // Fulfill the expectation if the API key is set
//            } else {
//                XCTFail("Login failed or API key is not set.")
//            }
//        }
        
        // 5. Wait for the expectation to be fulfilled
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // Helper method for awaiting expectations in async tests
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}
