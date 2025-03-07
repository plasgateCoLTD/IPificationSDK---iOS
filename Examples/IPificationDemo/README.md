# Plasgate IPification Demo

This is a demonstration application for the PlasgateAuthSDK framework, showing how to integrate and use the SDK in your iOS application to authenticate users seamlessly using their phone number.

## Features

- Seamless phone number authentication using Plasgate's service
- Silent authentication (no UI interaction required from the user)
- Handling of authentication callbacks via deep links
- Clean display of authentication results

## Requirements

- iOS 14.0+
- Swift 5.0+
- Xcode 13.0+

## Setup Instructions

1. Clone this repository
2. Open the project in Xcode
3. Build and run the application

## SDK Integration

### 1. Configure in AppDelegate

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Configure the SDK
    let config = PlasgateConfiguration(
        privateKey: "YOUR_PRIVATE_KEY",
        secretKey: "YOUR_SECRET_KEY",
        redirectScheme: "YOUR_REDIRECT_SCHEME"
    )
    
    PlasgateAuthSDK.shared.configure(with: config)
    return true
}
```

### 2. Handle Deep Links

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return PlasgateAuthSDK.shared.handleCallback(url: url)
}
```

### 3. Authenticating Users

```swift
// Silent authentication
PlasgateAuthSDK.shared.authenticate(phoneNumber: phoneNumber) { result in
    switch result {
    case .success(let response):
        // Handle success
    case .failure(let error):
        // Handle error
    }
}
```

## Project Structure

- **IPificationTestApp.swift**: Main app entry point
- **AppDelegate.swift**: Handles application lifecycle and deep links
- **ContentView.swift**: Main UI for the demo app
- **AuthenticationViewModel.swift**: Handles authentication logic

## Phone Number Format

When entering phone numbers, use the format: `[country code][number]` without any plus sign or separators.

Examples:
- 85512345678

## Security Notes

- For production use, never include API keys directly in your code
- Consider using a secure storage solution for sensitive credentials
- Validate phone numbers before sending to the authentication service

## License

This demo application is provided as an example only, as part of the PlasgateAuthSDK documentation.
