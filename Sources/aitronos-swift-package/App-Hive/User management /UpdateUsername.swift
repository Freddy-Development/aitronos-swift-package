//
//  UpdateUsername.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - UpdateUsernameRequest Struct
    /// The structure representing the request body for updating a user's username.
    struct UpdateUsernameRequest: Encodable {
        let userId: Int
        let userName: String
    }

    // MARK: - Update Username Function
    /// Updates the unique username for a user.
    ///
    /// - Parameters:
    ///   - userId: The unique ID of the user (required).
    ///   - userName: The new username to update (required).
    ///   - token: Bearer token for authentication.
    ///   - closure: Completion handler that returns a `Result` with a `Bool` indicating success (true) or failure (false), or a `FreddyError` in case of error.
    ///
    /// This function performs an HTTP `POST` request to update the user's username in the system. It returns a Boolean flag indicating the result of the operation.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive.updateUsername(
    ///       userId: 123,
    ///       userName: "new_username",
    ///       token: "BearerTokenHere"
    ///   ) { result in
    ///       switch result {
    ///       case .success(let success):
    ///           print("Username updated: \(success)")
    ///       case .failure(let error):
    ///           print("Failed to update username: \(error)")
    ///       }
    ///   }
    ///   ```
    func updateUsername(
        userId: Int,
        userName: String,
        closure: @Sendable @escaping (Result<Bool, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/\(userId)/username/update"
        
        // 2. Create request body
        let requestBody = UpdateUsernameRequest(userId: userId, userName: userName)
        
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
