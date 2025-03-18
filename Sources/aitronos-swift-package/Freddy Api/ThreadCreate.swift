//
//  ThreadCreate.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

/// Represents the response structure for the `createThread` endpoint.
public struct ThreadCreateResponse: Decodable {
    public let threadKey: String
} 