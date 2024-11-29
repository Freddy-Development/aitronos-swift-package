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
    public enum Event: Codable, Equatable, Sendable {
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
        public init(rawValue: String) {
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
            case "thread.run.step.delta": self = .threadMessageDelta
            case "thread.run.completed": self = .threadRunCompleted
            default: self = .other(rawValue)
            }
        }
        
        // Raw value extraction for known cases
        public var rawValue: String {
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
    public enum Status: Codable, Equatable, Sendable {
        case queued
        case inProgress
        case completed
        case other(String) // Catch-all case for unknown statuses

        // Custom initializer to handle raw values
        public init(rawValue: String) {
            switch rawValue {
            case "queued": self = .queued
            case "in_progress": self = .inProgress
            case "completed": self = .completed
            default: self = .other(rawValue)
            }
        }

        // Raw value extraction for known cases
        public var rawValue: String {
            switch self {
            case .queued: return "queued"
            case .inProgress: return "in_progress"
            case .completed: return "completed"
            case .other(let rawValue): return rawValue
            }
        }
    }

    public let event: Event
    public let status: Status?
    public let isResponse: Bool
    public let response: String?
    public let threadId: Int

    // Updated fromJson method to map JSON to enums
    static public func fromJson(_ json: [String: Any]) -> StreamEvent? {
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
    public let content: String
    public let role: MessageRole
    
    public init(content: String, role: MessageRole) {
        self.content = content
        self.role = role
    }

    public func dictionaryRepresentation() -> [String: Any] {
        return [
            "content": content,
            "role": role.rawValue
        ]
    }
}

// MARK: - MessageRole Enum
public enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

// MARK: - MessageRequestPayload Struct
public struct MessageRequestPayload: Codable {
    public var organizationId: Int
    public var assistantId: Int
    public var threadId: Int?
    public var model: FreddyModel?
    public var instructions: String?
    public var additionalInstructions: String?
    public var messages: [Message]
    public var stream: Bool = true
    public var files: [String] = []

    public init(
        organizationId: Int,
        assistantId: Int,
        threadId: Int? = nil,
        model: FreddyModel? = nil,
        instructions: String? = nil,
        additionalInstructions: String? = nil,
        messages: [Message] = [],
        files: [String] = []
    ) {
        self.organizationId = organizationId
        self.assistantId = assistantId
        self.threadId = threadId
        self.model = model
        self.instructions = instructions
        self.additionalInstructions = additionalInstructions
        self.messages = messages
        self.files = files
    }

    public func toDict() -> [String: Any] {
        let payload: [String: Any?] = [
            "organization_id": organizationId,
            "assistant_id": assistantId,
            "thread_id": threadId,
            "model": model?.rawValue, // Convert to raw value for serialization
            "instructions": instructions,
            "additional_instructions": additionalInstructions,
            "messages": messages.map { $0.dictionaryRepresentation() },
            "stream": stream,
            "files": files.map { $0 }
        ]
        return payload.compactMapValues { $0 } // Remove nil values
    }
}

// MARK: - JSON Validation Helper
public func isValidJson(data: String) -> Bool {
    guard let jsonData = data.data(using: .utf8) else { return false }
    return (try? JSONSerialization.jsonObject(with: jsonData)) != nil
}

// MARK: - Encodable Extension for Dictionary Conversion
public extension Encodable {
    func dictionaryRepresentation() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

// MARK: - Regex Helper (for finding JSON-like structures)
public func extractJsonStrings(from buffer: String, using pattern: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: buffer, range: NSRange(buffer.startIndex..., in: buffer))
    return matches.map { (buffer as NSString).substring(with: $0.range) }
}

// MARK: - HTTPMethod Enum
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Config Struct
public struct Config {
    let baseUrl: String
    let backendKey: String
}
// MARK: - FreddyError Enum
public enum FreddyError: Error, Equatable, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, description: String)
    case noData
    case decodingError(error: Error, data: Data)
    case networkIssue(description: String)
    case noUserFound
    case incorrectPassword
    case invalidCredentials
    case serverError(title: String, message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is invalid."
        case .invalidResponse:
            return "The response received from the server is invalid."
        case .httpError(let statusCode, let description):
            return "HTTP error \(statusCode): \(description)"
        case .noData:
            return "No data was received from the server."
        case .decodingError(let error, let data):
            return "Failed to decode the response. Error: \(error.localizedDescription). Data: \(String(data: data, encoding: .utf8) ?? "N/A")."
        case .networkIssue(let description):
            return "A network issue occurred: \(description)"
        case .noUserFound:
            return "No user found with the provided credentials."
        case .incorrectPassword:
            return "The provided password is incorrect."
        case .invalidCredentials:
            return "Invalid credentials were provided."
        case .serverError(let title, let message):
            return "\(title): \(message)"
        }
    }

    public static func == (lhs: FreddyError, rhs: FreddyError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsStatusCode, let lhsDescription),
              .httpError(let rhsStatusCode, let rhsDescription)):
            return lhsStatusCode == rhsStatusCode && lhsDescription == rhsDescription
        case (.noData, .noData):
            return true
        case (.decodingError(let lhsError, let lhsData),
              .decodingError(let rhsError, let rhsData)):
            return lhsError.localizedDescription == rhsError.localizedDescription && lhsData == rhsData
        case (.networkIssue(let lhsDescription), .networkIssue(let rhsDescription)):
            return lhsDescription == rhsDescription
        case (.noUserFound, .noUserFound):
            return true
        case (.incorrectPassword, .incorrectPassword):
            return true
        case (.invalidCredentials, .invalidCredentials):
            return true
        case (.serverError(let lhsTitle, let lhsMessage),
              .serverError(let rhsTitle, let rhsMessage)):
            return lhsTitle == rhsTitle && lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Perform HTTPS Request Function
public func performRequest<T: Decodable>(
    endpoint: String,
    method: HTTPMethod,
    config: Config,
    body: Data? = nil,
    emptyResponse: Bool = false,
    decoder: JSONDecoder = JSONDecoder(),
    completion: @Sendable @escaping (Result<T?, FreddyError>) -> Void
) {
    // 1. Construct the URL
    guard let url = URL(string: config.baseUrl + endpoint) else {
        DispatchQueue.main.async {
            completion(.failure(.invalidURL))
        }
        return
    }

    // 2. Configure the request
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(config.backendKey)", forHTTPHeaderField: "Authorization")

    if let body = body, [.post, .put].contains(method) {
        request.httpBody = body
    }

    // 3. Perform the network request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            // 4. Handle network errors
            if let error = error {
                completion(.failure(.networkIssue(description: error.localizedDescription)))
                return
            }

            // 5. Validate the response and status code
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            // 6. Handle non-successful HTTP status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data {
                    // Try to extract error details from response
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let dictionary = jsonObject as? [String: Any],
                       let errorDescription = dictionary["error"] as? String {
                        let detailedError = FreddyError.httpError(statusCode: httpResponse.statusCode, description: errorDescription)
                        completion(.failure(detailedError))
                    } else {
                        let genericError = FreddyError.httpError(statusCode: httpResponse.statusCode, description: "Unknown Error")
                        completion(.failure(genericError))
                    }
                } else {
                    completion(.failure(.noData))
                }
                return
            }

            // 7. Handle empty responses
            if emptyResponse {
                completion(.success(nil))
                return
            }

            // 8. Ensure there is data to decode
            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            // 9. Attempt to decode the response
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingError(error: error, data: data)))
            }
        }
    }
    task.resume()
}

// MARK: - EmptyResponse Struct
/// A placeholder structure for handling empty responses from the server.
struct EmptyResponse: Decodable {}
