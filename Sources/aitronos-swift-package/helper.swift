//
//  helper.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 23.09.2024.
//

import Foundation

// MARK: - StreamEvent Struct
public struct StreamEvent: Sendable {
    let event: String
    let status: String?
    let isResponse: Bool
    let response: String?
    let threadId: Int
    
    static func fromJson(_ json: [String: Any]) -> StreamEvent? {
        guard let event = json["event"] as? String,
              let isResponse = json["isResponse"] as? Bool,
              let threadId = json["threadId"] as? Int else {
            return nil
        }
        let status = json["status"] as? String
        let response = json["response"] as? String
        return StreamEvent(event: event, status: status, isResponse: isResponse, response: response, threadId: threadId)
    }
}

// MARK: - Message Struct
public struct Message: Codable {
    let content: String
    let role: String
    
    public init(content: String, role: String) {
        self.content = content
        self.role = role
    }
}

public struct MessageRequestPayload: Codable {
    var organizationId: Int = 0
    var assistantId: Int = 0
    var threadId: Int? = nil
    var model: String? = nil
    var instructions: String? = nil
    var additionalInstructions: String? = nil
    var messages: [Message] = []
    
    public init(
        organizationId: Int,
        assistantId: Int,
        threadId: Int? = nil,
        model: String? = nil,
        instructions: String? = nil,
        additionalInstructions: String? = nil,
        messages: [Message] = []
    ) {
        self.organizationId = organizationId
        self.assistantId = assistantId
        if let threadId { self.threadId = threadId }
        if let model { self.model = model }
        if let instructions { self.instructions = instructions }
        if let additionalInstructions { self.additionalInstructions = additionalInstructions }
        self.messages = messages
    }

    public func toDict() -> [String: Any] {
        let payload: [String: Any?] = [
            "organization_id": organizationId,
            "assistant_id": assistantId,
            "thread_id": threadId,
            "model": model,
            "instructions": instructions,
            "additional_instructions": additionalInstructions,
            "messages": messages.map { $0.dictionaryRepresentation() }
        ]
        return payload.compactMapValues { $0 } // Remove nil values
    }
}

extension Message {
    func dictionaryRepresentation() -> [String: Any] {
        return [
            "content": content,
            "role": role
        ]
    }
}

// MARK: - JSON Validation Helper
func isValidJson(data: String) -> Bool {
    guard let jsonData = data.data(using: .utf8) else { return false }
    return (try? JSONSerialization.jsonObject(with: jsonData)) != nil
}

// MARK: - Encodable Extension for Dictionary Conversion
extension Encodable {
    func dictionaryRepresentation() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

// MARK: - Regex Helper (for finding JSON-like structures)
func extractJsonStrings(from buffer: String, using pattern: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: buffer, range: NSRange(buffer.startIndex..., in: buffer))
    return matches.map { (buffer as NSString).substring(with: $0.range) }
}
