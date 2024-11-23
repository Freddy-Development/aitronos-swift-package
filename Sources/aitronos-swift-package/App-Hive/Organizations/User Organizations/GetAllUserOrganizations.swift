//
//  GetAllUserOrganizations.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - UserOrganization Struct
    /// The structure representing an organization and whether the user has joined it.
    struct UserOrganization: Decodable {
        public let organizationId: Int
        public let organizationName: String
        public let description: String
        public let isUserJoined: Bool
        
        enum CodingKeys: String, CodingKey {
            case organizationId = "OrganizationId"
            case organizationName = "OrganizationName"
            case description = "Description"
            case isUserJoined = "IsUserJoined"
        }
    }

    // MARK: - Get All User Organizations Function
    /// Retrieves all organizations and marks the ones the user has joined.
    ///
    /// - Parameters:
    ///   - closure: Completion handler that returns a `Result` with an array of `UserOrganization` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `GET` request to fetch all organizations and indicates the ones the user has joined using the `IsUserJoined` flag.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().getAllUserOrganizations { result in
    ///       switch result {
    ///       case .success(let organizations):
    ///           organizations.forEach { org in
    ///               //print("Organization: \(org.organizationName), Joined: \(org.isUserJoined)")
    ///           }
    ///       case .failure(let error):
    ///           //print("Failed to retrieve user organizations: \(error)")
    ///       }
    ///   }
    ///   ```
    func getAllUserOrganizations(
        closure: @escaping @Sendable (Result<[UserOrganization], FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/user/organizations/all"
        
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
        ) { (result: Result<[UserOrganization]?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Return the list of organizations
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
