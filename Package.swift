// swift-tools-version:5.7
// Package.swift
// PlasgateAuthenticationSDK
//
// Created by Cora Veng on 3/3/25.
//

import PackageDescription

let package = Package(
    name: "PlasgateAuthSDK",
    platforms: [
        .iOS(.v13)  // Minimum iOS version required
    ],
    products: [
        .library(
            name: "PlasgateAuthSDK",
            targets: ["PlasgateAuthSDK"]),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "PlasgateAuthSDK",
            dependencies: []),
    ]
)
