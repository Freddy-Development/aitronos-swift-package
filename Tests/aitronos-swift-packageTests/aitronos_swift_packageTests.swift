import XCTest
@testable import aitronos_swift_package

final class StreamTests: XCTestCase, StreamEventDelegate {

    var expectation: XCTestExpectation!
    var isFulfilled = false  // To track if expectation has been fulfilled

    func testRunStream() async throws {
        print("Running testRunStream")

        // Create an expectation for the async stream to complete
        expectation = expectation(description: "Stream API call completes")
        
        // Get the token from Config
        let token = Config.testKey
        
        // Initialize the API with the token
        let api = FreddyApi(token: token)
        
        // Define the payload for the stream request
        let payload = MessageRequestPayload(organizationId: 5, assistantId: 6, messages: [Message(content: "Hello", role: "user")])
        
        // Call the API's createStream method
        api.createStream(payload: payload, delegate: self)
        
        // Wait for the expectation to be fulfilled or timeout
        await fulfillment(of: [expectation], timeout: 120.0)  // Adjust timeout if needed
    }

    func handleStreamEvent(_ event: aitronos_swift_package.StreamEvent) {
        print("Received stream event: \(event)")
        
        // Ensure expectation is fulfilled only once
        if event.status == "completed" && !isFulfilled {
            isFulfilled = true  // Set flag to prevent multiple fulfill calls
            expectation.fulfill()
        }
    }
    
    func didEncounterError(_ error: any Error) {
        // Fail the test on unexpected error
        XCTFail("Unexpected error: \(error)")
    }
}
