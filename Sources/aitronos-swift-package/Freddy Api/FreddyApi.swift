//
//  FreddyApi.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

public class FreddyApi {
    public let baseUrls: [String: String] = ["v1": "https://freddy-api.aitronos.com/v1"]
    public let baseUrl: String
    public var userToken: String {
        didSet {
            if userToken.isEmpty {
                fatalError("AppHive API Key cannot be empty")
            }
        }
    }
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
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .httpError(statusCode: statusCode, description: "Unable to parse error response.")
        }
        
        let title = json["title"] as? String ?? "Unknown Error"
        let message = json["message"] as? String ?? "No detailed message provided."
        
        switch title {
        case "InvalidDataException":
            if message.contains("Invalid assistant") {
                return .httpError(statusCode: statusCode, description: "Invalid assistant specified.")
            }
        case "InvalidCredentialsException":
            return .invalidCredentials
        default:
            break
        }
        
        return .httpError(statusCode: statusCode, description: "\(title): \(message)")
    }
}
