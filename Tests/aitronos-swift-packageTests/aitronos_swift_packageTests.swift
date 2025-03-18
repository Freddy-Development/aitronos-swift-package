//
//  aitronos_swift_packageTests.swift
//  aitronos_swift_packageTests
//
//  Created by Phillip Loacker on 24.09.2024.
//

import XCTest
@testable import aitronos

final class aitronos_swift_packageTests: XCTestCase {
    
    func testInitWithToken() throws {
        // 1. Simulate a valid API key
        let apiKey = Config.testKey

        // 2. Initialize Aitronos with the API key
        let aitronos = Aitronos(apiKey: apiKey)

        // 3. Verify the token is correctly set
        XCTAssertEqual(aitronos.userToken, apiKey, "The user token should match the provided API key.")
    }
    
    func testInitWithLogin() async throws {
        // 1. Load test credentials from the config file
        let email = Config.testEmail
        let password = Config.testPassword

        // 2. Initialize Aitronos using username and password
        do {
            let aitronos = try await Aitronos(usernmeEmail: email, password: password)

            // 3. Verify the userToken is set after login
            XCTAssertFalse(aitronos.userToken.isEmpty, "The user token should not be empty after a successful login.")
            //print("User token: \(aitronos.userToken)")
        } catch {
            XCTFail("Failed to initialize Aitronos with login: \(error)")
        }
    }
    
    func testInitWithInvalidEmail() async throws {
        // 1. Provide invalid credentials
        let email = "invalid@example.com"
        let password = "wrong-password"

        // 2. Try initializing Aitronos with invalid credentials and expect a failure
        do {
            _ = try await Aitronos(usernmeEmail: email, password: password)
            XCTFail("Initialization should fail with invalid credentials.")
        } catch let error as FreddyError {
            // 3. Verify the error is as expected
            XCTAssertEqual(error, .resourceNotFound(resource: "Requested resource"), "The error should indicate user not found.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testInitWithInvalidPassword() async throws {
        let email = Config.testEmail
        let password = "wrong-password"
        
        do {
            _ = try await Aitronos(usernmeEmail: email, password: password)
        } catch let error as FreddyError {
            XCTAssertEqual(error, .unauthorized(reason: "Authentication required"), "The error should indicate incorrect password.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
