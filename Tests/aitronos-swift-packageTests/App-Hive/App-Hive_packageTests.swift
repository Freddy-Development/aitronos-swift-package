//
//  App-Hive_packageTests.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import XCTest
@testable import aitronos

final class AuthenticationTests: XCTestCase {

    // Test login using real credentials from the config file
    func testLogin() async throws {
        //print("Starting testLogin")

        // 1. Load test credentials from the config file
        let email = Config.testEmail
        let password = Config.testPassword
        //print("Loaded test credentials: \(email)")

        // 2. Call the login function from AppHive
        await withCheckedContinuation { continuation in
            AppHive.login(usernmeEmail: email, password: password) { result in
                switch result {
                case .success(let response):
                    // Assert that we received a valid token and fulfill the continuation
                    XCTAssertFalse(response.token.isEmpty, "Token should not be empty")
                    XCTAssertFalse(response.refreshToken.token.isEmpty, "Refresh token should not be empty")
                    XCTAssertFalse(response.deviceId.isEmpty, "Device ID should not be empty")

                    // Print the results for debugging purposes
                    //print("Login successful: \(response)")
                    
                    continuation.resume()  // Resume when login completes
                    
                case .failure(let error):
                    // If login fails, print and fail the test
                    XCTFail("Login failed with error: \(error)")
                    continuation.resume()
                }
            }
        }
    }
}
