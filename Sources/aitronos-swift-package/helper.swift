//
//  helper.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 23.09.2024.
//

import Foundation

// MARK: - StreamEvent Struct
public struct StreamEvent: Codable {
    public let event: String
    public let status: String?
    public let isResponse: Bool
    public let response: String?
    public let threadId: Int

    public init(event: String, status: String?, isResponse: Bool, response: String?, threadId: Int) {
        self.event = event
        self.status = status
        self.isResponse = isResponse
        self.response = response
        self.threadId = threadId
    }

    // Convert JSON dictionary to StreamEvent
    public static func fromJson(_ data: [String: Any]) -> StreamEvent? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let event = try? JSONDecoder().decode(StreamEvent.self, from: jsonData) else {
            return nil
        }
        return event
    }
}

// MARK: - Message Struct
public struct Message: Codable {
    public let content: String
    public let role: String
    public var type: String = "text"

    public init(content: String, role: String, type: String = "text") {
        guard role == "user" || role == "assistant" else {
            fatalError("Role must be either 'user' or 'assistant'")
        }

        guard type == "text" || type == "other_allowed_type" else {
            fatalError("Type must be 'text' or other allowed type")
        }

        self.content = content
        self.role = role
        self.type = type
    }
}

// MARK: - MessageRequestPayload Struct
public struct MessageRequestPayload: Codable {
    public var organizationId: Int = 0
    public var assistantId: Int = 0
    public var threadId: Int?
    public var model: String?
    public var instructions: String?
    public var additionalInstructions: String?
    public var messages: [Message] = []

    // Convert payload to dictionary
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
        return payload.compactMapValues { $0 }
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
