//
//  RunStream.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 19.10.2024.
//

import Foundation

public protocol StreamEventDelegate: AnyObject {
    func handleStreamEvent(_ event: StreamEvent)
    func didEncounterError(_ error: FreddyError)
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
            guard let url = URL(string: "\(self.baseUrl)/messages/run-stream") else {
                delegate.didEncounterError(.invalidURL(url: "\(self.baseUrl)/messages/run-stream"))
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
                delegate.didEncounterError(.decodingError(description: error.localizedDescription, originalError: error))
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
                self.delegate?.didEncounterError(FreddyError.from(error))
                return
            }
            
            if let response = task.response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    // Process remaining buffer when stream completes
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
                case 500...599:
                    DispatchQueue.main.async {
                        self.delegate?.didEncounterError(.internalError(
                            description: "HTTP \(response.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))"
                        ))
                    }
                default:
                    DispatchQueue.main.async {
                        self.delegate?.didEncounterError(.httpError(
                            statusCode: response.statusCode,
                            description: HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                        ))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didEncounterError(.invalidResponse(description: "Connection closed unexpectedly"))
                }
            }
        }
        
        private func processBuffer(forceProcess: Bool = false, callback: @Sendable @escaping (StreamEvent?) -> Void) {
            bufferQueue.async {
                var braceCount = 0
                var startIndex: String.Index? = nil
                var rangesToRemove = [Range<String.Index>]()
                
                for currentIndex in self.buffer.indices {
                    let char = self.buffer[currentIndex]
                    if char == "{" {
                        braceCount += 1
                        if startIndex == nil {
                            startIndex = currentIndex
                        }
                    } else if char == "}" {
                        braceCount -= 1
                        if braceCount < 0 {
                            braceCount = 0
                            startIndex = nil
                            continue
                        }
                    }
                    if braceCount == 0, let startIndexUnwrapped = startIndex {
                        let jsonStr = String(self.buffer[startIndexUnwrapped...currentIndex])
                        if let jsonData = jsonStr.data(using: .utf8) {
                            do {
                                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let event = StreamEvent.fromJson(jsonDict) {
                                    callback(event)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.delegate?.didEncounterError(.decodingError(description: error.localizedDescription, originalError: error))
                                }
                            }
                        }
                        let endIndex = self.buffer.index(after: currentIndex)
                        rangesToRemove.append(startIndexUnwrapped..<endIndex)
                        startIndex = nil
                    }
                }
                if forceProcess, let startIndexUnwrapped = startIndex {
                    let jsonStr = String(self.buffer[startIndexUnwrapped...])
                    if let jsonData = jsonStr.data(using: .utf8) {
                        do {
                            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let event = StreamEvent.fromJson(jsonDict) {
                                callback(event)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.delegate?.didEncounterError(.decodingError(description: error.localizedDescription, originalError: error))
                            }
                        }
                    }
                    self.buffer.removeAll()
                }
                for range in rangesToRemove.reversed() {
                    self.buffer.removeSubrange(range)
                }
            }
        }
    }
}
