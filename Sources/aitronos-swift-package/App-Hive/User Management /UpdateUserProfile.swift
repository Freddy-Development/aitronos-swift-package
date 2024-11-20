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
        let fullName: String
        let street: String
        let postCode: String
        let city: String
        let country: Int
        let phoneNumber: String
    }

    // MARK: - ProfileImage Struct
    /// The structure representing the user's profile image.
    struct ProfileImage: Encodable {
        let background: String
        let image: String
    }

    // MARK: - UpdateUserProfileRequest Struct
    /// The structure representing the request body for updating the user's profile.
    struct UpdateUserProfileRequest: Encodable {
        let fullName: String
        let lastName: String
        let userName: String
        let email: String
        let address: Address
        let profileImage: ProfileImage
        let birthday: String
        let gender: Int
        let country: Int
        let password: String
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
        let config = Config(baseUrl: baseUrl, backendKey: userToken)
        
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
