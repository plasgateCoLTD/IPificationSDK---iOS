//
//  PlasgateAuthDemoApp.swift
//  IPificationTest
//
//  Created by Cora Veng on 7/3/25.
//

import SwiftUI
import PlasgateAuthSDK

// MARK: - Main App Entry Point
@main
struct IPificationTestApp: App {
    // MARK: - Properties
    
    /// App delegate for handling lifecycle events and deep links
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
