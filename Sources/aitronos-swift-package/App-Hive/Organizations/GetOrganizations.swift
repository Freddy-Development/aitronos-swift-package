//
//  GetOrganizations.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - Organization Struct
    /// The structure representing an organization.
    struct Organization: Decodable {
        public let id: Int
        public let name: String
    }

    // MARK: - Get Organizations Function
    /// Retrieves a list of all organizations.
    ///
    /// - Parameters:
    ///   - closure: Completion handler that returns a `Result` with an array of `Organization` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `GET` request to fetch all organizations.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().getOrganizations { result in
    ///       switch result {
    ///       case .success(let organizations):
    ///           organizations.forEach { print("Organization Name: \($0.name), Key: \($0.key)") }
    ///       case .failure(let error):
    ///           print("Failed to retrieve organizations: \(error)")
    ///       }
    ///   }
    ///   ```
    func getOrganizations(
        closure: @escaping @Sendable (Result<[Organization], FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/organizations"
        
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
        ) { (result: Result<[Organization]?, FreddyError>) in
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
