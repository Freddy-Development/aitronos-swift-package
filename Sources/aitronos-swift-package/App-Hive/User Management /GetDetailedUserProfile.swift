//
//  GetDetailedUserProfile.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - DetailedUserProfileResponse Struct
    /// The structure representing the detailed profile information of the user.
    struct DetailedUserProfileResponse: Decodable {
        public let userId: Int
        public let birthday: String
        public let country: String
        public let profileImage: String
        public let timezone: String
        public let fullName: String
        public let userName: String
        public let email: String
    }

    // MARK: - Get Detailed User Profile Function
    /// Fetches the detailed profile information of the currently logged-in user.
    ///
    /// - Parameters:
    ///   - closure: Completion handler that returns a `Result` with `DetailedUserProfileResponse` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `GET` request to fetch the user's detailed profile information.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().getDetailedUserProfile { result in
    ///       switch result {
    ///       case .success(let profile):
    ///           //print("Full Name: \(profile.fullName), UserId: \(profile.userId), Timezone: \(profile.timezone)")
    ///       case .failure(let error):
    ///           //print("Failed to get detailed user profile: \(error)")
    ///       }
    ///   }
    ///   ```
    func getDetailedUserProfile(
        closure: @Sendable @escaping (Result<DetailedUserProfileResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/profile"
        
        // 2. Create config with Bearer token
        let config = Config(baseUrl: baseUrl, backendKey: userToken)
        
        // 3. Perform the GET request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .get,
            config: config,
            body: nil,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<DetailedUserProfileResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Return the detailed user profile
                } else {
                    closure(.failure(.noData)) // Handle case where no data is returned
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
