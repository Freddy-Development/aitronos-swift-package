//
//  FreddyApi_FileUpload_Test.swift
//  aitronos
//
//  Created by Phillip Loacker on 22.11.2024.
//

import XCTest
@testable import aitronos

final class FileUploadTests: XCTestCase {

    func testFileUploadSuccessWithRealFile() async throws {
        // Locate the file in the test bundle
        guard let fileUrl = Bundle.module.url(forResource: "testFile", withExtension: "txt"),
              let fileData = try? Data(contentsOf: fileUrl) else {
            XCTFail("File not found in test bundle")
            return
        }
        let fileName = "testFile.txt"
        let purpose: FileUploadPurpose = .assistants

        // Organization and API Setup
        let organizationId = 1 // Replace with a valid organization ID
        let freddyApi = FreddyApi(userToken: Config.testKey) // Use live token

        do {
            // Call the actual API
            let response = try await freddyApi.uploadFile(
                organizationId: organizationId,
                fileData: fileData,
                fileName: fileName,
                purpose: purpose
            )

            // Assert the response
            XCTAssertNotNil(response.fileId, "File ID should not be nil")
            print("[DEBUG] Uploaded File ID: \(String(describing: response.fileId))")

            if let success = response.success {
                XCTAssertTrue(success, "File upload should succeed")
            } else {
                XCTFail("Response does not contain success flag")
            }

            if let message = response.message {
                print("[DEBUG] Server Message: \(message)")
            } else {
                XCTFail("Response does not contain message field")
            }
            
            print("[DEBUG] Test Passed: File upload completed successfully.")
        } catch {
            // Handle and assert error details
            print("[DEBUG] File upload failed with error: \(error.localizedDescription)")
            XCTFail("File upload failed with error: \(error.localizedDescription)")
        }
    }
    
    func testFileUploadFailure() async throws {
        let organizationId = -1 // Invalid ID to simulate failure
        let fileName = "testFile.txt"
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
