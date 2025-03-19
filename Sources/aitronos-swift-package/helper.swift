// MARK: - LoginErrorType Enum
public enum LoginErrorType: Equatable, Sendable {
    case noUserFound
    case incorrectPassword
    case invalidCredentials
}
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
        case threadRunFailed
        case threadRunStepDelta
        case error
        case other(String)
        
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
            case "thread.run.completed": self = .threadRunCompleted
            case "thread.run.failed": self = .threadRunFailed
            case "thread.run.step.delta": self = .threadRunStepDelta
            case "error": self = .error
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
            case .threadRunFailed: return "thread.run.failed"
            case .other(let rawValue): return rawValue
            case .threadRunStepDelta: return "thread.run.step.delta"
            case .error: return "error"
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
    public var files: [FileInput]
    
    private enum CodingKeys: String, CodingKey {
        case organizationId = "organization_id"
        case assistantId = "assistant_id"
        case threadId = "thread_id"
        case model
        case instructions
        case additionalInstructions = "additional_instructions"
        case messages
        case stream
        case files
    }
    
    public init(
        organizationId: Int,
        assistantId: Int,
        threadId: Int? = nil,
        model: FreddyModel? = nil,
        instructions: String? = nil,
        additionalInstructions: String? = nil,
        messages: [Message] = [],
        stream: Bool = true,
        files: [FileInput] = []
    ) {
        self.organizationId = organizationId
        self.assistantId = assistantId
        self.threadId = threadId
        self.model = model
        self.instructions = instructions
        self.additionalInstructions = additionalInstructions
        self.messages = messages
        self.stream = stream
        self.files = files
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(organizationId, forKey: .organizationId)
        try container.encode(assistantId, forKey: .assistantId)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)  // Always encode stream since it's not optional
        
        // Only encode optional values if they are present and valid
        if let threadId = threadId, threadId > 0 {
            try container.encode(threadId, forKey: .threadId)
        }
        if let model = model {
            try container.encode(model, forKey: .model)
        }
        if let instructions = instructions, !instructions.isEmpty {
            try container.encode(instructions, forKey: .instructions)
        }
        if let additionalInstructions = additionalInstructions, !additionalInstructions.isEmpty {
            try container.encode(additionalInstructions, forKey: .additionalInstructions)
        }
        if !files.isEmpty {
            try container.encode(files, forKey: .files)
        }
    }
    
    /// Converts the payload into a dictionary representation
    public func toDict() -> [String: Any] {
        // Use JSONEncoder to properly handle null values
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback to basic dictionary if encoding fails
            return [
                "organization_id": organizationId,
                "assistant_id": assistantId,
                "messages": messages.map { $0.dictionaryRepresentation() }
            ]
        }
        return dict
    }
}

/// Represents a file input which can either be a base64 string or a file path
public enum FileInput: Codable {
    case base64String(String)
    case filePath(URL)
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
public enum FreddyError: Error, Equatable, LocalizedError, Sendable {
    // Network related errors
    case invalidURL(url: String)
    case invalidResponse(description: String)
    case httpError(statusCode: Int, description: String)
    case networkTimeout(timeoutInterval: TimeInterval)
    case noInternetConnection
    case serverUnavailable
    
    // Data related errors
    case noData
    case invalidData(description: String)
    case decodingError(description: String, originalError: Error?)
    case encodingError(description: String, originalError: Error?)
    case dataCorrupted(details: String)
    
    // Authentication errors
    case unauthorized(reason: String)
    case forbidden(reason: String)
    case tokenExpired
    case invalidCredentials(details: String)
    
    // Resource errors
    case resourceNotFound(resource: String)
    case resourceAlreadyExists(resource: String)
    case resourceLimitExceeded(resource: String, limit: String)
    
    // Business logic errors
    case invalidOperation(operation: String, reason: String)
    case validationError(field: String, reason: String)
    case businessRuleViolation(rule: String, details: String)
    
    // File handling errors
    case fileError(path: String, reason: String)
    case fileNotFound(path: String)
    case invalidFileFormat(expectedFormat: String)
    
    // Stream related errors
    case streamError(description: String)
    case streamDisconnected(reason: String)
    case invalidStreamState(details: String)
    
    // Generic errors
    case internalError(description: String)
    case unexpectedError(description: String)
    case customError(code: String, message: String)

    public var errorDescription: String? {
        switch self {
        // Network related errors
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse(let description):
            return "Invalid response: \(description)"
        case .httpError(let statusCode, let description):
            return "HTTP Error \(statusCode): \(description)"
        case .networkTimeout(let interval):
            return "Network request timed out after \(interval) seconds"
        case .noInternetConnection:
            return "No internet connection available"
        case .serverUnavailable:
            return "Server is currently unavailable"
            
        // Data related errors
        case .noData:
            return "No data received"
        case .invalidData(let description):
            return "Invalid data: \(description)"
        case .decodingError(let description, let error):
            return "Decoding error: \(description)" + (error.map { " (\($0))" } ?? "")
        case .encodingError(let description, let error):
            return "Encoding error: \(description)" + (error.map { " (\($0))" } ?? "")
        case .dataCorrupted(let details):
            return "Data corrupted: \(details)"
            
        // Authentication errors
        case .unauthorized(let reason):
            return "Unauthorized: \(reason)"
        case .forbidden(let reason):
            return "Forbidden: \(reason)"
        case .tokenExpired:
            return "Authentication token has expired"
        case .invalidCredentials(let details):
            return "Invalid credentials: \(details)"
            
        // Resource errors
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .resourceAlreadyExists(let resource):
            return "Resource already exists: \(resource)"
        case .resourceLimitExceeded(let resource, let limit):
            return "Resource limit exceeded for \(resource): \(limit)"
            
        // Business logic errors
        case .invalidOperation(let operation, let reason):
            return "Invalid operation '\(operation)': \(reason)"
        case .validationError(let field, let reason):
            return "Validation error for '\(field)': \(reason)"
        case .businessRuleViolation(let rule, let details):
            return "Business rule violation (\(rule)): \(details)"
            
        // File handling errors
        case .fileError(let path, let reason):
            return "File error at '\(path)': \(reason)"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .invalidFileFormat(let format):
            return "Invalid file format. Expected: \(format)"
            
        // Stream related errors
        case .streamError(let description):
            return "Stream error: \(description)"
        case .streamDisconnected(let reason):
            return "Stream disconnected: \(reason)"
        case .invalidStreamState(let details):
            return "Invalid stream state: \(details)"
            
        // Generic errors
        case .internalError(let description):
            return "Internal error: \(description)"
        case .unexpectedError(let description):
            return "Unexpected error: \(description)"
        case .customError(let code, let message):
            return "[\(code)] \(message)"
        }
    }
    
    public static func == (lhs: FreddyError, rhs: FreddyError) -> Bool {
        return lhs.errorDescription == rhs.errorDescription
    }
    
    // Helper method to convert HTTP status codes to appropriate FreddyError cases
    public static func fromHTTPStatus(_ statusCode: Int, description: String = "") -> FreddyError {
        switch statusCode {
        case 400:
            return .invalidOperation(operation: "HTTP Request", reason: description.isEmpty ? "Bad Request" : description)
        case 401:
            return .unauthorized(reason: description.isEmpty ? "Authentication required" : description)
        case 403:
            return .forbidden(reason: description.isEmpty ? "Access denied" : description)
        case 404:
            return .resourceNotFound(resource: description.isEmpty ? "Requested resource" : description)
        case 408:
            return .networkTimeout(timeoutInterval: 30)
        case 409:
            return .resourceAlreadyExists(resource: description.isEmpty ? "Resource" : description)
        case 429:
            return .resourceLimitExceeded(resource: "API", limit: description.isEmpty ? "Rate limit exceeded" : description)
        case 500:
            return .internalError(description: description.isEmpty ? "Internal server error" : description)
        case 503:
            return .serverUnavailable
        default:
            return .httpError(statusCode: statusCode, description: description.isEmpty ? "Unknown error" : description)
        }
    }
}

// MARK: - FreddyError Extension for Common Error Patterns
public extension FreddyError {
    // Helper method to create error from network error
    static func from(_ error: Error) -> FreddyError {
        switch error {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet:
                return .noInternetConnection
            case .timedOut:
                return .networkTimeout(timeoutInterval: TimeInterval(30))
            case .cannotFindHost, .cannotConnectToHost:
                return .serverUnavailable
            default:
                return .unexpectedError(description: urlError.localizedDescription)
            }
        case let decodingError as DecodingError:
            switch decodingError {
            case .dataCorrupted(let context):
                return .dataCorrupted(details: context.debugDescription)
            case .keyNotFound(let key, _):
                return .decodingError(description: "Missing key: \(key.stringValue)", originalError: decodingError)
            case .valueNotFound(let type, _):
                return .decodingError(description: "Missing value of type: \(type)", originalError: decodingError)
            case .typeMismatch(let type, _):
                return .decodingError(description: "Type mismatch for type: \(type)", originalError: decodingError)
            @unknown default:
                return .decodingError(description: decodingError.localizedDescription, originalError: decodingError)
            }
        default:
            return .unexpectedError(description: error.localizedDescription)
        }
    }
    
    // Helper method for validation errors
    static func validationFailed(_ field: String, message: String) -> FreddyError {
        return .validationError(field: field, reason: message)
    }
    
    // Helper method for stream errors
    static func streamFailed(_ reason: String, disconnect: Bool = false) -> FreddyError {
        return disconnect ? .streamDisconnected(reason: reason) : .streamError(description: reason)
    }
}

// MARK: - FreddyError Extension for Debug Information
public extension FreddyError {
    var debugDescription: String {
        return """
        Error Type: \(String(describing: self))
        Description: \(errorDescription ?? "No description available")
        """
    }
    
    var isNetworkError: Bool {
        switch self {
        case .invalidURL, .invalidResponse, .httpError, .networkTimeout, .noInternetConnection, .serverUnavailable:
            return true
        default:
            return false
        }
    }
    
    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized, .forbidden, .tokenExpired, .invalidCredentials:
            return true
        default:
            return false
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .networkTimeout, .noInternetConnection, .serverUnavailable:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500
        default:
            return false
        }
    }
}

// MARK: - Perform HTTPS Request Function
public static func performRequest<T: Decodable>(
    endpoint: String,
    method: HTTPMethod,
    config: Config,
    body: Data? = nil,
    emptyResponse: Bool = false,
    decoder: JSONDecoder = JSONDecoder(),
    completion: @Sendable @escaping (Result<T?, FreddyError>) -> Void
) {
    // Capture values before async block to prevent data races
    let fullUrl = config.baseUrl + endpoint
    let authToken = config.backendKey
    
    // 1. Construct the URL
    guard let url = URL(string: fullUrl) else {
        DispatchQueue.main.async {
            completion(.failure(.invalidURL(url: fullUrl)))
        }
        return
    }
    
    // 2. Configure the request
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    if let body = body, [.post, .put].contains(method) {
        request.httpBody = body
    }
    
    // 3. Perform the network request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            // 4. Handle network errors
            if let error = error {
                completion(.failure(FreddyError.from(error)))
                return
            }
            
            // 5. Validate the response and status code
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(description: "Unknown response type")))
                return
            }
            
            // 6. Handle non-successful HTTP status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data {
                    // Try to extract error details from response
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let dictionary = jsonObject as? [String: Any],
                       let errorMessage = dictionary["message"] as? String {
                        if httpResponse.statusCode == 404 {
                            completion(.failure(.resourceNotFound(resource: errorMessage)))
                        } else if httpResponse.statusCode == 401 {
                            completion(.failure(.invalidCredentials(details: errorMessage)))
                        } else {
                            completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode, description: errorMessage)))
                        }
                    } else {
                        completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode)))
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
                completion(.failure(.decodingError(description: error.localizedDescription, originalError: error)))
            }
        }
    }
    task.resume()
}

// MARK: - EmptyResponse Struct
/// A placeholder structure for handling empty responses from the server.
struct EmptyResponse: Decodable {}
