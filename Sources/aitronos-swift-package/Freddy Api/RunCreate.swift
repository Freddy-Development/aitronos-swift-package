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
            throw FreddyError.invalidURL(url: "\(self.baseUrl)/messages/run-create")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payloadDict = payload.toDict()
        print("Debug - Full payload dictionary: \(payloadDict)")
        
        let jsonData = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
        request.httpBody = jsonData
        
        // Debug - Print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Debug - JSON being sent: \(jsonString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FreddyError.invalidResponse(description: "Unknown response type")
            }
            
            // Debug - Print response information
            print("Debug - Response status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Debug - Response body: \(responseString)")
            }
            
            // Try to parse error data if status code is not 200
            if httpResponse.statusCode != 200 {
                // Try to parse error message from response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Debug - Error response: \(errorDict)")
                    if let errorMessage = errorDict["error"] as? String {
                        throw self.parseFreddyError(from: data, statusCode: httpResponse.statusCode)
                    }
                }
                // If no error message found, throw generic error
                throw FreddyError.fromHTTPStatus(httpResponse.statusCode)
            }
            
            // Try to decode successful response
            do {
                return try JSONDecoder().decode(RunCreateResponse.self, from: data)
            } catch {
                print("Debug - Decoding error: \(error)")
                throw FreddyError.decodingError(
                    description: error.localizedDescription,
                    originalError: error
                )
            }
        } catch let error as FreddyError {
            throw error
        } catch {
            print("Debug - Network error: \(error)")
            throw FreddyError.from(error)
        }
    }
}
