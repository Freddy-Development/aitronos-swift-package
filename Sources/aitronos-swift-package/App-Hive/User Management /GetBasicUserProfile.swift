//
//  GetBasicUserProfile.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - BasicUserProfileResponse Struct
    /// The structure representing the basic profile information of the user.
    struct BasicUserProfileResponse: Decodable {
        public let fullName: String
        public let userName: String
        public let email: String
    }

    // MARK: - Get Basic User Profile Function
    /// Fetches the basic profile information of the currently logged-in user.
    ///
    /// - Parameters:
    ///   - closure: Completion handler that returns a `Result` with `BasicUserProfileResponse` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `GET` request to fetch the user's basic profile information.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().getBasicUserProfile { result in
    ///       switch result {
    ///       case .success(let profile):
    ///           print("Full Name: \(profile.fullName), Username: \(profile.userName), Email: \(profile.email)")
    ///       case .failure(let error):
    ///           print("Failed to get basic user profile: \(error)")
    ///       }
    ///   }
    ///   ```
    func getBasicUserProfile(
        closure: @Sendable @escaping (Result<BasicUserProfileResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user"
        
        // 2. Create config with Bearer token
        let config = Config(baseURL: baseURL, backendKey: userToken)
        
        // 3. Perform the GET request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .get,
            config: config,
            body: nil,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<BasicUserProfileResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Return the basic user profile
                } else {
                    closure(.failure(.noData)) // Handle case where no data is returned
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
