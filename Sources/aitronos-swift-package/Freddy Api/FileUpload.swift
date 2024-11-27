//
//  FileUpload.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public enum FileUploadPurpose: String, Codable {
    case assistants = "assistants"
    case vision = "vision"
    case batch = "batch"
    case fineTune = "fine-tune"

    public var description: String {
        switch self {
        case .assistants:
            return "Assistants and Message files"
        case .vision:
            return "Assistants image file inputs"
        case .batch:
            return "Batch API"
        case .fineTune:
            return "Fine-tuning"
        }
    }
}

public struct FileUploadResponse: Codable {
    public let fileId: Int?
    public let success: Bool?
    public let message: String?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try container.decodeIfPresent(Int.self, forKey: .fileId)
        success = fileId != nil
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? "No message provided"
    }
}

public extension FreddyApi {
    func uploadFile(
        organizationId: Int,
        fileData: Data,
        fileName: String,
        purpose: FileUploadPurpose
    ) async throws -> FileUploadResponse {
        let url = URL(string: "\(baseUrl)/organizations/\(organizationId)/file/upload")!
        
        // Boundary for multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the multipart form data
        let bodyData = createMultipartFormData(
            fileData: fileData,
            fileName: fileName,
            purpose: purpose.rawValue,
            boundary: boundary
        )
        
        // Debugging: Print the payload
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            print("[DEBUG] Multipart Payload:\n\(bodyString)")
        } else {
            print("[DEBUG] Failed to encode body data to String.")
        }
        
        request.httpBody = bodyData

        // Debugging: Print headers
        print("[DEBUG] Request Headers:")
        for (header, value) in request.allHTTPHeaderFields ?? [:] {
            print("\(header): \(value)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debugging: Print HTTP response details
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] Response Status Code: \(httpResponse.statusCode)")
                print("[DEBUG] Response Headers: \(httpResponse.allHeaderFields)")
            } else {
                print("[DEBUG] Response is not an HTTPURLResponse.")
            }
            
            // Debugging: Print raw response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Response Body:\n\(responseString)")
            } else {
                print("[DEBUG] Failed to decode response data to String.")
            }
            
            // Check for successful HTTP response
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "FileUploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            // Decode the response into FileUploadResponse
            let decodedResponse = try JSONDecoder().decode(FileUploadResponse.self, from: data)
            print("[DEBUG] Decoded Response: \(decodedResponse)")
            return decodedResponse
        } catch {
            // Debugging: Print error
            print("[DEBUG] File upload failed with error: \(error.localizedDescription)")
            throw error
        }
    }

    private func createMultipartFormData(
        fileData: Data,
        fileName: String,
        purpose: String,
        boundary: String
    ) -> Data {
        var body = Data()
        
        // Add Purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(purpose)\r\n".data(using: .utf8)!)
        
        // Add FileName field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"FileName\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileName)\r\n".data(using: .utf8)!)
        
        // Add File field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"File\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Debugging: Print generated body data
        print("[DEBUG] Generated Multipart Data Size: \(body.count) bytes")
        
        return body
    }
}
