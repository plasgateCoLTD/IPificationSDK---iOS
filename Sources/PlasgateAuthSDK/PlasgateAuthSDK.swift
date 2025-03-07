import Foundation

#if canImport(UIKit)
import UIKit

// MARK: - Main SDK Class
/// The main entry point for the Plasgate Authentication SDK.
/// Use this class to configure and perform authentication operations.
public final class PlasgateAuthSDK {
    // MARK: - Singleton Instance
    /// The shared instance of the SDK
    public static let shared = PlasgateAuthSDK()
    
    // MARK: - Properties
    /// The underlying service that handles authentication
    private var service: PlasgateAuthService
    
    // MARK: - Initialization
    private init() {
        self.service = PlasgateAuthService.shared
    }
    
    // MARK: - Public API
    
    /// Configure the SDK with your Plasgate credentials
    /// - Parameter configuration: Your PlasgateConfiguration
    public func configure(with configuration: PlasgateConfiguration) {
        service.configure(configuration)
    }
    
    /// Start the authentication process using the phone number
    /// - Parameters:
    ///   - phoneNumber: The user's phone number to authenticate
    ///   - completion: Closure that will be called with the authentication result
    public func authenticate(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        service.startAuthentication(phoneNumber: phoneNumber, completion: completion)
    }
    
    /// Start a visible authentication process (shows a web popup)
    /// - Parameters:
    ///   - phoneNumber: The user's phone number to authenticate
    ///   - completion: Closure that will be called with the authentication result
    public func authenticateWithWebPopup(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        service.startVisibleAuthentication(phoneNumber: phoneNumber, completion: completion)
    }
    
    /// Handle callback URL from authentication flow
    /// - Parameter url: The URL received from the redirect
    /// - Returns: Whether the URL was handled by the SDK
    @discardableResult
    public func handleCallback(url: URL) -> Bool {
        if url.scheme == service.configuration?.redirectScheme {
            service.handleCallback(url: url)
            return true
        }
        return false
    }
    
    /// Register this method in your AppDelegate to handle deep links
    /// - Parameters:
    ///   - app: The UIApplication instance
    ///   - url: The URL received by the application
    ///   - options: URL options
    /// - Returns: Whether the URL was handled by the SDK
    @discardableResult
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return handleCallback(url: url)
    }
}

// MARK: - SDK Version
public extension PlasgateAuthSDK {
    /// The current version of the SDK
    static var version: String {
        return "1.0.0"
    }
}

// MARK: - UIApplicationDelegate Extension
public extension UIApplicationDelegate {
    /// Add this to your AppDelegate to handle authentication callbacks
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == PlasgateAuthService.shared.configuration?.redirectScheme {
            PlasgateAuthService.shared.handleCallback(url: url)
            return true
        }
        return false
    }
}
#else
// Non-UIKit version (stub implementation for other platforms)
public final class PlasgateAuthSDK {
    public static let shared = PlasgateAuthSDK()
    private init() {}
    
    public func configure(with configuration: PlasgateConfiguration) {
        fatalError("PlasgateAuthSDK only supports iOS platforms")
    }
    
    public func authenticate(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        completion(.failure(.configurationError("PlasgateAuthSDK only supports iOS platforms")))
    }
    
    public func authenticateWithWebPopup(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        completion(.failure(.configurationError("PlasgateAuthSDK only supports iOS platforms")))
    }
    
    @discardableResult
    public func handleCallback(url: URL) -> Bool {
        return false
    }
    
    public static var version: String {
        return "1.0.0"
    }
}
#endif
