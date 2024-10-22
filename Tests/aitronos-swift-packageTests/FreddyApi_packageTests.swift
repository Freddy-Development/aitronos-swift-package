//
//  FreddyApi_packageTests.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import XCTest
@testable import aitronos

final class StreamTests: XCTestCase, StreamEventDelegate {

    var expectation: XCTestExpectation!
    var isFulfilled = false  // To track if expectation has been fulfilled
    let testTimeout: TimeInterval = 60  // Timeout for the stream to complete

    func testRunStream() async throws {
        print("Starting testRunStream")

        // Create an expectation for the async stream to complete
        expectation = expectation(description: "Stream API call completes")
        
        // Get the token from Config (fail early if token is nil)
        let token = Config.testKey
        print("Token retrieved: \(token)")
        
        // Initialize the API with the token
        let api = Aitronos(apiKey: token).assistantMessaging
        
        // Define the payload for the stream request
        let payload = MessageRequestPayload(
            organizationId: 5,
            assistantId: 6,
            messages: [Message(content: "Hello", role: "user")]
        )
        print("Payload created: \(payload)")
        
        // Start the stream call
        print("Starting createStream call")
        api.createStream(payload: payload, delegate: self)
        
        // Await expectation fulfillment with timeout
        await fulfillment(of: [expectation], timeout: testTimeout)
        print("Test completed")
    }

    // MARK: - StreamEventDelegate Methods

    func handleStreamEvent(_ event: StreamEvent) {
        print("Received stream event: \(event.event.rawValue) with status: \(String(describing: event.status))")

        // Log the response for better visibility
        if let response = event.response {
            print("Event response: \(response)")
        } else {
            print("Event has no response")
        }

        // Check event status for stream completion, handling nil status for message deltas
        if event.status == .completed && !isFulfilled {
            if event.response != nil {
                isFulfilled = true
                print("Stream completed, fulfilling expectation")
                expectation.fulfill()
            }
           
        } else if event.event == .threadMessageDelta {
            // Handle partial message deltas separately, as they may not have a status
            print("Received partial message: \(event.response ?? "No response data")")
        } else if let status = event.status {
            print("Stream is still in progress: \(status.rawValue)")
        } else {
            print("Stream is still in progress: (no status available)")
        }
    }
    
    func didEncounterError(_ error: Error) {
        // Fail the test if any unexpected error occurs
        print("Error encountered during stream: \(error)")
        XCTFail("Unexpected error encountered: \(error.localizedDescription)")
    }

    // MARK: - Helper Method

    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        do {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))  // Timeout
            if !isFulfilled {
                print("Stream did not complete within the timeout period of \(timeout) seconds")
                XCTFail("Stream timed out after \(timeout) seconds")
            }
        } catch {
            print("Error while waiting for fulfillment: \(error)")
            XCTFail("Test failed during expectation waiting: \(error.localizedDescription)")
        }
    }
}
