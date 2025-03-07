//
//  PlasgateConfiguration.swift
//  PlasgateAuthenticationSDK
//
//  Created by Cora Veng on 3/3/25.
//

import Foundation

/// Configuration object for the Plasgate Auth SDK
public struct PlasgateConfiguration {
    /// Your Plasgate private key
    public let privateKey: String
    
    /// Your Plasgate secret key
    public let secretKey: String
    
    /// The URL scheme for handling redirects back to your app
    public let redirectScheme: String
    
    /// Initialize a new configuration
    /// - Parameters:
    ///   - privateKey: Your Plasgate private key
    ///   - secretKey: Your Plasgate secret key
    ///   - redirectScheme: The URL scheme for handling redirects
    public init(privateKey: String, secretKey: String, redirectScheme: String) {
        self.privateKey = privateKey
        self.secretKey = secretKey
        self.redirectScheme = redirectScheme
    }
}
