//
//  GetAssistants.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 29.10.2024.
//

import Foundation

public extension AppHive {
    
    // MARK: - Assistant Struct
    /// The structure representing an assistant.
    struct Assistant: Decodable {
        public let id: String
        public let name: String
        public let instructions: String
    }

    // MARK: - Get Assistants Function
    /// Retrieves a list of all assistants for a given organization.
    ///
    /// - Parameters:
    ///   - organizationID: The ID of the organization from which to fetch assistants.
    ///   - closure: Completion handler that returns a `Result` with an array of `Assistant` on success or `FreddyError` on failure.
    ///
    /// This function performs an HTTP `GET` request to fetch all assistants assigned to the organization with the given `ID`.
    ///
    /// - Example:
    ///   ```swift
    ///   AppHive().getAssistants(organizationID: "12345") { result in
    ///       switch result {
    ///       case .success(let assistants):
    ///           assistants.forEach { print("Assistant Name: \($0.name), ID: \($0.id)") }
    ///       case .failure(let error):
    ///           print("Failed to retrieve assistants: \(error)")
    ///       }
    ///   }
    ///   ```
    func getAssistants(
        organizationID: String,
        closure: @escaping @Sendable (Result<[Assistant], FreddyError>) -> Void
    ) {
        // 1. API Endpoint with the organization ID path parameter
        let endpoint = "/v1/organizations/\(organizationID)/assistants"
        
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
        ) { (result: Result<[Assistant]?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response)) // Return the list of assistants
                } else {
                    closure(.failure(.noData)) // Handle empty response case
                }
                
            case .failure(let error):
                closure(.failure(error)) // Pass the error to the caller
            }
        }
    }
}
