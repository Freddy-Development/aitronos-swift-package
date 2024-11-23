//
//  RunStream.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation
public protocol StreamEventDelegate: AnyObject {
    func handleStreamEvent(_ event: StreamEvent)
    func didEncounterError(_ error: Error)
}
extension FreddyApi {
    public final class AssistantMessaging: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        public var userToken: String
        private var session: URLSession!
        private let bufferQueue = DispatchQueue(label: "com.aitronos.bufferQueue", qos: .utility)
        private var buffer = ""  // Mutable buffer to accumulate data
        private var isCompleted = false  // Track whether stream has completed
        public let baseUrl: String
        
        public weak var delegate: StreamEventDelegate?
        public init(userToken: String, baseUrl: String) {
            self.userToken = userToken
            self.baseUrl = baseUrl
            super.init()
            self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        
        public func createStream(payload: MessageRequestPayload, delegate: StreamEventDelegate) {
            self.delegate = delegate
            let url = URL(string: "\(self.baseUrl)/messages/run-stream")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payloadDict = payload.toDict()
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
                request.httpBody = jsonData
            } catch {
                delegate.didEncounterError(error)
                return
            }
            let task = session.dataTask(with: request)
            task.resume()
        }
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            if let chunk = String(data: data, encoding: .utf8) {
                bufferQueue.async {
                    self.buffer += chunk
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
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if isCompleted { return }
            isCompleted = true
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.didEncounterError(error)
                }
            } else {
                // Force process any remaining buffer when stream completes
                bufferQueue.async {
                    self.processBuffer(forceProcess: true) { [weak self] event in
                        guard let self = self else { return }
                        if let event = event {
                            DispatchQueue.main.async {
                                self.delegate?.handleStreamEvent(event)
                            }
                        }
                    }
                }
                //print("Stream completed successfully")
            }
        }
        // Process buffer to extract complete JSON objects
        private func processBuffer(forceProcess: Bool = false, callback: @Sendable @escaping (StreamEvent?) -> Void) {
            bufferQueue.async {
                var braceCount = 0
                var startIndex: String.Index? = nil  // Declare `startIndex` as an optional `String.Index`
                var rangesToRemove = [Range<String.Index>]()  // Track ranges to remove later
                // Iterate over the string indices and characters
                for currentIndex in self.buffer.indices {
                    let char = self.buffer[currentIndex]
                    // Increment brace count on opening brace '{'
                    if char == "{" {
                        braceCount += 1
                        if startIndex == nil {
                            startIndex = currentIndex
                        }
                    }
                    // Decrement brace count on closing brace '}'
                    else if char == "}" {
                        braceCount -= 1
                        if braceCount < 0 {
                            //print("Unbalanced braces detected!")
                            braceCount = 0
                            startIndex = nil
                            continue
                        }
                    }
                    // Process complete JSON objects or force process remaining buffer on stream completion
                    if braceCount == 0, let startIndexUnwrapped = startIndex {
                        let jsonStr = String(self.buffer[startIndexUnwrapped...currentIndex])
                        if let jsonData = jsonStr.data(using: .utf8) {
                            do {
                                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let event = StreamEvent.fromJson(jsonDict) {
                                    callback(event)
                                } else {
                                    //print("Invalid StreamEvent data")
                                }
                            } catch {
                                //print("Failed to parse JSON: \(error)")
                                DispatchQueue.main.async {
                                    self.delegate?.didEncounterError(error)
                                }
                            }
                        }
                        // Track the range of the buffer that was processed to remove it later
                        let endIndex = self.buffer.index(after: currentIndex)
                        rangesToRemove.append(startIndexUnwrapped..<endIndex)
                        startIndex = nil
                    }
                }
                // Force process buffer if braces are unbalanced and stream has completed
                if forceProcess, let startIndexUnwrapped = startIndex {
                    //print("Force processing remaining buffer after stream completion")
                    let jsonStr = String(self.buffer[startIndexUnwrapped...])
                    if let jsonData = jsonStr.data(using: .utf8) {
                        do {
                            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let event = StreamEvent.fromJson(jsonDict) {
                                callback(event)
                            } else {
                                //print("Invalid StreamEvent data during forced processing")
                            }
                        } catch {
                            //print("Failed to parse JSON in forced buffer processing: \(error)")
                            DispatchQueue.main.async {
                                self.delegate?.didEncounterError(error)
                            }
                        }
                    }
                    self.buffer.removeAll()  // Clear buffer after final processing
                }
                // Remove all processed ranges from the buffer after the loop
                for range in rangesToRemove.reversed() {
                    self.buffer.removeSubrange(range)
                }
                // Log an error if there are unbalanced braces left after processing
                if braceCount != 0 && !forceProcess {
                    //print("Warning: Unbalanced braces at the end of buffer processing.")
                }
            }
        }
    }
}
