// The Swift Programming Language
// https://docs.swift.org/swift-book

//
//  aitronos_swift_package.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 24.09.2024.
//

import Foundation

public class Aitronos: @unchecked Sendable {
    public var appHive: AppHive {
        AppHive(userToken: userToken)
    }
    public var freddyApi: FreddyApi {
        FreddyApi(userToken: userToken)
    }
    public var assistantMessaging: FreddyApi.AssistantMessaging {
        FreddyApi.AssistantMessaging(userToken: userToken)
    }
    public private(set) var userToken = ""

    // MARK: - Async Init for macOS 10.15 and iOS 13+
    @available(macOS 10.15, iOS 13, *)
    public init(username: String? = nil, password: String? = nil, apiKey: String? = nil) async throws {
        guard (username != nil && password != nil) || apiKey != nil else {
            throw LoginError.missingCredentials
        }

        if let apiKey = apiKey {
            self.userToken = apiKey
        } else if let username = username, let password = password {
            let response = try await Aitronos.login(username: username, password: password)
            self.userToken = response.token
        }
    }

    // MARK: - Synchronous Init for older versions
    public init(
        username: String? = nil,
        password: String? = nil,
        apiKey: String? = nil,
        completion: @Sendable @escaping (Result<Void, Error>) -> Void
    ) {
        guard (username != nil && password != nil) || apiKey != nil else {
            completion(.failure(LoginError.missingCredentials))
            return
        }

        if let apiKey = apiKey {
            self.userToken = apiKey
            completion(.success(()))
        } else if let username = username, let password = password {
            AppHive.login(usernmeEmail: username, password: password) { [weak self] result in
                guard let self = self else {
                    completion(.failure(LoginError.missingCredentials))
                    return
                }
                switch result {
                case .success(let response):
                    self.userToken = response.token
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Login Helper Function (Async)
    @available(macOS 10.15, iOS 13, *)
    private static func login(username: String, password: String) async throws -> AppHive.LoginResponse {
        try await withCheckedThrowingContinuation { continuation in
            AppHive.login(usernmeEmail: username, password: password) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Error Handling
    public enum LoginError: Error {
        case missingCredentials
        case loginFailed(FreddyError)
    }
}
