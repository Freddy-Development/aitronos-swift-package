//
//  UpdateUserProfile.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - Address Struct
    /// The structure representing the user's address in the profile.
    struct Address: Encodable {
        public let fullName: String
        public let street: String
        public let postCode: String
        public let city: String
        public let country: Int
        public let phoneNumber: String
    }

    // MARK: - ProfileImage Struct
    /// The structure representing the user's profile image.
    struct ProfileImage: Encodable {
        public let background: String
        public let image: String
    }

    // MARK: - UpdateUserProfileRequest Struct
    /// The structure representing the request body for updating the user's profile.
    struct UpdateUserProfileRequest: Encodable {
        public let fullName: String
        public let lastName: String
        public let userName: String
        public let email: String
        public let address: Address
        public let profileImage: ProfileImage
        public let birthday: String
        public let gender: Int
        public let country: Int
        public let password: String
    }

    // MARK: - Update User Profile Function
    /// Updates the user's profile data.
    ///
    /// - Parameters:
    ///   - profileData: The data representing the user's updated profile.
    ///   - closure: Completion handler that returns a `Result` indicating success or `FreddyError` in case of failure.
    ///
    /// This function performs an HTTP `POST` request to update the user's profile with the provided data.
    ///
    /// - Example:
    ///   ```swift
    ///   let profileData = UpdateUserProfileRequest(
    ///       fullName: "John",
    ///       lastName: "Doe",
    ///       userName: "johndoe",
    ///       email: "johndoe@example.com",
    ///       address: Address(
    ///           fullName: "John Doe",
    ///           street: "123 Main St",
    ///           postCode: "12345",
    ///           city: "Sample City",
    ///           country: 1,
    ///           phoneNumber: "1234567890"
    ///       ),
    ///       profileImage: ProfileImage(
    ///           background: "#FFFFFF",
    ///           image: "imageBase64EncodedString"
    ///       ),
    ///       birthday: "2024-09-25T07:23:28.859Z",
    ///       gender: 0,
    ///       country: 1,
    ///       password: "password123"
    ///   )
    ///
    ///   AppHive().updateUserProfile(profileData: profileData) { result in
    ///       switch result {
    ///       case .success:
    ///           print("Profile updated successfully!")
    ///       case .failure(let error):
    ///           print("Failed to update profile: \(error)")
    ///       }
    ///   }
    ///   ```
    func updateUserProfile(
        profileData: UpdateUserProfileRequest,
        closure: @Sendable @escaping (Result<Void, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user"
        
        // 2. Encode request body as JSON
        guard let bodyData = try? JSONEncoder().encode(profileData) else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to serialize request body")))
            }
            return
        }
        
        // 3. Create config with Bearer token
        let config = Config(baseURL: baseURL, backendKey: userToken)
        
        // 4. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: true,  // Indicate no response body is expected
            decoder: JSONDecoder()
        ) { (result: Result<EmptyResponse?, FreddyError>) in // Use EmptyResponse? as the result type
            switch result {
            case .success:
                closure(.success(())) // Return success with Void
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
