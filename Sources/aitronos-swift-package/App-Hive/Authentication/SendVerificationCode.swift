//
//  SendVerificationCode.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - SendVerificationCodeRequest Struct
    /// The structure representing the request body for sending a verification code to a user.
    ///
    /// This request requires the user's email address.
    struct SendVerificationCodeRequest: Encodable {
        let email: String
    }

    // MARK: - SendVerificationCodeResponse Struct
    /// The structure representing the response from the API after sending a verification code.
    ///
    /// The response contains the verification `code` as a string.
    struct SendVerificationCodeResponse: Decodable {
        let code: String
    }

    // MARK: - Send Verification Code Function
    /// Sends a 4-digit verification code to the provided email address.
    ///
    /// - Parameters:
    ///   - email: The email address of the user to send the verification code.
    ///   - closure: Completion handler that returns a `Result` with `SendVerificationCodeResponse` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `POST` request to send a verification code to the user's email.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().sendVerificationCode(email: "user@example.com") { result in
    ///       switch result {
    ///       case .success(let response):
    ///           print("Verification Code: \(response.code)")
    ///       case .failure(let error):
    ///           print("Failed to send verification code: \(error)")
    ///       }
    ///   }
    ///   ```
    func sendVerificationCode(
        email: String,
        closure: @escaping @Sendable (Result<SendVerificationCodeResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/verificationEmail"
        
        // 2. Create request body
        let requestBody = SendVerificationCodeRequest(email: email)
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 4. Create config with Bearer token
        let config = Config(baseUrl: baseUrl, backendKey: userToken)
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<SendVerificationCodeResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Pass the non-nil response containing the verification code
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
