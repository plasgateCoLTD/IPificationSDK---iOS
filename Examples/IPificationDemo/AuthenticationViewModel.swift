//
//  AuthenticationViewModel.swift
//  IPificationTest
//
//  Created by Cora Veng on 7/3/25.
//

import Foundation
import PlasgateAuthSDK
import Combine

// MARK: - Authentication View Model
/// View model that handles authentication logic
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Phone number input by the user
    @Published var phoneNumber: String = ""
    
    /// Whether authentication is in progress
    @Published var isAuthenticating: Bool = false
    
    /// Status message to display to the user
    @Published var statusMessage: String = ""
    
    /// Whether to show the alert
    @Published var showAlert: Bool = false
    
    /// The result of authentication (if successful)
    @Published var authResult: AuthenticationResponse?
    
    // MARK: - Private Properties
    
    /// The last error encountered (if any)
    private var lastError: AuthError?
    
    // MARK: - Authentication Methods
    
    /// Start the authentication process
    func authenticate() {
        guard validatePhoneNumber() else {
            setError(.invalidInput("Please enter a valid phone number"))
            return
        }
        
        isAuthenticating = true
        statusMessage = "Starting authentication..."
        
        PlasgateAuthSDK.shared.authenticate(phoneNumber: phoneNumber) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                switch result {
                case .success(let response):
                    self.handleSuccess(response)
                case .failure(let error):
                    self.handleError(error)
                }
                
                self.showAlert = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validate the phone number format
    /// - Returns: Whether the phone number is valid
    private func validatePhoneNumber() -> Bool {
        // Check if the number contains only digits
        let digitsOnly = phoneNumber.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        
        // Basic validation - must be digits only and not empty
        // Production app would have more sophisticated validation
        return !digitsOnly.isEmpty && digitsOnly.count >= 8
    }
    
    /// Handle successful authentication
    /// - Parameter response: The authentication response
    private func handleSuccess(_ response: AuthenticationResponse) {
        self.authResult = response
        self.statusMessage = "Authentication successful!"
    }
    
    /// Handle authentication error
    /// - Parameter error: The error that occurred
    private func handleError(_ error: AuthError) {
        self.lastError = error
        self.statusMessage = "Authentication failed: \(error.localizedDescription)"
    }
    
    /// Set an error directly
    /// - Parameter error: The error to set
    private func setError(_ error: AuthError) {
        self.lastError = error
        self.statusMessage = error.localizedDescription
        self.showAlert = true
    }
    
    /// Reset the authentication state
    func reset() {
        statusMessage = ""
        authResult = nil
        lastError = nil
    }
}
