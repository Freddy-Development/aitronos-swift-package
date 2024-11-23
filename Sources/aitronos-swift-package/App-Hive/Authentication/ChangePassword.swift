//
//  ChangePassword.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - ChangePasswordRequest Struct
    /// The structure representing the request body for changing the user's password.
    ///
    /// This request requires the current password, the new password, and a confirmation of the new password.
    struct ChangePasswordRequest: Encodable {
        let currentPassword: String
        let newPassword: String
        let confirmPassword: String
    }

    // MARK: - ChangePasswordResponse Struct
    /// The structure representing the response when the user's password is successfully changed.
    ///
    /// This response typically contains a message confirming the password change.
    struct ChangePasswordResponse: Decodable {
        let message: String
    }

    // MARK: - Change Password Function
    /// Updates the user's password by providing the current password and the new password.
    ///
    /// - Parameters:
    ///   - currentPassword: The current password of the user.
    ///   - newPassword: The new password the user wants to set.
    ///   - confirmPassword: Confirmation of the new password (should match the `newPassword` field).
    ///   - closure: Completion handler that returns a `Result` with `ChangePasswordResponse` on success or `FreddyError` on failure.
    ///
    /// This function sends an HTTP `POST` request to update the user's password, ensuring that the old password is correctly provided. It returns a message confirming the change or an error if the update fails.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().changePassword(
    ///       currentPassword: "currentPass123",
    ///       newPassword: "newPass456",
    ///       confirmPassword: "newPass456"
    ///   ) { result in
    ///       switch result {
    ///       case .success(let response):
    ///           //print("Password changed successfully: \(response.message)")
    ///       case .failure(let error):
    ///           //print("Failed to change password: \(error)")
    ///       }
    ///   }
    ///   ```
    func changePassword(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String,
        closure: @escaping @Sendable (Result<ChangePasswordResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/auth/users/password/update"
        
        // 2. Create request body
        let requestBody = ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 4. Create a config with the Bearer token
        let config = Config(baseUrl: baseUrl, backendKey: userToken)
        
        // 5. Perform the request
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<ChangePasswordResponse?, FreddyError>) in
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
