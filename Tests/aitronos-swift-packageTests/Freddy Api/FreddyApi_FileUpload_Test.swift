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
        let organizationId = 1
        let freddyApi = FreddyApi(userToken: Config.testKey)

        do {
            let response = try await freddyApi.uploadFile(
                organizationId: organizationId,
                fileData: fileData,
                fileName: fileName,
                purpose: purpose
            )
            XCTAssertNotNil(response.fileId, "File ID should not be nil")
        } catch let error as NSError {
            if error.code == 401 {
                throw XCTSkip("Skipping test due to authentication issues")
            } else {
                XCTFail("File upload failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper method to handle fulfillment of expectations asynchronously
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}
