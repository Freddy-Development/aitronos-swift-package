//
//  helper.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 23.09.2024.
//

import Foundation

// MARK: - StreamEvent Struct
public struct StreamEvent: Sendable {
    // Enum for Event types
    enum Event: Codable, Equatable {
        case threadRunCreated
        case threadRunQueued
        case threadRunInProgress
        case threadRunStepCreated
        case threadRunStepInProgress
        case threadMessageCreated
        case threadMessageInProgress
        case threadMessageDelta
        case threadMessageCompleted
        case threadRunStepCompleted
        case threadRunCompleted
        case other(String) // Catch-all case for unknown events

        // Custom initializer to handle raw values
        init(rawValue: String) {
            switch rawValue {
            case "thread.run.created": self = .threadRunCreated
            case "thread.run.queued": self = .threadRunQueued
            case "thread.run.in_progress": self = .threadRunInProgress
            case "thread.run.step.created": self = .threadRunStepCreated
            case "thread.run.step.in_progress": self = .threadRunStepInProgress
            case "thread.message.created": self = .threadMessageCreated
            case "thread.message.in_progress": self = .threadMessageInProgress
            case "thread.message.delta": self = .threadMessageDelta
            case "thread.message.completed": self = .threadMessageCompleted
            case "thread.run.step.completed": self = .threadRunStepCompleted
            case "thread.run.completed": self = .threadRunCompleted
            default: self = .other(rawValue)
            }
        }

        // Encoding and decoding support
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .other(let rawValue):
                try container.encode(rawValue)
            default:
                try container.encode(self.rawValue)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Event(rawValue: rawValue)
        }

        // Raw value extraction for known cases
        var rawValue: String {
            switch self {
            case .threadRunCreated: return "thread.run.created"
            case .threadRunQueued: return "thread.run.queued"
            case .threadRunInProgress: return "thread.run.in_progress"
            case .threadRunStepCreated: return "thread.run.step.created"
            case .threadRunStepInProgress: return "thread.run.step.in_progress"
            case .threadMessageCreated: return "thread.message.created"
            case .threadMessageInProgress: return "thread.message.in_progress"
            case .threadMessageDelta: return "thread.message.delta"
            case .threadMessageCompleted: return "thread.message.completed"
            case .threadRunStepCompleted: return "thread.run.step.completed"
            case .threadRunCompleted: return "thread.run.completed"
            case .other(let rawValue): return rawValue
            }
        }
    }

    // Enum for Status types
    enum Status: Codable, Equatable {
        case queued
        case inProgress
        case completed
        case other(String) // Catch-all case for unknown statuses

        // Custom initializer to handle raw values
        init(rawValue: String) {
            switch rawValue {
            case "queued": self = .queued
            case "in_progress": self = .inProgress
            case "completed": self = .completed
            default: self = .other(rawValue)
            }
        }

        // Encoding and decoding support
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .other(let rawValue):
                try container.encode(rawValue)
            default:
                try container.encode(self.rawValue)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Status(rawValue: rawValue)
        }

        // Raw value extraction for known cases
        var rawValue: String {
            switch self {
            case .queued: return "queued"
            case .inProgress: return "in_progress"
            case .completed: return "completed"
            case .other(let rawValue): return rawValue
            }
        }
    }

    let event: Event
    let status: Status?
    let isResponse: Bool
    let response: String?
    let threadId: Int

    // Updated fromJson method to map JSON to enums
    static func fromJson(_ json: [String: Any]) -> StreamEvent? {
        guard let eventString = json["event"] as? String,
              let isResponse = json["isResponse"] as? Bool,
              let threadId = json["threadId"] as? Int else {
            return nil
        }

        let event = Event(rawValue: eventString)
        let statusString = json["status"] as? String
        let status = statusString.map { Status(rawValue: $0) }
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
