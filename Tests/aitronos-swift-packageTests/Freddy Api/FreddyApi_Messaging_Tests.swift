//
//  FreddyApi_Messaging_Tests.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import XCTest
@testable import aitronos

final class FreddyApiTests: XCTestCase {
    var freddyApi = Aitronos(apiKey: Config.testKey).freddyApi
    
    // MARK: - Test: Send Message Success
    func testSendMessageSuccess() async throws {
        let payload = MessageRequestPayload(
            organizationId: 1,
            assistantId: 1,
            messages: [Message(content: "Hello", role: "user")]
        )
        
        do {
            let response = try await freddyApi.createRun(payload: payload)
            XCTAssertNotNil(response, "The response should not be nil")
            XCTAssertNotNil(response.runKey, "Response should contain a valid runKey")
            XCTAssertNotNil(response.threadKey, "Response should contain a valid threadKey")
            print("API Response: \(response)")
        } catch {
            XCTFail("API call failed: \(error)")
        }
    }
    
    // MARK: - Test: Send Message Failure
    func testSendMessageFailure() async throws {
        let payload = MessageRequestPayload(
            organizationId: 1,
            assistantId: 9999, // Invalid assistant ID
            messages: [Message(content: "Hello", role: "user")]
        )
        
        do {
            _ = try await freddyApi.createRun(payload: payload)
            XCTFail("Expected an error, but the API call succeeded.")
        } catch let FreddyError.httpError(statusCode, description) {
            XCTAssertEqual(statusCode, 500, "Expected HTTP 500 error for invalid assistant ID")
            XCTAssert(description.contains("Invalid assistant"), "Expected error description to indicate invalid assistant")
            print("Caught expected HTTP error: \(description)")
        } catch {
            XCTFail("Unexpected error type: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test: Check Run Status
//    func testCheckRunStatusCompleted() async throws { (( TODO: Uncomment this test ))
//        let organizationId = 1
//        let runKey = "run_dIANCQnv0gR0MOCgi5sKy2cK"
//        let threadKey = "thread_QT013xhAcoKGkQWCaUy80JzX"
//        
//        print("Starting test for checking run status...")
//        
//        do {
//            for attempt in 1...30 {
//                print("Polling attempt \(attempt)...")
//                
//                let status = try await freddyApi.checkRunStatus(
//                    runKey: runKey,
//                    threadKey: threadKey,
//                    organizationId: organizationId
//                )
//                
//                print("Run Status: \(status)")
//                
//                if status == "completed" {
//                    XCTAssertEqual(status, "completed", "Run status should be 'completed'")
//                    print("Run completed successfully!")
//                    return
//                }
//                
//                try await Task.sleep(nanoseconds: UInt64(2.0 * 1_000_000_000)) // 2 seconds
//            }
//            
//            XCTFail("Run did not complete within the retry limit.")
//        } catch let FreddyError.httpError(statusCode, description) {
//            XCTFail("HTTP error \(statusCode): \(description)")
//        } catch {
//            XCTFail("Unexpected error: \(error.localizedDescription)")
//        }
//    }
    
    // MARK: - Test: Get Run Response
//    func testGetRunResponse() async throws {
//        let organizationId = 2
//        let threadKey = "thread_WQWyoPExdIpJF8P9NqldtBZL" // Replace with valid thread_key
//        
//        do {
//            let response = try await freddyApi.getRunResponse(
//                organizationId: organizationId,
//                threadKey: threadKey
//            )
//            
//            XCTAssertNotNil(response, "The response should not be nil")
//            XCTAssertNotNil(response.response, "The response should contain a valid 'response' key")
//            print("Run Response: \(response.response)")
//        } catch let FreddyError.httpError(statusCode, description) {
//            XCTFail("HTTP error: \(statusCode) - \(description)")
//        } catch {
//            XCTFail("Unexpected error: \(error.localizedDescription)")
//        }
//    }
    
    // MARK: - Test: Execute Run Live
    func testExecuteRunLive() async throws {
        let payload = MessageRequestPayload(
            organizationId: 1,
            assistantId: 1,
            instructions: "Provide a joke",
            additionalInstructions: "Use humor",
            messages: [Message(content: "Tell me a joke.", role: "user")]
        )
        
        do {
            // Call the API to execute the run
            let response = try await freddyApi.executeRun(payload: payload)
            
            // Safely unwrap the response
            guard let response = response else {
                XCTFail("The response should not be nil")
                return
            }
            
            XCTAssertFalse(response.isEmpty, "The response should contain at least one event")
            
            // Validate the first event in the response
            if let firstEvent = response.first {
                XCTAssertEqual(firstEvent.event, "thread.run.completed", "Expected the event to indicate completion")
                XCTAssertEqual(firstEvent.status, "completed", "Expected the run status to be completed")
                XCTAssertNotNil(firstEvent.response, "The response should contain valid data")
                XCTAssertEqual(firstEvent.responseType, "text", "Expected the response type to be 'text'")
                
                // Print the response content for debugging
                if let actualResponse = firstEvent.response {
                    print("Run completed successfully. Response: \(actualResponse)")
                } else {
                    XCTFail("The response content is missing")
                }
            } else {
                XCTFail("The response does not contain any events")
            }
        } catch let FreddyError.httpError(statusCode, description) {
            // Handle specific HTTP errors with detailed assertions
            XCTFail("HTTP error: \(statusCode) - \(description)")
        } catch {
            // Handle any unexpected errors
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    func testGenerateChatTitle() async throws {
        // Define mock messages
        let messages = [
            "What is the capital of France?",
            "The capital of France is Paris.",
            "Great, thank you!"
        ]
        
        do {
            // Call the function to generate a chat title
            let chatTitle = await freddyApi.generateChatTitle(from: messages)
            
            // Assert the result is not the default error title
            XCTAssertNotEqual(chatTitle, "Untitled Chat", "The chat title should not be the default error title.")
            
            // Assert that the title is within the expected format or contains expected keywords
            XCTAssertTrue(chatTitle.contains("capital") || chatTitle.contains("France"), "The generated chat title should be relevant to the messages.")
            
            print("Generated Chat Title: \(chatTitle)")
        }
    }
}