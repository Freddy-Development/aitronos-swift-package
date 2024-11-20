//
//  RunCreate.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

/// Represents the response structure for the `createRun` endpoint.
public struct RunCreateResponse: Decodable {
    public let runKey: String
    public let threadKey: String
}

extension FreddyApi {
    @available(macOS 12.0, *)
    public func createRun(payload: MessageRequestPayload) async throws -> RunCreateResponse {
        let url = URL(string: "\(self.baseUrl)/messages/run-create")
        guard let url = url else {
            throw FreddyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payloadDict = payload.toDict()
        request.httpBody = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FreddyError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Decode the response data into `RunCreateResponse`
                return try JSONDecoder().decode(RunCreateResponse.self, from: data)
            default:
                // Handle server-side errors with detailed parsing
                throw self.parseFreddyError(from: data, statusCode: httpResponse.statusCode)
            }
        } catch let error as FreddyError {
            throw error // Re-throw FreddyError for clarity
        } catch {
            throw FreddyError.networkIssue(description: error.localizedDescription)
        }
    }
}
