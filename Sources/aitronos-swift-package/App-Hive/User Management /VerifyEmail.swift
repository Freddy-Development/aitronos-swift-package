//
//  UpdateUserProfile.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 12.3.2025.
//

import Foundation

public extension AppHive {
    
    // MARK: - VerifyEmailRequest Struct
    /// The structure representing the request body for verifying an email.
    struct VerifyEmailRequest: Encodable {
        let email: String
    }
    
    // MARK: - VerifyEmailResponse Struct
    /// The structure representing the response from the API after verifying an email.
    struct VerifyEmailResponse: Decodable {
        public let success: Bool

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.success = try container.decode(Bool.self)
        }
    }
    
    // MARK: - Verify Email Function
    /// Verifies the provided email address.
    ///
    /// - Parameters:
    ///   - email: The email address to verify.
    ///   - closure: Completion handler that returns a `Result` with `VerifyEmailResponse` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `POST` request to verify the user's email.
    static func verifyEmail(
        email: String,
        closure: @escaping @Sendable (Result<VerifyEmailResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/verifyEmail"
        
        // 2. Create request body
        let requestBody = VerifyEmailRequest(email: email)
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            closure(.failure(.invalidData(description: "Failed to serialize request body")))
            return
        }
        
        // 4. Create config with Bearer token
        let config = Config(baseUrl: AppHive.baseUrl, backendKey: "")
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<VerifyEmailResponse?, FreddyError>) in
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
