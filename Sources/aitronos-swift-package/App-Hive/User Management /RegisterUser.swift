//
//  RegisterUser.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - RegisterUserRequest Struct
    /// The structure representing the request body for registering a new user.
    struct RegisterUserRequest: Encodable {
        let email: String
        let password: String
        let fullName: String
    }
    
    // MARK: - RegisterUserResponse Struct
    /// The structure representing the response from the register user API.
    struct RegisterUserResponse: Decodable {
        let verificationResponse: VerificationResponse
        
        struct VerificationResponse: Decodable {
            let userId: Int
            let emailKey: String
        }
    }

    /// Register a new user.
    ///
    /// - Parameters:
    ///   - email: The email of the user to register (required).
    ///   - password: The password for the new user account (required).
    ///   - fullName: The full name of the user (required).
    ///   - token: Bearer token for authentication.
    ///   - closure: Completion handler that returns a `Result` with either `RegisterUserResponse` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `POST` request to create a new user in the system. A new `userId` and `emailKey` are returned in the response.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive.registerUser(
    ///       email: "user@example.com",
    ///       password: "password123",
    ///       fullName: "John Doe",
    ///       token: "BearerTokenHere"
    ///   ) { result in
    ///       switch result {
    ///       case .success(let response):
    ///           print("User ID: \(response.verificationResponse.userId), Email Key: \(response.verificationResponse.emailKey)")
    ///       case .failure(let error):
    ///           print("Registration failed: \(error)")
    ///       }
    ///   }
    ///   ```
    func registerUser(
        email: String,
        password: String,
        fullName: String,
        closure: @Sendable @escaping (Result<RegisterUserResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/register"
        
        // 2. Create request body
        let requestBody = RegisterUserRequest(email: email, password: password, fullName: fullName)
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 4. Create config without backend key
        let config = Config(baseURL: baseURL, backendKey: "") // No backend key needed
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<RegisterUserResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response))
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
