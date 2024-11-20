//
//  AddUserOrganization.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - AddUserOrganizationRequest Struct
    /// The structure representing the request body for adding the user to an organization.
    ///
    /// This request requires the `organizationId`, `organizationName`, `description`, and the `isUserJoined` flag.
    struct AddUserOrganizationRequest: Encodable {
        let organizationId: Int
        let organizationName: String
        let description: String
        let isUserJoined: Bool
        
        enum CodingKeys: String, CodingKey {
            case organizationId = "organizationId"
            case organizationName = "organizationName"
            case description = "description"
            case isUserJoined = "isUserJoined"
        }
    }

    // MARK: - Add User to Organization Function
    /// Adds the signed-in user to the specified organization.
    ///
    /// - Parameters:
    ///   - organizationId: The ID of the organization to join.
    ///   - organizationName: The name of the organization.
    ///   - description: A description of the organization.
    ///   - isUserJoined: A flag indicating if the user should be joined (typically set to `true`).
    ///   - closure: Completion handler that returns a `Result<Bool, FreddyError>` indicating success or failure.
    ///
    /// This function performs an HTTP `POST` request to add the signed-in user to the specified organization.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().addUserOrganization(
    ///       organizationId: 123,
    ///       organizationName: "Organization Name",
    ///       description: "This is an organization.",
    ///       isUserJoined: true
    ///   ) { result in
    ///       switch result {
    ///       case .success(let success):
    ///           print("User successfully added to the organization: \(success)")
    ///       case .failure(let error):
    ///           print("Failed to add user to organization: \(error)")
    ///       }
    ///   }
    ///   ```
    func addUserOrganization(
        organizationId: Int,
        organizationName: String,
        description: String,
        isUserJoined: Bool = true,
        closure: @escaping @Sendable (Result<Bool, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/organizations/add"
        
        // 2. Create request body
        let requestBody = AddUserOrganizationRequest(
            organizationId: organizationId,
            organizationName: organizationName,
            description: description,
            isUserJoined: isUserJoined
        )
        
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
        ) { (result: Result<Bool?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Return the boolean response
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
