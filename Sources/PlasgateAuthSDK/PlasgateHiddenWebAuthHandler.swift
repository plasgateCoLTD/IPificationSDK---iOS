import Foundation

#if canImport(UIKit)
import UIKit
import WebKit

// MARK: - Hidden WebView Authentication Handler
/// Handler for background authentication using a hidden WebView
/// This class manages the authentication flow without showing UI to the user
public class PlasgateHiddenWebAuthHandler: NSObject, WKNavigationDelegate {
    // MARK: - Properties
    /// The hidden web view used for authentication
    private var webView: WKWebView?
    
    /// Completion handler for authentication
    private var completion: ((Result<AuthenticationResponse, AuthError>) -> Void)?
    
    /// SDK configuration
    private let configuration: PlasgateConfiguration
    
    /// Timer to handle authentication timeouts
    private var timeoutTimer: Timer?
    
    /// Authentication timeout in seconds
    private let authenticationTimeout: TimeInterval = 30
    
    // Keep a strong reference to ensure it's not deallocated during authentication
    // This is a class variable so it persists across instances
    private static var activeInstances = [PlasgateHiddenWebAuthHandler]()
    
    // MARK: - Initialization
    /// Initialize with a configuration
    /// - Parameter configuration: The SDK configuration
    public init(configuration: PlasgateConfiguration) {
        self.configuration = configuration
        super.init()
        
        // Add self to active instances
        Self.activeInstances.append(self)
        #if DEBUG
        print("[DEBUG] Added handler to active instances. Count: \(Self.activeInstances.count)")
        #endif
    }
    
    // MARK: - WebView Setup
    /// Set up a hidden WebView for authentication
    /// - Returns: The configured WebView
    private func setupWebView() -> WKWebView {
        // Create a WebView configuration with minimized resource usage
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // Create the WebView with a minimal frame
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 10, height: 10), configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.alpha = 0.01  // Almost invisible but still functional
        
        // Finding the key window more reliably
        var keyWindow: UIWindow?
        if #available(iOS 15.0, *) {
            // For iOS 15 and above
            keyWindow = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows
                .first(where: { $0.isKeyWindow })
        } else {
            // For iOS 14 and below
            keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
        
        // Add to window
        if let window = keyWindow {
            window.addSubview(webView)
            #if DEBUG
            print("[DEBUG] Added WebView to key window")
            #endif
        } else {
            #if DEBUG
            print("[ERROR] No key window found to attach WebView")
            #endif
        }
        
        return webView
    }
    
    // MARK: - Authentication
    /// Start the background authentication process
    /// - Parameters:
    ///   - phoneNumber: The user's phone number
    ///   - completion: Callback with the result
    public func startAuthentication(phoneNumber: String, completion: @escaping (Result<AuthenticationResponse, AuthError>) -> Void) {
        self.completion = completion
        
        // Add timeout protection
        self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: authenticationTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.webView != nil else { return }
            #if DEBUG
            print("[DEBUG] Authentication timeout after \(self.authenticationTimeout) seconds")
            #endif
            self.finishWithResult(.failure(.networkError(NSError(domain: "com.plasgateauth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication timed out after \(self.authenticationTimeout) seconds"]))))
        }
        
        // Create the webView now, not in init
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.webView = self.setupWebView()
            
            // Create URL with parameters
            var components = URLComponents(string: PlasgateAuthService.Constants.authenticateURL)
            components?.queryItems = [
                URLQueryItem(name: "private_key", value: self.configuration.privateKey),
                URLQueryItem(name: "phone_number", value: phoneNumber),
                URLQueryItem(name: "redirect_uri", value: PlasgateAuthService.Constants.redirectURL),
                URLQueryItem(name: "scope", value: PlasgateAuthService.Constants.scope)
            ]
            
            guard let authURL = components?.url else {
                self.finishWithResult(.failure(.invalidURL))
                return
            }
            
            #if DEBUG
            print("[DEBUG] Starting hidden authentication with URL: \(authURL.absoluteString)")
            #endif
            self.webView?.load(URLRequest(url: authURL))
        }
    }
    
    // MARK: - WKNavigationDelegate
    /// Handle navigation actions in the WebView
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            #if DEBUG
            print("[DEBUG] WebView navigating to: \(url.absoluteString)")
            #endif
            
            // Check for plasgateauth:// URLs directly
            if let scheme = url.scheme, scheme == configuration.redirectScheme {
                #if DEBUG
                print("[DEBUG] Found app scheme URL: \(url.absoluteString)")
                #endif
                decisionHandler(.cancel)
                
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                   let state = components.queryItems?.first(where: { $0.name == "state" })?.value {
                    #if DEBUG
                    print("[DEBUG] Extracted code and state from app URL")
                    #endif
                    verifyAuthentication(code: code, state: state)
                }
                return
            }
            
            // Check for redirect URL
            if url.absoluteString.hasPrefix(PlasgateAuthService.Constants.redirectURL) {
                #if DEBUG
                print("[DEBUG] Found redirect URL: \(url.absoluteString)")
                #endif
                
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                   let state = components.queryItems?.first(where: { $0.name == "state" })?.value {
                    
                    #if DEBUG
                    print("[DEBUG] Extracted code and state from redirect URL")
                    #endif
                    
                    // Always allow this navigation first so the page can load
                    decisionHandler(.allow)
                    
                    // But also set a timer to verify if the app scheme redirect doesn't work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        guard let self = self, self.webView != nil else { return }
                        #if DEBUG
                        print("[DEBUG] Using fallback verification")
                        #endif
                        self.verifyAuthentication(code: code, state: state)
                    }
                    return
                }
            }
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - Authentication Verification
    /// Verify the authentication code with the server
    /// - Parameters:
    ///   - code: The authentication code
    ///   - state: The state parameter
    private func verifyAuthentication(code: String, state: String) {
        // Cancel timeout timer
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        guard let url = URL(string: PlasgateAuthService.Constants.checkInfoURL) else {
            finishWithResult(.failure(.invalidURL))
            return
        }
        
        let body: [String: Any] = [
            "private_key": configuration.privateKey,
            "response_type": "code",
            "state": state,
            "redirect_uri": PlasgateAuthService.Constants.redirectURL,
            "code": code
        ]
        
        #if DEBUG
        print("[DEBUG] Verification body: \(body)")
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.secretKey, forHTTPHeaderField: "X-Secret")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            finishWithResult(.failure(.encodingError))
            return
        }
        
        // Use a background queue for network operations
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Create a strong reference to self for the network task
            let strongSelf = self
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    strongSelf.finishWithResult(.failure(.networkError(error)))
                    return
                }
                
                guard let data = data else {
                    strongSelf.finishWithResult(.failure(.noData))
                    return
                }
                
                #if DEBUG
                let rawResponse = String(data: data, encoding: .utf8) ?? "Invalid data"
                print("[DEBUG] Raw API Response: \(rawResponse)")
                #endif
                
                strongSelf.processAuthenticationResponse(data: data)
            }
            task.resume()
        }
    }
    
    // MARK: - Response Processing
    /// Process the authentication response data
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
                    
                    self.finishWithResult(.success(response))
                    return
                }
            }
            
            // If manual parsing fails, try decoder
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(AuthenticationResponse.self, from: data)
            
            if response.error_description == nil || (response.status == "success" && response.phone_number_verified) {
                self.finishWithResult(.success(response))
            } else {
                let errorMessage = response.error_description ?? "Authentication failed"
                self.finishWithResult(.failure(.invalidCallback(errorMessage)))
            }
        } catch {
            #if DEBUG
            let rawResponse = String(data: data, encoding: .utf8) ?? "Invalid data"
            let errorMessage = "Decoding failed: \(error.localizedDescription)\nResponse: \(rawResponse)"
            #else
            let errorMessage = "Decoding failed: \(error.localizedDescription)"
            #endif
            
            self.finishWithResult(.failure(.decodingError(errorMessage)))
        }
    }
    
    // MARK: - Cleanup
    /// Finish authentication with a result
    /// - Parameter result: The authentication result
    private func finishWithResult(_ result: Result<AuthenticationResponse, AuthError>) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel timeout timer if it's still active
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
            
            // Capture the completion handler before cleanup
            let completionHandler = self.completion
            
            // First clean up resources
            self.cleanup()
            
            // Then call the completion handler
            #if DEBUG
            print("[DEBUG] Calling completion handler with result")
            #endif
            completionHandler?(result)
        }
    }
    
    /// Clean up resources
    private func cleanup() {
        #if DEBUG
        print("[DEBUG] Cleanup called for handler")
        #endif
        
        // Remove WebView from the view hierarchy
        webView?.removeFromSuperview()
        webView = nil
        
        // Cancel timeout timer if it exists
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        // Remove self from active instances
        if let index = Self.activeInstances.firstIndex(where: { $0 === self }) {
            Self.activeInstances.remove(at: index)
            #if DEBUG
            print("[DEBUG] Removed handler from active instances. Count: \(Self.activeInstances.count)")
            #endif
        }
    }
    
    deinit {
        #if DEBUG
        print("[DEBUG] Handler being deallocated")
        #endif
        cleanup()
    }
}
#endif
