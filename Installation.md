# Installation Guide for PlasgateAuthSDK

This guide will walk you through how to properly install and set up the PlasgateAuthSDK in your iOS project for seamless phone number authentication.

## Installation Options

### Option 1: Swift Package Manager (Recommended)

#### Step 1: Add the Package Dependency

1. In Xcode, go to **File > Add Packages...**
2. In the search bar, enter the repository URL: `https://github.com/yourusername/PlasgateAuthSDK.git`
3. Choose the version or branch you want to install
4. Click **Add Package**

#### Step 2: Import the SDK

In any file where you want to use the SDK, add the import statement:

```swift
import PlasgateAuthSDK
```

### Option 2: Manual Installation

If you prefer manual installation or need to make local modifications:

#### Step 1: Download the Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/PlasgateAuthSDK.git
   ```

#### Step 2: Add to Your Project

1. In Xcode, go to **File > Add Files to "YourProject"**
2. Navigate to the downloaded PlasgateAuthSDK source directory
3. Select all the Swift files
4. Make sure "Copy items if needed" is checked
5. Add to your target
6. Click **Add**

## Required Setup

### Step 1: Configure URL Scheme in Info.plist

Add the following to your `Info.plist` file to handle authentication callbacks:

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

> **Important**: You can use any URL scheme you prefer, but make sure it's unique and matches the `redirectScheme` you provide during SDK configuration.

### Step 2: Set Up Redirect Page

You'll need to host a simple HTML redirect page that handles the authentication callback. This page should be hosted on a server you control.

Create an HTML file with the following content:

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
            
            // Display parameters for debugging
            document.getElementById('params').textContent = window.location.search;
            
            // Redirect to app if parameters exist
            if (code && state) {
                const redirectUrl = `plasgateauth://callback?code=${code}&state=${state}`;
                document.getElementById('redirectUrl').textContent = redirectUrl;
                document.getElementById('redirectLink').href = redirectUrl;
                document.getElementById('redirectLink').style.display = 'block';
                
                // Auto-redirect after a short delay
                setTimeout(function() {
                    window.location.href = redirectUrl;
                }, 1500);
            }
        }
    </script>
</head>
<body>
    <h2>Plasgate Auth Redirect</h2>
    <p>URL Parameters: <span id="params">None</span></p>
    <p>Redirect URL: <span id="redirectUrl">Waiting for parameters...</span></p>
    <a id="redirectLink" href="#" style="display:none">Click here to open the app</a>
    <p>Redirecting to mobile app automatically...</p>
</body>
</html>
```

Host this page on your server and note the URL (e.g., `https://your-domain.com/plasgate-redirect.html`).

> **Note**: Make sure to replace `plasgateauth` in the redirect URL with your custom URL scheme if you're using a different one.

### Step 3: Handle URL Callbacks

#### In AppDelegate:

```swift
import PlasgateAuthSDK

// Add this method to handle deep links
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return PlasgateAuthSDK.shared.handleCallback(url: url)
}
```

#### For SceneDelegate (iOS 13+):

```swift
import PlasgateAuthSDK

// Add this method to handle deep links
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    _ = PlasgateAuthSDK.shared.handleCallback(url: url)
}
```

## SDK Initialization

### Initialize in AppDelegate or SceneDelegate

Add this code to your `didFinishLaunchingWithOptions` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Configure the SDK with your Plasgate credentials
    let config = PlasgateConfiguration(
        privateKey: "YOUR_PRIVATE_KEY", // Replace with your actual keys
        secretKey: "YOUR_SECRET_KEY",
        redirectScheme: "plasgateauth" // Must match your URL scheme in Info.plist
    )
    
    PlasgateAuthSDK.shared.configure(with: config)
    
    return true
}
```

> **Important**: Replace `YOUR_PRIVATE_KEY` and `YOUR_SECRET_KEY` with your actual Plasgate API credentials.

## Verifying Installation

To verify that the SDK is correctly installed and configured, add this simple test to your code:

```swift
let sdkVersion = PlasgateAuthSDK.version
print("PlasgateAuthSDK installed successfully. Version: \(sdkVersion)")
```

## Troubleshooting

### Common Installation Issues

1. **SDK not found after installation**:
   - Ensure the SDK is properly added to your target
   - Try cleaning your project (Cmd+Shift+K) and rebuilding

2. **Deep linking not working**:
   - Verify that Info.plist is correctly configured
   - Check that your URL scheme is registered correctly
   - Ensure your redirect page is properly set up and accessible

3. **SSL errors with redirect page**:
   - Make sure your redirect page is served over HTTPS
   - Check for any mixed content warnings

4. **Initialization failing**:
   - Verify that you're calling `configure` before using any other SDK methods
   - Ensure you're providing valid credentials

### Getting Help

If you encounter issues that aren't covered here, please:

1. Check the detailed error message from the SDK
2. Review the API documentation
3. Open an issue on the GitHub repository with a detailed description of the problem

## Next Steps

After successful installation, refer to the main [README.md](README.md) for detailed usage instructions and examples.