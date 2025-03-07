//
//  AuthenticationResponse.swift
//  PlasgateAuthenticationSDK
//
//  Created by Cora Veng on 3/3/25.
//

import Foundation

/// The response from a successful authentication
public struct AuthenticationResponse: Codable, Identifiable {
    /// The user's unique identifier
    public let sub: String
    
    /// The user's phone number
    public let login_hint: String
    
    /// Whether the phone number was verified
    public let phone_number_verified: Bool
    
    /// The user's mobile ID
    public let mobile_id: String
    
    /// Error description if any
    public let error_description: String?
    
    /// Status of the authentication
    public let status: String?
    
    /// Session ID
    public let sid: String?
    
    /// Additional message
    public let message: String?
    
    /// Unique identifier for this response
    public var id: String {
        return sub
    }
    
    /// Initialize a new authentication response
    /// - Parameters:
    ///   - sub: The user's unique identifier
    ///   - login_hint: The user's phone number
    ///   - phone_number_verified: Whether the phone number was verified
    ///   - mobile_id: The user's mobile ID
    ///   - error_description: Error description if any
    ///   - status: Status of the authentication
    ///   - sid: Session ID
    ///   - message: Additional message
    public init(sub: String,
                login_hint: String,
                phone_number_verified: Bool,
                mobile_id: String,
                error_description: String? = nil,
                status: String? = nil,
                sid: String? = nil,
                message: String? = nil) {
        self.sub = sub
        self.login_hint = login_hint
        self.phone_number_verified = phone_number_verified
        self.mobile_id = mobile_id
        self.error_description = error_description
        self.status = status
        self.sid = sid
        self.message = message
    }
}
