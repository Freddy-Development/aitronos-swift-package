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
            // Parsing buffer for complete JSON objects
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

                    // Check if the JSON is complete by counting opening and closing brackets
                    let openBracketsCount = self.buffer.filter { $0 == "[" }.count
                    let closeBracketsCount = self.buffer.filter { $0 == "]" }.count

                    // Parse only if the number of opening and closing brackets match
                    if openBracketsCount == closeBracketsCount {
                        if let validJsonData = self.buffer.data(using: .utf8) {
                            do {
                                // Parse the accumulated JSON array
                                if let jsonArray = try JSONSerialization.jsonObject(with: validJsonData) as? [[String: Any]] {
                                    print("Parsed JSON array: \(jsonArray)")

                                    // Process each event in the array
                                    for jsonDict in jsonArray {
                                        // Convert the matching event into a StreamEvent for all event types
                                        if let event = StreamEvent.fromJson(jsonDict) {
                                            // Call the delegate or callback with the matching event
                                            DispatchQueue.main.async {
                                                callback(event)
                                            }
                                        } else {
                                            print("Invalid StreamEvent data")
                                        }
                                    }

                                    // Clear buffer after successful parsing
                                    self.buffer = ""
                                } else {
                                    print("Received data is not a valid JSON array")
                                }
                            } catch {
                                // Print the error and call the delegate's error handler
                                print("Failed to parse JSON: \(error)")
                                DispatchQueue.main.async {
                                    self.delegate?.didEncounterError(error)
                                }
                            }
                        } else {
                            print("Failed to convert accumulated JSON buffer to Data")
                        }
                    } else {
                        print("JSON data is incomplete, waiting for more data")
                    }
                } else {
                    print("Failed to convert data to UTF-8 string")
                }
            }
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
