//  Authentication.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation
import CoreLocation

public extension AppHive {
    
    // MARK: - LoginResponse Struct
    /// Represents the response received after a successful login.
    struct LoginResponse: Decodable, Sendable {
        public let token: String
        public let refreshToken: RefreshToken
        public let deviceId: String
        
        // RefreshToken Struct inside LoginResponse
        public struct RefreshToken: Decodable, Sendable {
            public let token: String
            public let expiry: String
        }
    }
    
    // MARK: - LoginError Struct
    /// Represents an error received during the login process.
    struct LoginError: Decodable, Error, Sendable {
        public let message: String
    }
    
    // MARK: - DeviceInformation Struct
    /// Represents device information for login verification
    struct DeviceInformation: Codable, Sendable {
        public let device: String
        public let location: String
        public let latitude: String
        public let longitude: String
        public let deviceId: String
        public let operatingSystem: String
        public let platform: String

        public init(device: String, location: String, latitude: String, longitude: String, deviceId: String, operatingSystem: String, platform: String) {
            self.device = device
            self.location = location
            self.latitude = latitude
            self.longitude = longitude
            self.deviceId = deviceId
            self.operatingSystem = operatingSystem
            self.platform = platform
        }
        
        enum CodingKeys: String, CodingKey {
            case device
            case location
            case latitude
            case longitude
            case deviceId = "deviceId"
            case operatingSystem = "operatingSystem"
            case platform
        }
        
        /// Gathers device information automatically
        public static func gatherDeviceInformation() -> DeviceInformation {
            let device = getDeviceType()
            let location = "Unknown" // Default location
            let (latitude, longitude) = getLocation()
            let deviceId = UUID().uuidString
            let operatingSystem = getOperatingSystem()
            let platform = getPlatform()
            
            return DeviceInformation(
                device: device,
                location: location,
                latitude: latitude ?? "0",
                longitude: longitude ?? "0",
                deviceId: deviceId,
                operatingSystem: operatingSystem,
                platform: platform
            )
        }
        
        private static func getDeviceType() -> String {
            #if targetEnvironment(macCatalyst)
                return "Mac"
            #else
                return "Mobile"
            #endif
        }
        
        private static func getOperatingSystem() -> String {
            #if os(macOS)
                return "macOS"
            #elseif os(iOS)
                return "iOS"
            #elseif os(tvOS)
                return "tvOS"
            #elseif os(watchOS)
                return "watchOS"
            #else
                return "Unknown"
            #endif
        }
        
        private static func getPlatform() -> String {
            #if os(macOS)
                return "macOS"
            #elseif os(iOS)
                return "iOS"
            #elseif os(tvOS)
                return "tvOS"
            #elseif os(watchOS)
                return "watchOS"
            #else
                return "Unknown"
            #endif
        }
        
        private static func getLocation() -> (String?, String?) {
            #if os(iOS) || os(macOS)
                if #available(macOS 10.15, iOS 13.0, *) {
                    let locationManager = CLLocationManager()
                    locationManager.requestWhenInUseAuthorization()
                    
                    if CLLocationManager.locationServicesEnabled() {
                        if let location = locationManager.location {
                            let latitude = String(location.coordinate.latitude)
                            let longitude = String(location.coordinate.longitude)
                            return (latitude, longitude)
                        }
                    }
                }
            #endif
            return (nil, nil)
        }
    }
    
    // MARK: - LoginRequest Struct
    /// Represents the login request body
    struct LoginRequest: Codable, Sendable {
        public let emailorusername: String
        public let password: String
        public let deviceInformation: DeviceInformation
    }
    
    // MARK: - Login Function
    /// Authenticates a user with their email or username and password.
    ///
    /// - Parameters:
    ///   - usernmeEmail: The username or email of the user attempting to log in.
    ///   - password: The user's password.
    ///   - closure: A closure that returns a `Result` containing either the `LoginResponse` on success or a `FreddyError` on failure.
    static func login(
        usernmeEmail: String,
        password: String,
        closure: @Sendable @escaping (Result<LoginResponse, FreddyError>) -> Void
    ) {
        // 1. API Endpoint
        let endpoint = "/auth/login"
        
        // 2. Gather device information automatically
        let deviceInformation = DeviceInformation.gatherDeviceInformation()
        
        // 3. Create request body
        let requestBody = LoginRequest(
            emailorusername: usernmeEmail,
            password: password,
            deviceInformation: deviceInformation
        )
        
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            closure(.failure(.invalidData(description: "Failed to serialize request body")))
            return
        }
        
        // 4. Config without authorization (since this is the login endpoint)
        let config = Config(baseUrl: baseUrl, backendKey: "")
        
        // 5. Perform the request using the helper function `performRequest`
        performRequest(
            endpoint: endpoint,
            method: .post,
            config: config,
            body: bodyData,
            emptyResponse: false,
            decoder: JSONDecoder()
        ) { (result: Result<LoginResponse?, FreddyError>) in
            switch result {
            case .success(let response):
                if let response = response {
                    closure(.success(response))
                } else {
                    closure(.failure(.noData))
                }
            case .failure(let error):
                if case let .httpError(statusCode, description) = error {
                    switch statusCode {
                    case 404:
                        if description.contains("User name not found") {
                            closure(.failure(.resourceNotFound(resource: "User name not found")))
                        } else {
                            closure(.failure(.resourceNotFound(resource: description)))
                        }
                    case 401:
                        if description.contains("Incorrect password") {
                            closure(.failure(.invalidCredentials(details: "Incorrect password")))
                        } else {
                            closure(.failure(.unauthorized(reason: description)))
                        }
                    case 403:
                        closure(.failure(.forbidden(reason: description)))
                    default:
                        closure(.failure(FreddyError.fromHTTPStatus(statusCode, description: description)))
                    }
                } else {
                    closure(.failure(error))
                }
            }
        }
    }
}

extension AppHive {
    @available(macOS 10.15, *)
    static func login(
        usernmeEmail: String,
        password: String
    ) async throws -> LoginResponse {
        try await withCheckedThrowingContinuation { continuation in
            login(
                usernmeEmail: usernmeEmail,
                password: password
            ) { result in
                switch result {
                case .success(let loginResponse):
                    continuation.resume(returning: loginResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
