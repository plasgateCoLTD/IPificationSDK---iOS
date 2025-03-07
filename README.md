# PlasgateAuthSDK

A Swift SDK for authenticating users via Plasgate's IPification service, enabling seamless silent phone number verification for iOS apps without requiring any user interaction.

## Features

- Seamless phone number verification with no user interaction required
- Comprehensive error handling
- Support for deep linking and redirect handling
- Lightweight and easy to integrate

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

### Swift Package Manager (Recommended)

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/PlasgateAuthSDK.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/PlasgateAuthSDK.git`
3. Choose the version you want to install

### Manual Installation

If you prefer manual installation:

1. Download the SDK source
2. Add the source files to your project
3. Make sure to include all required files in your target

## Configuration

### 1. Set Up URL Handling

Add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>plasgateauth</string>
        </array>
    </dict>
</array>
```

Make sure to use a URL scheme that won't conflict with other apps.

### 2. Set Up Redirect Page

You'll need to host a simple HTML redirect page that handles the authentication callback. This page should be hosted on a server you control and specified as the redirect URL in your Plasgate account.

Here's a template for the redirect page:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Plasgate Auth Redirect</title>
    <script>
        window.onload = function() {
            // Get parameters from URL
            const urlParams = new URLSearchParams(window.location.search);
            const code = urlParams.get('code');
            const state = urlParams.get('state');
            
            // Redirect to app if parameters exist
            if (code && state) {
                const redirectUrl = `plasgateauth://callback?code=${code}&state=${state}`;
                
                // Auto-redirect to the app
                window.location.href = redirectUrl;
            }
        }
    </script>
</head>
<body>
    <h2>Completing authentication...</h2>
    <p>Redirecting back to the app...</p>
</body>
</html>
```

Host this page and note the URL, as you'll need it when setting up your Plasgate account.

## Usage

### Initialize the SDK

```swift
import PlasgateAuthSDK

// In your AppDelegate or SceneDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Configure the SDK with your Plasgate credentials
    let config = PlasgateConfiguration(
        privateKey: "YOUR_PRIVATE_KEY",
        secretKey: "YOUR_SECRET_KEY",
        redirectScheme: "plasgateauth" // Must match your URL scheme in Info.plist
    )
    
    PlasgateAuthSDK.shared.configure(with: config)
    
    return true
}
```

### Handle URL callbacks

```swift
// In your AppDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Let the SDK handle the callback URL
    return PlasgateAuthSDK.shared.handleCallback(url: url)
}
```

For SceneDelegate (iOS 13+):

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    _ = PlasgateAuthSDK.shared.handleCallback(url: url)
}
```

### Authenticate a user

```swift
// Format: countryCode + phoneNumber without any separators or plus sign
let phoneNumber = "85516772627" // Example: Cambodia number

PlasgateAuthSDK.shared.authenticate(phoneNumber: phoneNumber) { result in
    switch result {
    case .success(let response):
        // Authentication successful
        let userId = response.sub
        let phoneNumber = response.login_hint
        let isVerified = response.phone_number_verified
        let mobileId = response.mobile_id
        
        // Use the authenticated data
        self.handleSuccessfulAuth(userId: userId, phoneNumber: phoneNumber)
        
    case .failure(let error):
        // Authentication failed
        self.showError(message: error.localizedDescription)
    }
}
```

## Phone Number Format

When authenticating users, provide the phone number in the format: `[country code][number]` without any plus sign or separators.

Examples:
- `85516772627` (Cambodia)
- `447911123456` (UK)
- `12025550189` (US)

## Error Handling

The SDK provides detailed error information through the `AuthError` enum:

```swift
switch error {
case .configurationError(let message):
    // SDK not properly configured
case .invalidInput(let message):
    // Invalid input (e.g., empty phone number)
case .networkError(let underlyingError):
    // Network-related errors
case .authenticationCancelled:
    // User cancelled the authentication
// Handle other error cases
}
```

## Troubleshooting

### Common Issues

1. **Authentication fails immediately**:
   - Check if your private key and secret key are correct
   - Verify that your app has internet permissions

2. **Callback not received after authentication**:
   - Ensure your URL scheme matches between Info.plist and configuration
   - Verify that the redirect page is correctly set up and accessible
   - Check that URL handling methods are properly implemented in AppDelegate/SceneDelegate

3. **App crashes during authentication**:
   - Make sure you're calling the SDK methods on the main thread
   - Verify that you have correctly configured the SDK before using it

## Example App

An example application demonstrating the SDK integration is available in the `Examples` directory. The example shows best practices for integration and demonstrates a complete authentication flow.

## License

This SDK is available under the MIT license. See the LICENSE file for more info.
