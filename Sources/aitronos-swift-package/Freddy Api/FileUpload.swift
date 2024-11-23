//
//  FileUpload.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public struct FileUploadResponse: Codable {
    public let success: Bool
    public let message: String
}

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

public extension FreddyApi {
    public func uploadFile(
        organizationId: Int,
        fileData: Data,
        fileName: String,
        purpose: FileUploadPurpose
    ) async throws -> FileUploadResponse {
        let url = URL(string: "\(baseUrl)/organizations/\(organizationId)/file/upload")!
        //print("Uploading file to URL: \(url.absoluteString)")

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

        // Debugging print for the request body
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            //print("Request Body: \n\(bodyString)")
        } else {
            //print("Failed to convert request body to string.")
        }

        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Debugging print for the response
            if let httpResponse = response as? HTTPURLResponse {
                //print("Response Status Code: \(httpResponse.statusCode)")
                //print("Response Headers: \(httpResponse.allHeaderFields)")
            } else {
                //print("Response is not a valid HTTPURLResponse.")
            }

            // Debugging print for the response data
            if let responseString = String(data: data, encoding: .utf8) {
                //print("Response Body: \n\(responseString)")
            } else {
                //print("Failed to convert response body to string.")
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                //print("File upload failed with status code \(statusCode). Error message: \(errorMessage)")
                throw NSError(domain: "FileUploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }

            // Decode the response
            let decodedResponse = try JSONDecoder().decode(FileUploadResponse.self, from: data)
            //print("File uploaded successfully: \(decodedResponse)")
            return decodedResponse
        } catch {
            //print("File upload failed with error: \(error.localizedDescription)")
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

        // Add purpose
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(purpose)\r\n".data(using: .utf8)!)

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"File\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        //print("Generated multipart form data with boundary: \(boundary)")
        return body
    }
}
