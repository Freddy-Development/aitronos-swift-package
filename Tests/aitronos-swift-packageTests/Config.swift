//
//  Config.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 23.09.2024.
//

import Foundation

public struct Config: Codable {
    public let testToken: String

    public init() {
        let fileUrl = URL(fileURLWithPath: "config.json")
        do {
            let data = try Data(contentsOf: fileUrl)
            let config = try JSONDecoder().decode(Config.self, from: data)
            self.testToken = config.testToken
        } catch {
            fatalError("Failed to load config: \(error)")
        }
    }

    // If you want a specific function to return the token
    public func getTestToken() -> String {
        return testToken
    }
}
