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
    public var userToken = ""

    public init(username: String? = nil, password: String? = nil, apiKey: String? = nil) {
        // Ensure either both username and password are provided or an API key is provided
        guard (username != nil && password != nil) || apiKey != nil else {
            fatalError("You must provide either both username and password or an API key")
        }

        if let apiKey = apiKey {
            // Use provided API key
            userToken = apiKey
        } else if let username = username, let password = password {
            // If no API key, login using username and password
            AppHive.login(usernmeEmail: username, password: password) { [weak self] result in
                guard let strongSelf = self else {
                    print("Aitronos instance was deallocated")
                    return
                }
                switch result {
                case .success(let response):
                    // Store the token on success
                    strongSelf.userToken = response.token
                    print("Successfully logged in. API Key: \(strongSelf.userToken)")
                    
                case .failure(let error):
                    // Handle login failure
                    print("Failed to login to AppHive: \(error)")
                    fatalError("Failed to login to AppHive with provided credentials.")
                }
            }
        }
    }
}

