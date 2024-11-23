//
//  CreateThreadName.swift
//  aitronos
//
//  Created by Phillip Loacker on 19.11.2024.
//

import Foundation

public extension FreddyApi {
    /// Generates a chat title based on the last few messages.
    /// - Parameters:
    ///   - messages: An array of messages to analyze for title generation.
    ///   - maxMessages: The maximum number of recent messages to consider.
    /// - Returns: A string representing the generated chat title.
    @available(macOS 12.0, *)
    func generateChatTitle(from messages: [String], maxMessages: Int = 3) async -> String {
        // Limit the messages to the specified maximum number
        let recentMessages = Array(messages.suffix(maxMessages))
        
        // Join the messages for processing
        let combinedText = recentMessages.joined(separator: ", ")
        
        let payload = MessageRequestPayload(
            organizationId: 1,
            assistantId: 1,
            model: .ftg15Basic,
            messages: [
                .init(content: "You need to generate a meaningful title for the newly created chat thread, based on the initial message sent by the user. Please restrict the title length to a maximum of 3 or 4 words only.", role: .assistant),
                .init(content: "Please create a meaningful title for a chat thread here are the messages: \n" + combinedText, role: .user)
            ]
        )
        
        do {
            if let result = try await executeRun(payload: payload),
               let title = result.first?.response {
                return title
            } else {
                throw FreddyError.noData // Throw if no title is returned
            }
        } catch {
            //print("Error generating chat title: \(error)")
            return "Untitled Chat" // Default title in case of error
        }
    }
    
    /// Creates a thread name based on recent messages.
    /// - Parameters:
    ///   - messages: An array of message strings.
    ///   - maxMessages: The maximum number of recent messages to consider.
    /// - Returns: A thread name string.
    @available(macOS 12.0, *)
    func createThreadName(messages: [String], maxMessages: Int = 3) async -> String {
        return await generateChatTitle(from: messages, maxMessages: maxMessages)
    }
}
