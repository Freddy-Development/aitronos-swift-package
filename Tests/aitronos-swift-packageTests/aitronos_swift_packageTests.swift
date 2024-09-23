import Testing
@testable import aitronos_swift_package

@Test func example() async throws {
    let token = Config().getTestToken()
    let api = FreddyApi(token: token)
    
    func printStreamEvent(_ event: StreamEvent) {
        print("Event: \(event.event)")
        print("Status: \(event.status ?? "No status")")
        print("Response: \(event.response ?? "No response")")
        print("ThreadId: \(event.threadId)")
    }
    
    let payload = MessageRequestPayload(organizationId: 1, assistantId: 1, messages: [Message(content: "Hello", role: "user")])
    
    api.createStream(payload: payload) { event in
        print(event as Any)
    }
}
