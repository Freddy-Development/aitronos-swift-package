//
//  RunStatus.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

/// Represents the response structure for the `checkRunStatus` endpoint.
public struct RunStatusResponse: Decodable, Sendable {
    public let runStatus: String
}

extension FreddyApi {
    @available(macOS 12.0, *)
    func checkRunStatus(
        runKey: String,
        threadKey: String,
        organizationId: Int
    ) async throws -> String {
        let urlString = "\(self.baseUrl)/messages/run-status"
        guard let url = URL(string: urlString) else {
            throw FreddyError.invalidURL(url: urlString)
        }

        let payload: [String: Any] = [
            "organization_id": organizationId,
            "thread_key": threadKey,
            "run_key": runKey
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: FreddyError.from(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: FreddyError.invalidResponse(description: "Unknown response type"))
                    return
                }

                if !(200...299).contains(httpResponse.statusCode) {
                    let errorDescription = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: FreddyError.fromHTTPStatus(httpResponse.statusCode, description: errorDescription))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: FreddyError.noData)
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(RunStatusResponse.self, from: data)
                    continuation.resume(returning: decodedResponse.runStatus)
                } catch {
                    continuation.resume(throwing: FreddyError.decodingError(
                        description: error.localizedDescription,
                        originalError: error
                    ))
                }
            }
            task.resume()
        }
    }
}
