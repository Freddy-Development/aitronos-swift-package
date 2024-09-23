// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import os.log

let log = OSLog(subsystem: "com.aitronos.app", category: "network")

// MARK: - FreddyApi Class
public class FreddyApi {
    private let baseUrls: [String: String] = ["v1": "https://freddy-core-api.azurewebsites.net/v1"]
    private var token: String
    private var version: String
    private var baseUrl: String
    private var headers: [String: String]
    private var rateLimitReached: Bool = false

    public init(token: String, version: String = "v1") {
        guard let url = baseUrls[version] else {
            fatalError("Unsupported API version: \(version). Supported versions are: \(baseUrls.keys.joined(separator: ", "))")
        }
        self.token = token
        self.version = version
        self.baseUrl = url
        self.headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }

    // MARK: - Stream API
    public func createStream(payload: MessageRequestPayload, callback: @Sendable @escaping (StreamEvent?) -> Void) {
        let url = URL(string: "\(self.baseUrl)/messages/run-stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = self.headers

        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(payload) else {
            os_log("Failed to encode payload", log: log, type: .error)
            return
        }
        request.httpBody = jsonData

        let session = URLSession.shared
        session.dataTask(with: request) { [callback] data, response, error in  // Capture `callback` safely
            if let error = error {
                os_log("Request error: %@", log: log, type: .error, error.localizedDescription)
                return
            }

            guard let data = data else {
                os_log("No data received", log: log, type: .error)
                return
            }

            let buffer = String(data: data, encoding: .utf8) ?? ""
            let regex = try! NSRegularExpression(pattern: "\\{[^{}]*\\}|\\[[^\\[\\]]*\\]", options: [])
            let matches = regex.matches(in: buffer, range: NSRange(buffer.startIndex..., in: buffer))

            for match in matches {
                let jsonStr = (buffer as NSString).substring(with: match.range)
                guard let jsonData = jsonStr.data(using: .utf8),
                      let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let event = StreamEvent.fromJson(jsonDict) else {
                    continue
                }
                callback(event)  // Invoke the callback here
            }
        }.resume()
    }
    // TODO: Implement other API methods
}
