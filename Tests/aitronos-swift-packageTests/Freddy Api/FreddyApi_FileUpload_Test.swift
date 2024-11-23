//
//  FreddyApi_FileUpload_Test.swift
//  aitronos
//
//  Created by Phillip Loacker on 22.11.2024.
//

import XCTest
@testable import aitronos

final class FileUploadTests: XCTestCase {

    func testFileUploadSuccess() async throws {
        let organizationId = 1
        let fileName = "testFile.txt"
        let purpose: FileUploadPurpose = .batch
        let fileContent = "This is a test file."
        let fileData = Data(fileContent.utf8)
        
        // Set up a fake API with expected success response
        let freddyApi = FreddyApi(userToken: Config.testKey)
        
        // Expectations
        let expectation = XCTestExpectation(description: "File upload completes successfully")
        
        Task {
            do {
                let response = try await freddyApi.uploadFile(
                    organizationId: organizationId,
                    fileData: fileData,
                    fileName: fileName,
                    purpose: purpose
                )
                
                XCTAssertTrue(response.success, "File upload should succeed")
                XCTAssertEqual(response.message, "File uploaded successfully", "Expected success message from server")
                expectation.fulfill()
            } catch {
                XCTFail("File upload failed with error: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        // Wait for expectations asynchronously
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testFileUploadFailure() async throws {
        let organizationId = -1 // Invalid ID to simulate failure
        let fileName = "testFile.txt"
        let purpose = "testing"
        let fileContent = "This is a test file."
        let fileData = Data(fileContent.utf8)
        
        // Set up a fake API with expected failure response
        let freddyApi = FreddyApi(userToken: Config.testKey)
        
        // Expectations
        let expectation = XCTestExpectation(description: "File upload fails as expected")
        
        Task {
            do {
                _ = try await freddyApi.uploadFile(
                    organizationId: organizationId,
                    fileData: fileData,
                    fileName: fileName,
                    purpose: .fineTune
                )
                
                XCTFail("File upload should have failed")
                expectation.fulfill()
            } catch {
                XCTAssertNotNil(error, "Error should not be nil")
                expectation.fulfill()
            }
        }
        
        // Wait for expectations asynchronously
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // Helper method to handle fulfillment of expectations asynchronously
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}
