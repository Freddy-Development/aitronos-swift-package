//
//  File.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

// MARK: - StreamEventDelegate Protocol

public protocol StreamEventDelegate: AnyObject {
    func handleStreamEvent(_ event: StreamEvent)
    func didEncounterError(_ error: Error)
}

// MARK: - FreddyApi Extension

public extension FreddyApi {
    final class AssistantMessaging: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        
        // MARK: - Custom Error Types
        
        public enum AssistantMessagingError: Error, LocalizedError {
            case unsupportedAPIVersion
            case invalidURL
            case jsonSerializationError(underlying: Error)
            case invalidResponse(statusCode: Int)
            case networkError(underlying: Error)
            case malformedDataStream
            
            public var errorDescription: String? {
                switch self {
                case .unsupportedAPIVersion:
                    return "The API version provided is unsupported."
                case .invalidURL:
                    return "The constructed URL is invalid."
                case .jsonSerializationError(let underlying):
                    return "Failed to serialize JSON payload: \(underlying.localizedDescription)"
                case .invalidResponse(let statusCode):
                    return "Received invalid HTTP response with status code: \(statusCode)"
                case .networkError(let underlying):
                    return "Network error occurred: \(underlying.localizedDescription)"
                case .malformedDataStream:
                    return "Malformed data stream detected."
                }
            }
        }
        
        // MARK: - Properties
        
        private let baseUrls: [String: String] = ["v1": "https://freddy-api.aitronos.com/v1"]
        private let userToken: String
        private let baseUrl: String
        private var session: URLSession!
        private let bufferQueue = DispatchQueue(label: "com.aitronos.bufferQueue", qos: .utility)
        private var buffer = ""  // Mutable buffer to accumulate data
        private var isCompleted = false  // Track whether stream has completed
        
        public weak var delegate: StreamEventDelegate?
        
        // MARK: - Initialization
        
        public init(userToken: String) {
            guard let url = baseUrls["v1"] else {
                fatalError("Unsupported API version")
            }
            self.userToken = userToken
            self.baseUrl = url
            super.init()
            self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        
        // MARK: - Public Methods
        
        public func createStream(payload: MessageRequestPayload, delegate: StreamEventDelegate) {
            self.delegate = delegate
            guard let url = URL(string: "\(self.baseUrl)/messages/run-stream") else {
                delegate.didEncounterError(AssistantMessagingError.invalidURL)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payloadDict = payload.toDict()
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
                request.httpBody = jsonData
            } catch {
                delegate.didEncounterError(AssistantMessagingError.jsonSerializationError(underlying: error))
                return
            }
            
            let task = session.dataTask(with: request)
            task.resume()
        }
        
        // MARK: - URLSessionDataDelegate
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let chunk = String(data: data, encoding: .utf8) else {
                // Non-critical error: Unable to decode data chunk
                // Optionally log this error
                print("Received data chunk could not be decoded to UTF-8 string.")
                return
            }
            
            bufferQueue.async { [weak self] in
                guard let self = self else { return }
                self.buffer += chunk
                self.processBuffer { event in
                    if let event = event {
                        DispatchQueue.main.async {
                            self.delegate?.handleStreamEvent(event)
                        }
                    }
                }
            }
        }
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if isCompleted { return }
            isCompleted = true
            
            if let error = error {
                // Critical error: Network issue or request failure
                DispatchQueue.main.async {
                    self.delegate?.didEncounterError(AssistantMessagingError.networkError(underlying: error))
                }
            } else {
                // Validate HTTP response
                if let httpResponse = task.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let responseError = AssistantMessagingError.invalidResponse(statusCode: httpResponse.statusCode)
                    DispatchQueue.main.async {
                        self.delegate?.didEncounterError(responseError)
                    }
                }
                
                // Force process any remaining buffer when stream completes
                bufferQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.processBuffer(forceProcess: true) { event in
                        if let event = event {
                            DispatchQueue.main.async {
                                self.delegate?.handleStreamEvent(event)
                            }
                        }
                    }
                }
                
                print("Stream completed successfully")
            }
        }
        
        // MARK: - Private Methods
        
        /// Processes the buffer to extract complete JSON objects.
        /// - Parameters:
        ///   - forceProcess: Whether to force processing the remaining buffer regardless of brace balance.
        ///   - callback: A closure to handle the extracted `StreamEvent`.
        private func processBuffer(forceProcess: Bool = false, callback: @escaping (StreamEvent?) -> Void) {
            // Process on bufferQueue to ensure thread safety
            bufferQueue.async { [weak self] in
                guard let self = self else { return }
                var braceCount = 0
                var insideString = false
                var escapeCharacter = false
                var startIndex: String.Index? = nil
                var rangesToRemove = [Range<String.Index>]()  // Track ranges to remove later
                
                for currentIndex in self.buffer.indices {
                    let char = self.buffer[currentIndex]
                    
                    if escapeCharacter {
                        escapeCharacter = false
                        continue
                    }
                    
                    if char == "\\" {
                        escapeCharacter = true
                        continue
                    }
                    
                    if char == "\"" {
                        insideString.toggle()
                        continue
                    }
                    
                    if !insideString {
                        if char == "{" {
                            braceCount += 1
                            if startIndex == nil {
                                startIndex = currentIndex
                            }
                        } else if char == "}" {
                            braceCount -= 1
                            if braceCount < 0 {
                                // Unbalanced braces detected
                                print("Unbalanced braces detected!")
                                braceCount = 0
                                startIndex = nil
                                self.delegate?.didEncounterError(AssistantMessagingError.malformedDataStream)
                                break
                            }
                        }
                    }
                    
                    // Process complete JSON objects or force process remaining buffer on stream completion
                    if braceCount == 0, let start = startIndex {
                        let jsonStr = String(self.buffer[start...currentIndex])
                        
                        if let jsonData = jsonStr.data(using: .utf8) {
                            do {
                                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let event = StreamEvent.fromJson(jsonDict) {
                                    callback(event)
                                } else {
                                    // Non-critical error: Unable to parse individual event
                                    print("Invalid StreamEvent data: \(jsonStr)")
                                }
                            } catch {
                                // Non-critical error: JSON parsing failed for individual event
                                print("Failed to parse JSON: \(error.localizedDescription). JSON String: \(jsonStr)")
                            }
                        }
                        
                        // Track the range of the buffer that was processed to remove it later
                        let endIndex = self.buffer.index(after: currentIndex)
                        rangesToRemove.append(start..<endIndex)
                        startIndex = nil
                    }
                }
                
                // Force process buffer if stream has completed
                if forceProcess, let start = startIndex {
                    let jsonStr = String(self.buffer[start...])
                    if !jsonStr.isEmpty {
                        if let jsonData = jsonStr.data(using: .utf8) {
                            do {
                                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let event = StreamEvent.fromJson(jsonDict) {
                                    callback(event)
                                } else {
                                    // Non-critical error: Unable to parse individual event
                                    print("Invalid StreamEvent data during forced processing: \(jsonStr)")
                                }
                            } catch {
                                // Non-critical error: JSON parsing failed for individual event
                                print("Failed to parse JSON during forced processing: \(error.localizedDescription). JSON String: \(jsonStr)")
                            }
                        }
                    }
                    self.buffer.removeAll()
                }
                
                // Remove all processed ranges from the buffer after the loop
                for range in rangesToRemove.reversed() {
                    self.buffer.removeSubrange(range)
                }
                
                // Handle unbalanced braces if not forcing processing
                if braceCount != 0 && !forceProcess && startIndex != nil {
                    // Malformed data stream
                    self.delegate?.didEncounterError(AssistantMessagingError.malformedDataStream)
                    self.buffer.removeAll()
                }
            }
        }
    }
}
