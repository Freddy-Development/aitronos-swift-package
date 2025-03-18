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

        do {
            let _ = try await AppHive.login(usernmeEmail: email, password: wrongPassword)
            XCTFail("Login should have failed with incorrect password")
        } catch let error as FreddyError {
            XCTAssertEqual(error, .unauthorized(reason: "Authentication required"), "Expected unauthorized error")
        }
    }

    func testLoginWrongEmail() async throws {
        let wrongEmail = "wrongemail@example.com"
        let password = Config.testPassword

        do {
            let _ = try await AppHive.login(usernmeEmail: wrongEmail, password: password)
            XCTFail("Login should have failed with incorrect email")
        } catch let error as FreddyError {
            XCTAssertEqual(error, .resourceNotFound(resource: "Requested resource"), "Expected resource not found error")
        }
    }
}
