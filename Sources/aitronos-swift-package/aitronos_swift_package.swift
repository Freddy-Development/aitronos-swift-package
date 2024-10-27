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

    // MARK: - Synchronous Init for older versions
    public init(apiKey: String) {
        self.userToken = apiKey
    }
}
