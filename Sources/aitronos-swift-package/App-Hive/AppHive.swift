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
    public init (userToken: String) {
        self.userToken = userToken
    }
}
