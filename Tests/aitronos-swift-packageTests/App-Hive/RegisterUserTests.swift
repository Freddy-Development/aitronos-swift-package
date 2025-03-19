//
//  RegisterUserTests.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.03.2025.
//

import XCTest
@testable import aitronos

final class RegisterUserTests: XCTestCase {
    
    private func generateRandomEmail() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "test\(timestamp)\(random)@aitronos.com"
    }

    func testRegisterUserSuccess() async throws {
        // Arrange
        let email = generateRandomEmail()
        let password = "Test@123456"
        let fullName = "Test User"

        // Act & Assert
        let expectation = XCTestExpectation(description: "Register user should succeed")
        
        AppHive.registerUser(
            email: email,
            password: password,
            fullName: fullName
        ) { result in
            switch result {
            case .success(let response):
                // Verify the response structure
                XCTAssertNotNil(response.verificationResponse)
                XCTAssertGreaterThan(response.verificationResponse.userId, 0)
                XCTAssertFalse(response.verificationResponse.emailKey.isEmpty)
                
            case .failure(let error):
                XCTFail("Registration should not fail. Error: \(error)")
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testRegisterUserWithInvalidEmail() async throws {
        // Arrange
        let invalidEmail = "invalid-email"
        let password = "Test@123456"
        let fullName = "Test User"
        
        // Act & Assert
        let expectation = XCTestExpectation(description: "Register user should fail with invalid email")
        
        AppHive.registerUser(
            email: invalidEmail,
            password: password,
            fullName: fullName
        ) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail with invalid email")
            case .failure(let error):
                // Verify we get an appropriate error
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testRegisterUserWithWeakPassword() async throws {
        // Arrange
        let email = generateRandomEmail()
        let weakPassword = "123" // Too short password
        let fullName = "Test User"
        
        // Act & Assert
        let expectation = XCTestExpectation(description: "Register user should fail with weak password")
        
        AppHive.registerUser(
            email: email,
            password: weakPassword,
            fullName: fullName
        ) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail with weak password")
            case .failure(let error):
                // Verify we get an appropriate error
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // Helper method for handling test expectations
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
} 
