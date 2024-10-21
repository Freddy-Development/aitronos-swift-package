//
//  FreddyApi.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

public class FreddyApi {
    private let baseURL = "https://freddy-api.aitronos.com"
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
