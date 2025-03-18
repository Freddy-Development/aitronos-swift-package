import XCTest
@testable import aitronos

final class VerifyEmailTests: XCTestCase {

    func testVerifyEmailSuccess() async throws {
        // Arrange
        let email = "phillip.loacker@aitronos.com"

        // Act
        let expectation = XCTestExpectation(description: "Verify email should succeed")
        
        AppHive.verifyEmail(email: email) { result in
            switch result {
            case .success(let response):
                // Assert
                XCTAssertTrue(response.success, "Email verification should be successful")
            case .failure(let error):
                XCTFail("Email verification failed with error: \(error)")
            }
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled, or time out after 5 seconds
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testVerifyEmailFailure() async throws {
        // Arrange
        let email = "invalid-email@aitasdasdronos.com"

        // Act
        let expectation = XCTestExpectation(description: "Verify email should fail")
        
        AppHive.verifyEmail(email: email) { result in
            switch result {
            case .success(let result):
                if result.success {
                    XCTFail("Email verification should have failed")
                } else {
                    XCTAssertTrue(true, "Email verification failed as expected")
                }
            case .failure(let error):
                // Assert
                XCTFail("The ckeck should not have failed: \(error)")
            }
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled, or time out after 5 seconds
        await fulfillment(of: [expectation], timeout: 5.0)
    }
} 
