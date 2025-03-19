//
//  ZeptoMailService.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 27.10.2024.
//

import Foundation

/// A service class to send emails using the ZeptoMail API.
public class ZeptoMailService {
    // The API key for ZeptoMail service
    private let apiKey: String
    
    // Base URL for the ZeptoMail API
    private let baseURL = "https://api.zeptomail.eu/v1.1/email/template"
    
    // Constant sender information
    private let defaultSender = Sender(address: "noreply@aitronos.com", name: "aitronos")
    
    // Predefined template keys
    private enum Templates: String {
        case freddyWelcomeEmail = "13ef.af487f0368e80b7.k1.16dede50-75c0-11ef-a94a-3a5ca817313f.192054620b5"
        case freddyResetPasswordKey = "13ef.af487f0368e80b7.k1.0b9040f1-692e-11ef-8787-525400b65433.191b2e45a7e"
        case registrationEmailOTPTemplate = "13ef.af487f0368e80b7.k1.e15d3b70-65be-11ef-a188-525400b65433.1919c62a8a7"
    }
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public Methods

    /// Sends a welcome email to the specified recipients.
    public func sendWelcomeEmail(to recipients: [Recipient], mergeInfo: [String: String] = [:], completion: @escaping (Result<Void, FreddyError>) -> Void) {
        sendEmail(
            templateKey: Templates.freddyWelcomeEmail.rawValue,
            bounceAddress: "bounce@bounce.zylker.com",
            to: recipients,
            mergeInfo: mergeInfo,
            completion: completion
        )
    }

    /// Sends a reset password email to the specified recipients.
    public func sendResetPasswordEmail(to recipients: [Recipient], mergeInfo: [String: String] = [:], completion: @escaping (Result<Void, FreddyError>) -> Void) {
        sendEmail(
            templateKey: Templates.freddyResetPasswordKey.rawValue,
            bounceAddress: "bounce@bounce.zylker.com",
            to: recipients,
            mergeInfo: mergeInfo,
            completion: completion
        )
    }

    /// Sends an OTP email to the specified recipients.
    public func sendOTPEmail(to recipients: [Recipient], mergeInfo: [String: String] = [:], completion: @escaping (Result<Void, FreddyError>) -> Void) {
        sendEmail(
            templateKey: Templates.registrationEmailOTPTemplate.rawValue,
            bounceAddress: "",
            to: recipients,
            mergeInfo: mergeInfo,
            completion: completion
        )
    }

    // MARK: - Private Methods

    private func sendEmail(
        templateKey: String,
        bounceAddress: String,
        to recipients: [Recipient],
        cc: [Recipient] = [],
        bcc: [Recipient] = [],
        mergeInfo: [String: String] = [:],
        completion: @escaping (Result<Void, FreddyError>) -> Void
    ) {
        let emailRequest = EmailRequest(
            template_key: templateKey,
            bounce_address: bounceAddress,
            from: defaultSender,
            to: recipients,
            cc: cc,
            bcc: bcc,
            merge_info: mergeInfo,
            reply_to: [defaultSender],
            client_reference: UUID().uuidString,
            mime_headers: ["X-Test": "test"]
        )

        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL(url: baseURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Zoho-enczapikey \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let bodyData = try JSONEncoder().encode(emailRequest)
            request.httpBody = bodyData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(FreddyError.from(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse(description: "Unknown response type")))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let data = data,
                       let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let dictionary = jsonObject as? [String: Any],
                       let errorMessage = dictionary["message"] as? String {
                        completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode, description: errorMessage)))
                    } else {
                        completion(.failure(FreddyError.fromHTTPStatus(httpResponse.statusCode)))
                    }
                    return
                }
                
                completion(.success(()))
            }
            task.resume()
        } catch {
            completion(.failure(.encodingError(description: "Failed to encode email request", originalError: error)))
        }
    }
}

// MARK: - Supporting Models

/// Represents the sender of the email.
struct Sender: Codable {
    let address: String
    let name: String
}

/// Represents a recipient of the email.
public struct Recipient: Codable {
    let emailAddress: EmailAddress

    public init(email: String, name: String) {
        emailAddress = EmailAddress(address: email, name: name)
    }
}

/// Represents an email address and name.
struct EmailAddress: Codable {
    let address: String
    let name: String
}

/// Represents the entire email request payload.
struct EmailRequest: Codable {
    let template_key: String
    let bounce_address: String
    let from: Sender
    let to: [Recipient]
    let cc: [Recipient]
    let bcc: [Recipient]
    let merge_info: [String: String]
    let reply_to: [Sender]?
    let client_reference: String
    let mime_headers: [String: String]
}
