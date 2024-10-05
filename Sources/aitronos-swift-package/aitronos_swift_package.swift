// The Swift Programming Language
// https://docs.swift.org/swift-book

//
//  aitronos_swift_package.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 24.09.2024.
//

import Foundation

public enum FreddyApiError: Error {
    case unsupportedAPIVersion
    case invalidUrl
    case jsonSerializationFailed
}

public protocol StreamEventDelegate: AnyObject {
    func handleStreamEvent(_ event: StreamEvent)
    func didEncounterError(_ error: Error)
}

public final class FreddyApi: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let baseUrls: [String: String] = ["v1": "https://freddy-core-api.azurewebsites.net/v1"]
    private let token: String
    private let baseUrl: String
    private var session: URLSession!
    private let bufferQueue = DispatchQueue(label: "com.aitronos.bufferQueue", qos: .utility)
    private var buffer = ""  // Mutable buffer
    
    private var isCompleted = false  // Track whether stream has completed
    
    public weak var delegate: StreamEventDelegate?
    private var accumulatedResponse: String = ""

    private func concatenateResponse(_ response: String) {
        // Accumulate the response string
        accumulatedResponse += response
        print("Current accumulated response: \(accumulatedResponse)")
    }

    public init(token: String) throws {
        guard let url = baseUrls["v1"] else {
            throw FreddyApiError.unsupportedAPIVersion
        }
        self.token = token
        self.baseUrl = url
        super.init()
        
        // Configure the session with a custom configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // Timeout after 30 seconds
        config.timeoutIntervalForResource = 60.0  // Timeout after 60 seconds
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // Start the stream and process each chunk as it arrives
    public func createStream(payload: MessageRequestPayload, delegate: StreamEventDelegate) {
        self.delegate = delegate
        guard let url = URL(string: "\(self.baseUrl)/messages/run-stream") else {
            delegate.didEncounterError(FreddyApiError.invalidUrl)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payloadDict = payload.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
            request.httpBody = jsonData
        } catch {
            delegate.didEncounterError(FreddyApiError.jsonSerializationFailed)
            return
        }

        let task = session.dataTask(with: request)
        task.resume()
    }

    // URLSessionDataDelegate method to handle incoming data
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let chunk = String(data: data, encoding: .utf8) {
            bufferQueue.async {
                self.buffer += chunk

                // Process the buffer for complete JSON objects
                self.processBuffer { [weak self] event in
                    guard let self = self else { return }
                    
                    if let event = event {
                        DispatchQueue.main.async {
                            self.delegate?.handleStreamEvent(event)
                        }
                    }
                }
            }
        }
    }

    // URLSessionTaskDelegate method to handle completion
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Ensure the completion handler is called only once
        if isCompleted { return }
        isCompleted = true

        if let error = error {
            DispatchQueue.main.async {
                self.delegate?.didEncounterError(error)
            }
        } else {
            print("Stream completed successfully")
        }
    }

    // Process buffer to extract valid JSON objects from chunks
    private func processBuffer(callback: @Sendable @escaping (StreamEvent?) -> Void) {
        bufferQueue.async {
            // Append new chunk to the buffer
            while let jsonData = self.getCompleteJsonData() {
                if let rawJsonString = String(data: jsonData, encoding: .utf8) {
                    print("Raw JSON data received: \(rawJsonString)")

                    // Check if the received string is empty or just contains whitespace
                    if rawJsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("Skipping empty or whitespace-only JSON data")
                        continue
                    }

                    // Append to buffer to accumulate full JSON if necessary
                    self.buffer += rawJsonString

                    // Try to extract valid JSON objects
                    self.processBufferedEvents(callback: callback)

                    // Log buffer after processing
                    print("Buffer after processing: \(self.buffer)")
                } else {
                    print("Failed to convert data to UTF-8 string")
                }
            }
        }
    }

    private func processBufferedEvents(callback: @Sendable @escaping (StreamEvent?) -> Void) {
        // Regular expression to match JSON objects inside the buffer
        let regexPattern = "\\{[^{}]*\\}" // Matches JSON objects
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        
        // Search for JSON objects in the buffer
        let matches = regex.matches(in: self.buffer, range: NSRange(self.buffer.startIndex..., in: self.buffer))

        // Iterate over matches and process each event
        for match in matches {
            let jsonStr = (self.buffer as NSString).substring(with: match.range)

            // Convert the extracted JSON string to data
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        // Convert the matching event into a StreamEvent for all event types
                        if let event = StreamEvent.fromJson(jsonDict) {
                            // Call the delegate or callback with the matching event
                            DispatchQueue.main.async {
                                callback(event)
                            }
                        } else {
                            print("Invalid StreamEvent data")
                        }
                    } else {
                        print("Received data is not a valid JSON dictionary")
                    }
                } catch {
                    print("Failed to parse JSON object: \(error)")
                    DispatchQueue.main.async {
                        self.delegate?.didEncounterError(error)
                    }
                }
            }
        }

        // Remove processed JSON objects from the buffer
        if let lastMatch = matches.last {
            let endIndex = self.buffer.index(self.buffer.startIndex, offsetBy: lastMatch.range.upperBound)
            self.buffer = String(self.buffer[endIndex...])
        }
    }
    
    // Helper function to extract complete JSON objects from the buffer
    private func getCompleteJsonData() -> Data? {
        let openBraceCount = buffer.filter { $0 == "{" }.count
        let closeBraceCount = buffer.filter { $0 == "}" }.count

        // Check if we have complete JSON
        if openBraceCount == closeBraceCount, let jsonData = buffer.data(using: .utf8) {
            buffer = ""  // Clear buffer
            return jsonData
        }
        
        // No complete JSON yet
        return nil
    }
}
