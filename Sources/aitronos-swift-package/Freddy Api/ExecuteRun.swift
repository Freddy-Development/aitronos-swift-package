//
//  ExecuteRun.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

extension FreddyApi {
    /// Executes a non-streaming run request.
    /// - Parameter payload: The payload for the run request.
    /// - Returns: A dictionary containing the response, or `nil` if there is no data.
    /// - Throws: A `FreddyError` if the request fails or the response cannot be decoded.
    @available(macOS 12.0, *)
    public func executeRun(payload: MessageRequestPayload) async throws -> [String: Any]? {
        let url = URL(string: "\(self.baseUrl)/messages/run-stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add "stream": false to the payload
        var payloadDict = payload.toDict()
        payloadDict["stream"] = false
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FreddyError.httpError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                description: "Failed to execute run"
            )
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
