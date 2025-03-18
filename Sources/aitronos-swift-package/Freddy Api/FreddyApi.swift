//
//  FreddyApi.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

public final class FreddyApi: Sendable {
    public let baseUrls: [String: String] = ["v1": "https://freddy-api.aitronos.com/v1"]
    public let baseUrl: String
    public let userToken: String
    public init (userToken: String) {
        self.userToken = userToken
        guard let url = baseUrls["v1"] else {
            fatalError("Unsupported API version")
        }
        self.baseUrl = url
    }
    
    /// Parses server-side errors into appropriate `FreddyError` cases.
    /// - Parameters:
    ///   - data: The raw data returned from the server.
    ///   - statusCode: The HTTP status code of the response.
    /// - Returns: A `FreddyError` instance representing the server error.
    public func parseFreddyError(from data: Data, statusCode: Int) -> FreddyError {
        // Try to parse error data
        let errorInfo = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        let errorMessage = (errorInfo["error"] as? String) ?? (errorInfo["message"] as? String) ?? ""
        
        // Handle specific error cases
        switch statusCode {
        case 400:
            if errorMessage.contains("credentials") {
                return .invalidCredentials(details: errorMessage)
            }
            if errorMessage.contains("validation") {
                return .validationError(field: "request", reason: errorMessage)
            }
            return .invalidOperation(operation: "API Request", reason: errorMessage)
            
        case 401:
            if errorMessage.contains("expired") {
                return .tokenExpired
            }
            return .unauthorized(reason: errorMessage.isEmpty ? "Authentication required" : errorMessage)
            
        case 403:
            return .forbidden(reason: errorMessage.isEmpty ? "Access denied" : errorMessage)
            
        case 404:
            let resource = errorMessage.contains("user") ? "User" :
                          errorMessage.contains("assistant") ? "Assistant" :
                          errorMessage.contains("thread") ? "Thread" : "Resource"
            return .resourceNotFound(resource: resource)
            
        case 408:
            return .networkTimeout(timeoutInterval: 30)
            
        case 409:
            return .resourceAlreadyExists(resource: errorMessage.isEmpty ? "Resource" : errorMessage)
            
        case 429:
            return .resourceLimitExceeded(
                resource: "API",
                limit: errorMessage.isEmpty ? "Rate limit exceeded" : errorMessage
            )
            
        case 500...599:
            return .internalError(
                description: errorMessage.isEmpty ? "Internal server error" : errorMessage
            )
            
        default:
            return .httpError(statusCode: statusCode, description: errorMessage.isEmpty ? "Unknown error" : errorMessage)
        }
    }
    
    @available(macOS 12.0, *)
    public func createThread(organizationId: Int) async throws -> ThreadCreateResponse {
        let url = URL(string: "\(self.baseUrl)/threads/create")
        guard let url = url else {
            throw FreddyError.invalidURL(url: "\(self.baseUrl)/threads/create")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["organization_id": organizationId]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FreddyError.invalidResponse(description: "Unknown response type")
        }
        
        if httpResponse.statusCode != 200 {
            throw self.parseFreddyError(from: data, statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(ThreadCreateResponse.self, from: data)
    }
}
