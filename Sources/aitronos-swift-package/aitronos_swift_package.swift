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
    private var buffer = ""  // Mutable buffer
    
    private var isCompleted = false  // Track whether stream has completed
    
    // Delegate to handle stream events and errors
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

    // Start the stream and process each chunk as it arrives
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
            let regex = try! NSRegularExpression(pattern: "\\{[^{}]*\\}|\\[[^\\[\\]]*\\]", options: [])
            let matches = regex.matches(in: self.buffer, range: NSRange(self.buffer.startIndex..., in: self.buffer))

            for match in matches {
                let jsonStr = (self.buffer as NSString).substring(with: match.range)
                guard let jsonData = jsonStr.data(using: .utf8) else { continue }

                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        if let event = StreamEvent.fromJson(jsonDict) {
                            callback(event)
                        } else {
                            print("Invalid StreamEvent data")
                        }
                    }
                } catch {
                    print("Failed to parse JSON: \(error)")
                    DispatchQueue.main.async {
                        self.delegate?.didEncounterError(error)
                    }
                }
            }

            // Remove processed JSON from the buffer
            if let lastMatch = matches.last {
                let endIndex = self.buffer.index(self.buffer.startIndex, offsetBy: lastMatch.range.upperBound)
                self.buffer = String(self.buffer[endIndex...])
            }
        }
    }
}
