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
        let response = try await AppHive.login(usernmeEmail: email, password: password)
        
        // 3. Assert the response
        XCTAssertFalse(response.token.isEmpty, "Token should not be empty")
        XCTAssertFalse(response.refreshToken.token.isEmpty, "Refresh token should not be empty")
        XCTAssertFalse(response.deviceId.isEmpty, "Device ID should not be empty")

        // Print the results for debugging purposes
        //print("Login successful: \(response)")
    }

    func testLoginWrongPassword() async throws {
        let email = Config.testEmail
        let wrongPassword = "wrongpassword123"

        // Create an expectation for the asynchronous login call
        let expectation = XCTestExpectation(description: "Login should fail with incorrect password")

        AppHive.login(usernmeEmail: email, password: wrongPassword) { result in
            switch result {
            case .success:
                XCTFail("Login should have failed with incorrect password")
            case .failure(let error):
                if case .invalidCredentials(let details) = error {
                    XCTAssertEqual(details, "Incorrect password", "Expected incorrect password error")
                } else {
                    XCTFail("Expected invalidCredentials error, got \(error)")
                }
            }
            // Fulfill the expectation to indicate that the async call has completed
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled, or time out after 5 seconds
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testLoginWrongEmail() async throws {
        let wrongEmail = "wrongemail@example.com"
        let password = Config.testPassword

        do {
            let _ = try await AppHive.login(usernmeEmail: wrongEmail, password: password)
            XCTFail("Login should have failed with incorrect email")
        } catch let error as FreddyError {
            XCTAssertEqual(error, .resourceNotFound(resource: "User name not found"), "Expected user name not found error")
        }
    }
}
