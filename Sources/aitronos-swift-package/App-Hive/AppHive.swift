//
//  AppHive.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

public final class AppHive {
    public static var baseUrl: String { "https://freddy-api.aitronos.com" }
    
    public var baseUrl: String { "https://freddy-api.aitronos.com" }
    public var userToken: String {
        didSet {
            if userToken.isEmpty {
                fatalError("AppHive API Key cannot be empty")
            }
        }
    }
    
    public init(userToken: String) {
        self.userToken = userToken
    }
    
    // MARK: - HTTP Methods
    public static func performRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        config: Config,
        body: Data? = nil,
        emptyResponse: Bool = false,
        decoder: JSONDecoder = JSONDecoder(),
        completion: @Sendable @escaping (Result<T?, FreddyError>) -> Void
    ) {
        // Capture values before async block to prevent data races
        let fullUrl = config.baseUrl + endpoint
        let authToken = config.backendKey
        
        // 1. Construct the URL
        guard let url = URL(string: fullUrl) else {
            DispatchQueue.main.async {
                completion(.failure(.invalidURL(url: fullUrl)))
            }
            return
        }
        
        // 2. Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        if let body = body, [.post, .put].contains(method) {
            request.httpBody = body
        }
        
        // 3. Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // 4. Handle network errors
                if let error = error {
                    completion(.failure(FreddyError.from(error)))
                    return
                }
                
                // 5. Validate the response and status code
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse(description: "Unknown response type")))
                    return
                }
                
                // 6. Handle non-successful HTTP status codes
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let data = data {
                        // Try to extract error details from response
                        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                           let dictionary = jsonObject as? [String: Any],
                           let errorMessage = dictionary["message"] as? String {
                            if httpResponse.statusCode == 404 {
                                completion(.failure(.resourceNotFound(resource: errorMessage)))
                            } else if httpResponse.statusCode == 401 {
                                completion(.failure(.invalidCredentials(details: errorMessage)))
                            } else {
                                completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode, description: errorMessage)))
                            }
                        } else {
                            completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode)))
                        }
                    } else {
                        completion(.failure(.noData))
                    }
                    return
                }
                
                // 7. Handle empty responses
                if emptyResponse {
                    completion(.success(nil))
                    return
                }
                
                // 8. Ensure there is data to decode
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                // 9. Attempt to decode the response
                do {
                    let decodedResponse = try decoder.decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(.decodingError(description: error.localizedDescription, originalError: error)))
                }
            }
        }
        task.resume()
    }
}
