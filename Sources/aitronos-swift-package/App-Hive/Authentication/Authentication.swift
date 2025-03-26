//  Authentication.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - LoginResponse Struct
    /// Represents the response received after a successful login.
    struct LoginResponse: Decodable, Sendable {
        public let token: String
        public let refreshToken: RefreshToken
        public let deviceId: String
        
        // RefreshToken Struct inside LoginResponse
        public struct RefreshToken: Decodable, Sendable {
            public let token: String
            public let expiry: String
        }
    }
    
    // MARK: - LoginError Struct
    /// Represents an error received during the login process.
    struct LoginError: Decodable, Error, Sendable {
        public let message: String
    }
    
    // MARK: - DeviceInformation Struct
    /// Represents device information for login verification
    struct DeviceInformation: Codable, Sendable {
        let device: String
        let location: String
        let latitude: String
        let longitude: String
        let deviceId: String
        let operatingSystem: String
        let platform: String
        
        enum CodingKeys: String, CodingKey {
            case device
            case location
            case latitude
            case longitude
            case deviceId = "deviceId"
            case operatingSystem = "operatingSystem"
            case platform
        }
    }
    
    // MARK: - LoginRequest Struct
    /// Represents the login request body
    struct LoginRequest: Codable, Sendable {
        let emailorusername: String
        let password: String
        let deviceInformation: DeviceInformation
    }
    
    // MARK: - Login Function
    /// Authenticates a user with their email or username and password.
    ///
    /// - Parameters:
    ///   - usernmeEmail: The username or email of the user attempting to log in.
    ///   - password: The user's password.
    ///   - deviceInformation: Information about the device making the login request.
    ///   - closure: A closure that returns a `Result` containing either the `LoginResponse` on success or a `FreddyError` on failure.
    ///
    /// The function performs an HTTP `POST` request to the `/auth/login` endpoint of the Freddy API to authenticate the user and return a token and refresh token. The request does not require Bearer authorization since it's the login step.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive.login(usernmeEmail: "user@example.com", password: "password123") { result in
    ///       switch result {
    ///       case .success(let loginResponse):
    ///           //print("Logged in! Token: \(loginResponse.token)")
    ///       case .failure(let error):
    ///           //print("Login failed: \(error)")
    ///       }
    ///   }
    ///   ```
    static func login(
        usernmeEmail: String,
        password: String,
        deviceInformation: DeviceInformation,
        closure: @Sendable @escaping (Result<LoginResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/auth/login"
        
        // 2. Create request body
        let requestBody = LoginRequest(
            emailorusername: usernmeEmail,
            password: password,
            deviceInformation: deviceInformation
        )
        
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            closure(.failure(.invalidData(description: "Failed to serialize request body")))
            return
        }
        
        // 3. Config without authorization (since this is the login endpoint)
        let config = Config(baseUrl: "https://freddy-api.aitronos.ch", backendKey: "")
        
        // 4. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<LoginResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response))
                } else {
                    closure(.failure(.noData))
                }
            case .failure(let error):
                if case let .httpError(statusCode, description) = error {
                    switch statusCode {
                    case 404:
                        if description.contains("User name not found") {
                            closure(.failure(.resourceNotFound(resource: "User name not found")))
                        } else {
                            closure(.failure(.resourceNotFound(resource: description)))
                        }
                    case 401:
                        if description.contains("Incorrect password") {
                            closure(.failure(.invalidCredentials(details: "Incorrect password")))
                        } else {
                            closure(.failure(.invalidCredentials(details: description)))
                        }
                    case 403:
                        closure(.failure(.forbidden(reason: description)))
                    default:
                        closure(.failure(FreddyError.fromHTTPStatus(statusCode, description: description)))
                    }
                } else {
                    closure(.failure(error))
                }
            }
        }
    }
}

extension AppHive {
    @available(macOS 10.15, *)
    static func login(
        usernmeEmail: String,
        password: String,
        deviceInformation: DeviceInformation
    ) async throws -> LoginResponse {
        try await withCheckedThrowingContinuation { continuation in
            login(
                usernmeEmail: usernmeEmail,
                password: password,
                deviceInformation: deviceInformation
            ) { result in
                switch result {
                case .success(let loginResponse):
                    continuation.resume(returning: loginResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
