//
//  AppDelegate.swift
//  IPificationTest
//
//  Created by Cora Veng on 7/3/25.
//

import UIKit
import PlasgateAuthSDK

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Application Lifecycle
    
    /// Called when the application has finished launching
    /// - Parameters:
    ///   - application: The singleton app object
    ///   - launchOptions: Options dictionary
    /// - Returns: Success indicator
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupSDK()
        
        #if DEBUG
        print("[DEBUG] App finished launching with SDK v\(PlasgateAuthSDK.version)")
        #endif
        
        return true
    }
    
    /// Handle deep links to the application
    /// - Parameters:
    ///   - app: The singleton app object
    ///   - url: The URL resource to open
    ///   - options: Additional options
    /// - Returns: Success indicator
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        #if DEBUG
        print("[DEBUG] App received deep link: \(url.absoluteString)")
        #endif
        
        let result = PlasgateAuthSDK.shared.handleCallback(url: url)
        
        #if DEBUG
        print("[DEBUG] Handle callback result: \(result)")
        #endif
        
        return result
    }
    
    // MARK: - SDK Setup
    
    /// Configure the SDK with default credentials
    private func setupSDK() {
        // Configure the SDK with the appropriate keys for your environment
        let config = PlasgateConfiguration(
            privateKey: "your_private_key",
            secretKey: "your_secret_key",
            redirectScheme: "your_redirect_scheme"
        )
        
        PlasgateAuthSDK.shared.configure(with: config)
    }
}
