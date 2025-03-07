//
//  UIExtensions.swift
//  PlasgateAuthenticationSDK
//
//  Created by Cora Veng on 3/3/25.
//
import Foundation

#if canImport(UIKit)
import UIKit

// MARK: - UIApplication Extensions
public extension UIApplication {
    /// Get the top view controller
    func topViewController() -> UIViewController? {
        // First try using scene-based approach for iOS 13+
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window.rootViewController?.topMostViewController()
        }
        
        // Fallback to traditional approach
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return window.rootViewController?.topMostViewController()
        }
        
        return nil
    }
    
    /// End editing (dismiss keyboard)
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - UIViewController Extensions
public extension UIViewController {
    /// Get the topmost view controller in the hierarchy
    func topMostViewController() -> UIViewController {
        // If this controller is presenting another controller
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        // If this is a navigation controller, use the visible controller
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        // If this is a tab controller, use the selected controller
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        // Otherwise, return this controller
        return self
    }
}
#endif
