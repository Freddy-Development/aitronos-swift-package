//
//  SendVerificationCode.swift
//  aitronos-swift-package
//
//  Created by Phillip Loacker on 20.10.2024.
//

import Foundation

public extension AppHive {
    /// Sends a verification code to the user's email address.
    /// - Parameters:
    ///   - email: The email address to send the verification code to
    ///   - fullName: The full name of the recipient
    ///   - zeptomailApiKey: The API key for the ZeptoMail service
    ///   - completion: A completion handler that returns either a success with the verification code or a failure with an error
    func sendVerificationCode(to email: String, fullName: String, zeptomailApiKey: String, completion: @escaping (Result<String, FreddyError>) -> Void) {
        // Generate a random 4-digit code
        let verificationCode = String(Int.random(in: 1000...9999))
        let codeExpiryMinutes = 10
        
        // Prepare merge info for the email template
        let mergeInfo: [String: String] = [
            "token": verificationCode,
            "expiry_minutes": "\(codeExpiryMinutes)",
            "contact_email": "support@aitronos.com"
        ]
        
        // Create recipient
        let recipient = Recipient(email: email, name: fullName)
        
        // Send the verification email
        let emailService = ZeptoMailService(apiKey: zeptomailApiKey)
        emailService.sendOTPEmail(to: [recipient], mergeInfo: mergeInfo) { result in
            switch result {
            case .success:
                completion(.success(verificationCode))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
