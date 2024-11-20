//
//  RunStatus.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation
//import Alamofire

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
//        let url = "\(self.baseUrl)/messages/run-status"
//        
//        // Use [String: String] to conform to Sendable
//        let parameters: [String: String] = [
//            "organization_id": "\(organizationId)",
//            "thread_key": threadKey,
//            "run_key": runKey
//        ]
//        
//        // Use async/await compatible API with Alamofire
//        return try await withCheckedThrowingContinuation { continuation in
//            AF.request(
//                url,
//                method: .post, // Change to .post if required
//                parameters: parameters,
//                encoder: JSONParameterEncoder.default, // Use JSON encoding for body
//                headers: ["Authorization": "Bearer \(self.userToken)"]
//            )
//            .responseDecodable(of: RunStatusResponse.self) { response in
//                switch response.result {
//                case .success(let runStatusResponse):
//                    continuation.resume(returning: runStatusResponse.runStatus)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
        return ""
    }
}
