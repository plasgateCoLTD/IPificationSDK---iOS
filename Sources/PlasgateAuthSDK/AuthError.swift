//
//  AuthError.swift
//  PlasgateAuthenticationSDK
//
//  Created by Cora Veng on 3/3/25.
//

import Foundation

/// Errors that can occur during authentication
public enum AuthError: Error {
    /// Configuration is missing or invalid
    case configurationError(String)
    
    /// User input is invalid
    case invalidInput(String)
    
    /// URL could not be formed
    case invalidURL
    
    /// Callback URL is invalid or contains an error
    case invalidCallback(String)
    
    /// Network request failed
    case networkError(Error)
    
    /// Request could not be encoded
    case encodingError
    
    /// Response could not be decoded
    case decodingError(String)
    
    /// No data was received
    case noData
    
    /// User cancelled authentication
    case authenticationCancelled
}

// MARK: - LocalizedError
extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .invalidInput(let message):
            return message
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidCallback(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError:
            return "Failed to encode request data"
        case .decodingError(let message):
            return message
        case .noData:
            return "No data received from server"
        case .authenticationCancelled:
            return "Authentication was cancelled"
        }
    }
}
