//
//  ExecuteRun.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

/// Represents the structure of the response from the `executeRun` endpoint.
public struct ExecuteRunResponse: Decodable, Sendable {
    public let event: String
    public let status: String
    public let isResponse: Bool
    public let response: String?
    public let responseType: String
    public let threadId: Int

    private enum CodingKeys: String, CodingKey {
        case event
        case status
        case isResponse
        case response
        case responseType
        case threadId
    }
}

extension FreddyApi {
    /// Executes a non-streaming run request.
    /// - Parameter payload: The payload for the run request.
    /// - Returns: An array of `ExecuteRunResponse` containing the results of the run.
    /// - Throws: A `FreddyError` if the request fails or the response cannot be decoded.
    @available(macOS 12.0, *)
    public func executeRun(payload: MessageRequestPayload) async throws -> [ExecuteRunResponse]? {
        let url = URL(string: "\(self.baseUrl)/messages/run-stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add "stream": false to the payload
        var payloadDict = payload.toDict()
        payloadDict["stream"] = false
        
        // Ensure all values in the dictionary are valid JSON types
        guard JSONSerialization.isValidJSONObject(payloadDict) else {
            print("Invalid JSON payload: \(payloadDict)\n")
            throw FreddyError.invalidResponse // Use an appropriate error
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FreddyError.httpError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                description: "Failed to execute run"
            )
        }
        
        return try JSONDecoder().decode([ExecuteRunResponse].self, from: data)
    }
}
