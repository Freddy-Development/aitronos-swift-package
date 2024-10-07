// The Swift Programming Language
// https://docs.swift.org/swift-book

//
//  aitronos_swift_package.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 24.09.2024.
//

import Foundation

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
    private var buffer = ""  // Mutable buffer to accumulate data
    private var isCompleted = false  // Track whether stream has completed
    
    public weak var delegate: StreamEventDelegate?

    public init(token: String) {
        guard let url = baseUrls["v1"] else {
            fatalError("Unsupported API version")
        }
        self.token = token
        self.baseUrl = url
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public func createStream(payload: MessageRequestPayload, delegate: StreamEventDelegate) {
        self.delegate = delegate
        let url = URL(string: "\(self.baseUrl)/messages/run-stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
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
            print("Stream completed successfully")
        }
    }

    // Process buffer to extract complete JSON objects
    private func processBuffer(callback: @Sendable @escaping (StreamEvent?) -> Void) {
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
                    // If it's the first opening brace, mark the startIndex
                    if startIndex == nil {
                        startIndex = currentIndex
                    }
                }
                // Decrement brace count on closing brace '}'
                else if char == "}" {
                    braceCount -= 1
                    // Ensure the braceCount doesn't become negative
                    if braceCount < 0 {
                        print("Unbalanced braces detected!")
                        braceCount = 0
                        startIndex = nil
                        continue
                    }
                }

                // When braceCount is 0, it means a complete JSON object is found
                if braceCount == 0, let startIndexUnwrapped = startIndex {
                    let jsonStr = String(self.buffer[startIndexUnwrapped...currentIndex])

                    // Process the JSON string
                    if let jsonData = jsonStr.data(using: .utf8) {
                        do {
                            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let event = StreamEvent.fromJson(jsonDict) {
                                callback(event)
                            } else {
                                print("Invalid StreamEvent data")
                            }
                        } catch {
                            print("Failed to parse JSON: \(error)")
                            DispatchQueue.main.async {
                                self.delegate?.didEncounterError(error)
                            }
                        }
                    }

                    // Track the range of the buffer that was processed to remove it later
                    let endIndex = self.buffer.index(after: currentIndex)  // Move past the currentIndex for an open-ended range
                    rangesToRemove.append(startIndexUnwrapped..<endIndex)  // Use `..<` for a Range
                    startIndex = nil  // Reset startIndex for the next object
                }
            }

            // Remove all processed ranges from the buffer after the loop
            for range in rangesToRemove.reversed() {
                self.buffer.removeSubrange(range)
            }

            // Log an error if there are unbalanced braces left after processing
            if braceCount != 0 {
                print("Warning: Unbalanced braces at the end of buffer processing.")
            }
        }
    }
}
