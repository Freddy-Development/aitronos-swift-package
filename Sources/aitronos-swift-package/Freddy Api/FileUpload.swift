//
//  FileUpload.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    struct FileUploadResponse: Decodable {
        let fileId: String
    }
    
    /// Upload a file to the vector store
    /// - Parameters:
    ///   - organizationId: The organization ID where the file is uploaded
    ///   - fileURL: The local file URL of the binary content to upload
    ///   - purpose: The purpose of the file upload (must match predefined values like 'fine-tune', 'assistants', 'batch', etc.)
    ///   - fileName: The desired name for the file after it is uploaded
    ///   - token: Bearer token for authentication
    ///   - closure: Completion handler with success or failure response
    func uploadFile(
        organizationId: String,
        fileURL: URL,
        purpose: String,
        fileName: String,
        token: String,
        closure: @Sendable @escaping (Result<FileUploadResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/v1/organizations/\(organizationId)/file/upload"
        
        // 2. Create boundary for multipart/form-data
        let boundary = UUID().uuidString
        
        // 3. Construct the multipart form body
        var body = Data()
        
        // 3a. Add file content
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } else {
            DispatchQueue.main.async {
                closure(.failure(.networkIssue(description: "Failed to read file data")))
            }
            return
        }
        
        // 3b. Add purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(purpose)\r\n".data(using: .utf8)!)
        
        // 3c. Add fileName field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"fileName\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileName)\r\n".data(using: .utf8)!)
        
        // 3d. End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 4. Create request configuration
        let config = Config(baseURL: "https://freddy-core-api.azurewebsites.net", backendKey: token)
        
        // 5. Create a custom request and add multipart headers
        var request = URLRequest(url: URL(string: config.baseURL + endpoint)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        
        // 6. Perform the request using the helper function
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: body,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<FileUploadResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response))
                } else {
                    closure(.failure(.noData))
                }
                
            case .failure(let error):
                closure(.failure(error))
            }
        }
    }
}
