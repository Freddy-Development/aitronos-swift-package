//
//  VerifyToken.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    /// The structure representing the request body for verifying a token.
    struct VerifyTokenRequest: Encodable {
        let token: Int
        let emailKey: String
        let isRegister: Bool
    }
    
    /// The structure representing the response from the token verification API.
    struct VerifyTokenResponse: Decodable {
        public let success: Bool
        public let message: String?
    }
    
    /// Verifies a token sent to the user's email.
    /// - Parameters:
    ///   - token: The verification token sent to the user's email
    ///   - emailKey: The email key received during registration
    ///   - isRegister: Whether this verification is for registration (true) or other purposes (false)
    ///   - completion: A completion handler that returns either a success with the verification response or a failure with an error
    func verifyToken(token: Int, emailKey: String, isRegister: Bool = true, completion: @Sendable @escaping (Result<VerifyTokenResponse, FreddyError>) -> Void) {
        // 1. API Endpoint
        let endpoint = "/v1/token/verify"
        
        // 2. Create request body
        let requestBody = VerifyTokenRequest(token: token, emailKey: emailKey, isRegister: isRegister)
        
        // 3. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(.invalidData(description: "Failed to serialize request body")))
            return
        }
        
        // 4. Create config with Bearer token
        let config = Config(baseUrl: AppHive.baseUrl, backendKey: userToken)
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<VerifyTokenResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    completion(.success(response))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 