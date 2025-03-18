//
//  RunResponse.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

/// Represents the response structure for the `getRunResponse` endpoint.
public struct RunResponse: Decodable {
    public let response: String
}

extension FreddyApi {
    @available(macOS 12.0, *)
    public func getRunResponse(organizationId: Int, threadKey: String) async throws -> RunResponse {
        let url = URL(string: "\(self.baseUrl)/messages/run-response")
        guard let url = url else {
            throw FreddyError.invalidURL(url: "\(self.baseUrl)/messages/run-response")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // Changed to POST as payloads can't be sent in GET requests
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "organization_id": organizationId,
            "thread_key": threadKey
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FreddyError.invalidResponse(description: "Unknown response type")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Decode the response into `RunResponse`
                return try JSONDecoder().decode(RunResponse.self, from: data)
            default:
                // Handle server-side errors with detailed parsing
                throw parseFreddyError(from: data, statusCode: httpResponse.statusCode)
            }
        } catch let error as FreddyError {
            throw error // Re-throw FreddyError for clarity
        } catch {
            throw FreddyError.from(error)
        }
    }
}
