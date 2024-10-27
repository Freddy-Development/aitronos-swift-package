//
//  CheckUsernameDuplication.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - CheckUsernameRequest Struct
    /// The structure representing the request body for checking if a username is taken.
    struct CheckUsernameRequest: Encodable {
        public let userId: Int
        public let userName: String
    }

    // MARK: - Check Username Duplication Function
    /// Checks whether the new username is already taken.
    ///
    /// - Parameters:
    ///   - userId: The unique ID of the user (required).
    ///   - userName: The username to check for duplication (required).
    ///   - token: Bearer token for authentication.
    ///   - closure: Completion handler that returns a `Result` with a `Bool` indicating success (`true` if the username is available, `false` if taken), or a `FreddyError` in case of error.
    ///
    /// This function performs an HTTP `POST` request to check if the provided username is already in use in the system. It returns a Boolean flag indicating the result.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive.checkUsernameDuplication(
    ///       userId: 123,
    ///       userName: "desired_username",
    ///       token: "BearerTokenHere"
    ///   ) { result in
    ///       switch result {
    ///       case .success(let isAvailable):
    ///           print("Username available: \(isAvailable)")
    ///       case .failure(let error):
    ///           print("Failed to check username: \(error)")
    ///       }
    ///   }
    ///   ```
    func checkUsernameDuplication(
        userId: Int,
        userName: String,
        closure: @Sendable @escaping (Result<Bool, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/username/checkforduplicate"
        
        // 2. Create request body
        let requestBody = CheckUsernameRequest(userId: userId, userName: userName)
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 4. Create config with Bearer token
        let config = Config(baseURL: baseURL, backendKey: userToken)
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<Bool?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response))
                } else {
                    closure(.failure(.noData))
                }
                
            case .failure(let error):
                closure(.failure(error))
            }
        }
    }
}
