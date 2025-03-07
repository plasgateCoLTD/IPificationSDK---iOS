import Foundation

#if canImport(UIKit)
import UIKit
import SafariServices
import AuthenticationServices

// MARK: - Authentication Context Provider
/// Provides the presentation context for web authentication
public class AuthenticationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    /// Shared instance
    public static let shared = AuthenticationContextProvider()
    
    /// Returns the presentation anchor for web authentication
    /// - Parameter session: The authentication session
    /// - Returns: The presentation anchor
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback to first window
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                return window
            }
            fatalError("No window available for presentation")
        }
        return window
    }
}

// MARK: - Auth Service
/// Core service for handling authentication operations
public class PlasgateAuthService {
    // MARK: - Constants
    /// Constants used throughout the service
    public struct Constants {
        /// OAuth scope
        public static let scope = "mobile_id phone_verify"
        
        /// Base URL for authentication
        public static let authenticateURL = "https://cloudapi.plasgate.com/ip/authenticate"
        
        /// URL for verifying authentication
        public static let checkInfoURL = "https://cloudapi.plasgate.com/ip/check-info"
        
        /// Redirect URL for OAuth flow, use your own
        public static let redirectURL = ""
        
        /// Default private key (for development only)
        public static let defaultPrivateKey = ""
        
        /// Default secret key (for development only)
        public static let defaultSecretKey = ""
        
        /// Default redirect scheme (for development only)
        public static let defaultRedirectScheme = "plasgateauth"
    }
    
    // MARK: - Properties
    /// Shared instance
    public static let shared = PlasgateAuthService()
    
    /// User defaults for storing temporary data
    private let userDefaults = UserDefaults.standard
    
    /// Completion handler for authentication
    private var authenticationCompletion: ((Result<AuthenticationResponse, AuthError>) -> Void)?
    
    /// Current SDK configuration
    public var configuration: PlasgateConfiguration?
    
    /// Web authentication session for visible authentication
    private var authSession: ASWebAuthenticationSession?
    
    /// Safari view controller for visible authentication
    private var safariVC: SFSafariViewController?
    
    /// Handler for hidden authentication
    private var hiddenAuthHandler: PlasgateHiddenWebAuthHandler?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Configuration
    /// Configure the service with SDK credentials
    /// - Parameter configuration: The configuration to use
    public func configure(_ configuration: PlasgateConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Authentication Methods
    
    /// Start authentication process in the background (no UI shown)
    /// - Parameters:
    ///   - phoneNumber: The user's phone number to authenticate
    ///   - completion: Callback with the result
    public func startAuthentication(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        guard let config = configuration else {
            completion(.failure(.configurationError("Service not configured")))
            return
        }
        
        guard !phoneNumber.isEmpty else {
            completion(.failure(.invalidInput("Phone number required!")))
            return
        }
        
        userDefaults.set(phoneNumber, forKey: "phone_number")
        self.authenticationCompletion = completion
        
        // Create and store a strong reference to the handler
        let handler = PlasgateHiddenWebAuthHandler(configuration: config)
        self.hiddenAuthHandler = handler
        // Start authentication with a separate completion that clears our reference
        handler.startAuthentication(phoneNumber: phoneNumber) { [weak self] result in
            // Clear the reference to allow deallocation
            self?.hiddenAuthHandler = nil
            
            // Forward the result to the original completion handler
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Start authentication with visible UI (web popup)
    /// - Parameters:
    ///   - phoneNumber: The user's phone number to authenticate
    ///   - completion: Callback with the result
    public func startVisibleAuthentication(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        guard let config = configuration else {
            completion(.failure(.configurationError("Service not configured")))
            return
        }
        
        guard !phoneNumber.isEmpty else {
            completion(.failure(.invalidInput("Phone number required!")))
            return
        }
        
        userDefaults.set(phoneNumber, forKey: "phone_number")
        self.authenticationCompletion = completion
        
        var components = URLComponents(string: Constants.authenticateURL)
        components?.queryItems = [
            URLQueryItem(name: "private_key", value: config.privateKey),
            URLQueryItem(name: "phone_number", value: phoneNumber),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURL),
            URLQueryItem(name: "scope", value: Constants.scope)
        ]
        
        guard let authURL = components?.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        #if DEBUG
        print("[DEBUG] Auth URL: \(authURL.absoluteString)")
        #endif
        
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: config.redirectScheme,
            completionHandler: { [weak self] callbackURL, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self?.authenticationCompletion?(.failure(.authenticationCancelled))
                    } else {
                        self?.authenticationCompletion?(.failure(.networkError(error)))
                    }
                    return
                }
                
                guard let url = callbackURL else {
                    self?.authenticationCompletion?(.failure(.invalidCallback("No callback URL")))
                    return
                }
                
                self?.handleCallback(url: url)
            }
        )
        
        authSession?.presentationContextProvider = AuthenticationContextProvider.shared
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }
    
    // MARK: - Callback Handling
    /// Handle callback URL from the authentication flow
    /// - Parameter url: The callback URL to handle
    public func handleCallback(url: URL) {
        #if DEBUG
        print("[DEBUG] Handling callback: \(url.absoluteString)")
        #endif
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value else {
            authenticationCompletion?(.failure(.invalidCallback("Missing code/state")))
            return
        }
        
        verifyAuthentication(code: code, state: state)
    }
    
    // MARK: - Authentication Verification
    /// Verify authentication code with the server
    /// - Parameters:
    ///   - code: The authentication code
    ///   - state: The state parameter
    private func verifyAuthentication(code: String, state: String) {
        guard let config = configuration else {
            authenticationCompletion?(.failure(.configurationError("Service not configured")))
            return
        }
        
        guard let url = URL(string: Constants.checkInfoURL) else {
            authenticationCompletion?(.failure(.invalidURL))
            return
        }
        
        let body: [String: Any] = [
            "private_key": config.privateKey,
            "response_type": "code",
            "state": state,
            "redirect_uri": Constants.redirectURL,
            "code": code
        ]
        
        #if DEBUG
        print("[DEBUG] Verification body: \(body)")
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.secretKey, forHTTPHeaderField: "X-Secret")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            authenticationCompletion?(.failure(.encodingError))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.authenticationCompletion?(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                self?.authenticationCompletion?(.failure(.noData))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP Error \(httpResponse.statusCode)"
                self?.authenticationCompletion?(.failure(.invalidCallback(errorMessage)))
                return
            }
            
            #if DEBUG
            // Add debug print to see the raw response
            let rawResponse = String(data: data, encoding: .utf8) ?? "Invalid data"
            print("[DEBUG] Raw API Response: \(rawResponse)")
            #endif
            
            self?.processAuthenticationResponse(data: data)
        }
        task.resume()
    }
    
    /// Process and parse the authentication response
    /// - Parameter data: The response data
    private func processAuthenticationResponse(data: Data) {
        do {
            // Try first with JSON parsing to handle different data types
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check if we have all required fields
                if let sub = json["sub"] as? String,
                   let loginHint = json["login_hint"] as? String,
                   let mobileId = json["mobile_id"] as? String {
                    
                    // Handle phone_number_verified which could be a String or Bool
                    let phoneVerified: Bool
                    if let verified = json["phone_number_verified"] as? Bool {
                        phoneVerified = verified
                    } else if let verifiedStr = json["phone_number_verified"] as? String {
                        phoneVerified = verifiedStr.lowercased() == "true"
                    } else {
                        phoneVerified = false
                    }
                    
                    // Create a custom response
                    let response = AuthenticationResponse(
                        sub: sub,
                        login_hint: loginHint,
                        phone_number_verified: phoneVerified,
                        mobile_id: mobileId,
                        error_description: json["error_description"] as? String,
                        status: json["status"] as? String,
                        sid: json["sid"] as? String,
                        message: json["message"] as? String
                    )
                    
                    DispatchQueue.main.async {
                        self.authenticationCompletion?(.success(response))
                    }
                    return
                }
            }
            
            // If manual parsing fails, try regular decoding
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(AuthenticationResponse.self, from: data)
            
            DispatchQueue.main.async {
                if response.error_description == nil || (response.status == "success" && response.phone_number_verified) {
                    self.authenticationCompletion?(.success(response))
                } else {
                    let errorMessage = response.error_description ?? "Authentication failed"
                    self.authenticationCompletion?(.failure(.invalidCallback(errorMessage)))
                }
            }
        } catch {
            #if DEBUG
            let rawResponse = String(data: data, encoding: .utf8) ?? "Invalid data"
            #endif
            
            DispatchQueue.main.async {
                #if DEBUG
                let errorMessage = "Decoding failed: \(error.localizedDescription)\nResponse: \(rawResponse)"
                #else
                let errorMessage = "Decoding failed: \(error.localizedDescription)"
                #endif
                self.authenticationCompletion?(.failure(.decodingError(errorMessage)))
            }
        }
    }
    
    /// Present the authentication view for visible authentication
    /// - Parameter url: The URL to display
    private func presentAuthenticationView(with url: URL) {
        if let topVC = UIApplication.shared.topViewController() {
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationStyle = .fullScreen
            self.safariVC = safariVC
            topVC.present(safariVC, animated: true)
        }
    }

    /// Dismiss the authentication view
    /// - Parameter completion: Completion handler called after dismissal
    private func dismissAuthenticationView(completion: (() -> Void)? = nil) {
        if let topVC = UIApplication.shared.topViewController(),
           let safariVC = topVC.presentedViewController as? SFSafariViewController {
            safariVC.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
        authSession = nil
    }
}
#else
// Stub implementation for non-UIKit platforms
public class PlasgateAuthService {
    public static let shared = PlasgateAuthService()
    public var configuration: PlasgateConfiguration?
    
    private init() {}
    
    public func configure(_ configuration: PlasgateConfiguration) {
        self.configuration = configuration
    }
    
    public func startAuthentication(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        completion(.failure(.configurationError("PlasgateAuthSDK only supports iOS platforms")))
    }
    
    public func startVisibleAuthentication(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        completion(.failure(.configurationError("PlasgateAuthSDK only supports iOS platforms")))
    }
    
    public func handleCallback(url: URL) {
        // No-op for non-UIKit platforms
    }
}
#endif
