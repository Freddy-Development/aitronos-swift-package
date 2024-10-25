//
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
        let token: String
        let refreshToken: RefreshToken
        let deviceId: String
        
        struct RefreshToken: Decodable, Sendable {
            let token: String
            let expiry: String
        }
    }
    
    // MARK: - LoginError Struct
    /// Represents an error received during the login process.
    struct LoginError: Decodable, Error, Sendable {
        let message: String
    }
    
    // MARK: - Login Function
    /// Authenticates a user with their email or username and password.
    ///
    /// - Parameters:
    ///   - usernmeEmail: The username or email of the user attempting to log in.
    ///   - password: The user's password.
    ///   - closure: A closure that returns a `Result` containing either the `LoginResponse` on success or a `FreddyError` on failure.
    ///
    /// The function performs an HTTP `POST` request to the `/auth/login` endpoint of the Freddy API to authenticate the user and return a token and refresh token. The request does not require Bearer authorization since it's the login step.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive.login(usernmeEmail: "user@example.com", password: "password123") { result in
    ///       switch result {
    ///       case .success(let loginResponse):
    ///           print("Logged in! Token: \(loginResponse.token)")
    ///       case .failure(let error):
    ///           print("Login failed: \(error)")
    ///       }
    ///   }
    ///   ```
    static func login(
        usernmeEmail: String,
        password: String,
        closure: @Sendable @escaping (Result<LoginResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/auth/login"
        
        // 2. Create request body as JSON
        let requestBody: [String: String] = [
            "emailOrUserName": usernmeEmail,
            "password": password
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 3. Config without authorization (since this is the login endpoint)
        let config = Config(baseURL: "https://freddy-api.aitronos.com", backendKey: "")
        
        // 4. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<LoginResponse?, FreddyError>) in  // Result now expects LoginResponse?
            
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Pass the non-nil response
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
