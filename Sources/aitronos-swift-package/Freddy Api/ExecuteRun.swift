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
        var updatedPayload = payload
        updatedPayload.stream = false
        
        let payloadDict = updatedPayload.toDict()
        // Log and validate the payload
        //print("Payload dictionary before validation: \(payloadDict)")
        guard JSONSerialization.isValidJSONObject(payloadDict) else {
            throw FreddyError.invalidResponse(description: "Invalid JSON payload format")
        }

        // Serialize the payload
        request.httpBody = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
        
        // Make the API call
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FreddyError.httpError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                description: "Failed to execute run"
            )
        }

        // Decode the response
        do {
            return try JSONDecoder().decode([ExecuteRunResponse].self, from: data)
        } catch {
            throw FreddyError.decodingError(
                description: error.localizedDescription,
                originalError: error
            )
        }
    }
}
