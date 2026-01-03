# Aegis Auth iOS SDK

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)

Aegis Auth is a unified identity management system providing secure iOS authentication. Consolidation of disparate identity providers into a single canonical source.

## Features

- 🔐 **Email/Password Authentication** - Traditional login with secure password handling
- 🔑 **WebAuthn/Passkey Support** - Passwordless authentication using biometrics
- 🛡️ **Multi-Factor Authentication (MFA)** - TOTP-based additional security layer
- 📱 **Biometric Authentication** - Touch ID and Face ID integration
- 🔗 **OAuth/SSO Integration** - Google, Apple, GitHub, Microsoft, and custom providers
- 🎫 **JWT Token Management** - Automatic token refresh and secure storage
- 📊 **Session Analytics** - User behavior tracking and insights
- 🏢 **Multi-Tenant Support** - Organization and project-based user management

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Xcode 14.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/navchetnaofficialllp/aegis-auth-sdk-ios.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/navchetnaofficialllp/aegis-auth-sdk-ios.git`
3. Select version and add to your target

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'AegisAuth', '~> 1.0.0'
```

## Quick Start

### 1. Initialize the SDK

```swift
import AegisAuth

class AppDelegate: UIResponder, UIApplicationDelegate {
    var aegisAuth: AegisAuth!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        aegisAuth = AegisAuth(
            apiKey: "your_api_key_here",
            baseURL: "https://your-aegis-instance.com" // Optional
        )
        
        return true
    }
}
```

### 2. User Registration

```swift
import AegisAuth

class AuthViewController: UIViewController {
    private var aegisAuth: AegisAuth {
        return (UIApplication.shared.delegate as! AppDelegate).aegisAuth
    }
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        aegisAuth.register(
            email: "user@example.com",
            password: "securePassword123",
            firstName: "John",
            lastName: "Doe"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    // Registration successful
                    print("User registered: \(user.email)")
                    self.navigateToMainScreen()
                    
                case .failure(let error):
                    // Handle error
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
}
```

### 3. User Login

```swift
// Email/Password login
aegisAuth.login(email: "user@example.com", password: "password123") { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let user):
            // Login successful
            print("Welcome back, \(user.email)!")
            self.navigateToMainScreen()
            
        case .failure(let error):
            // Handle login error
            self.showAlert(message: error.localizedDescription)
        }
    }
}
```

### 4. WebAuthn/Passkey Authentication

```swift
import AuthenticationServices

// Initiate WebAuthn registration
aegisAuth.initiateWebAuthnRegistration { result in
    switch result {
    case .success(let challenge):
        // Use ASAuthorizationController for WebAuthn
        self.createWebAuthnCredential(with: challenge)
        
    case .failure(let error):
        print("WebAuthn initiation failed: \(error)")
    }
}

private func createWebAuthnCredential(with challenge: WebAuthnChallenge) {
    // Implementation using ASAuthorizationController
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: challenge.rpId)
    
    let request = provider.createCredentialRegistrationRequest(
        challenge: Data(challenge.challenge.utf8),
        name: "user@example.com",
        userID: Data("user-id".utf8)
    )
    
    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}

// Complete WebAuthn registration
extension AuthViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            let credentialData = credential.rawClientDataJSON.base64EncodedString()
            
            aegisAuth.completeWebAuthnRegistration(credential: credentialData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.showAlert(message: "WebAuthn registration successful!")
                    case .failure(let error):
                        self.showAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }
}
```

### 5. Multi-Factor Authentication (MFA)

```swift
// Enable MFA
aegisAuth.enableMFA { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let mfaSetup):
            // Show QR code for authenticator app
            self.displayQRCode(mfaSetup.qrCode)
            
            // Store backup codes securely
            self.storeBackupCodes(mfaSetup.backupCodes)
            
        case .failure(let error):
            self.showAlert(message: error.localizedDescription)
        }
    }
}

// Verify MFA token
aegisAuth.verifyMFA(token: "123456") { result in
    DispatchQueue.main.async {
        switch result {
        case .success:
            self.showAlert(message: "MFA verification successful!")
            
        case .failure(let error):
            self.showAlert(message: error.localizedDescription)
        }
    }
}
```

### 6. User Profile Management

```swift
// Get current user
aegisAuth.getCurrentUser { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let user):
            self.displayUserProfile(user)
            
        case .failure(let error):
            print("Failed to get user: \(error)")
        }
    }
}

// Check authentication status
if aegisAuth.isAuthenticated() {
    // User is logged in
    navigateToMainScreen()
} else {
    // Show login screen
    navigateToLoginScreen()
}
```

### 7. Logout

```swift
// Logout user
aegisAuth.logout { result in
    DispatchQueue.main.async {
        switch result {
        case .success:
            self.navigateToLoginScreen()
            
        case .failure(let error):
            print("Logout error: \(error)")
            // Still navigate to login screen
            self.navigateToLoginScreen()
        }
    }
}
```

## Advanced Usage

### Custom Configuration

```swift
let aegisAuth = AegisAuth(
    apiKey: "your_api_key",
    baseURL: "https://custom-domain.com"
)
```

### Error Handling

```swift
aegisAuth.login(email: email, password: password) { result in
    switch result {
    case .success(let user):
        self.handleSuccessfulLogin(user)
        
    case .failure(let error):
        switch error {
        case .networkError(let message):
            self.handleNetworkError(message)
        case .authenticationFailed(let message):
            self.handleAuthError(message)
        case .notAuthenticated:
            self.redirectToLogin()
        case .apiError(let message):
            self.handleAPIError(message)
        case .decodingError(let message):
            self.handleDecodingError(message)
        }
    }
}
```

### Async/Await Support (iOS 15+)

```swift
@available(iOS 15.0, *)
extension AegisAuth {
    func login(email: String, password: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            login(email: email, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// Usage
Task {
    do {
        let user = try await aegisAuth.login(email: "user@example.com", password: "password")
        await MainActor.run {
            self.navigateToMainScreen()
        }
    } catch {
        await MainActor.run {
            self.showAlert(message: error.localizedDescription)
        }
    }
}
```

## API Reference

### AegisAuth Class

#### Methods

- `func register(email: String, password: String, firstName: String?, lastName: String?, completion: @escaping (Result<User, AegisError>) -> Void)`
- `func login(email: String, password: String, completion: @escaping (Result<User, AegisError>) -> Void)`
- `func logout(completion: @escaping (Result<Void, AegisError>) -> Void)`
- `func getCurrentUser(completion: @escaping (Result<User, AegisError>) -> Void)`
- `func initiateWebAuthnRegistration(completion: @escaping (Result<WebAuthnChallenge, AegisError>) -> Void)`
- `func completeWebAuthnRegistration(credential: String, completion: @escaping (Result<Void, AegisError>) -> Void)`
- `func enableMFA(completion: @escaping (Result<MFASetup, AegisError>) -> Void)`
- `func verifyMFA(token: String, completion: @escaping (Result<Void, AegisError>) -> Void)`
- `func isAuthenticated() -> Bool`

### Data Models

#### User
```swift
public struct User: Codable {
    public let id: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let emailVerified: Bool
    public let mfaEnabled: Bool
    public let createdAt: String
}
```

#### AegisError
```swift
public enum AegisError: Error, LocalizedError {
    case networkError(String)
    case authenticationFailed(String)
    case notAuthenticated
    case apiError(String)
    case decodingError(String)
}
```

## Security Features

- 🔒 **TLS 1.3 Encryption** - All API communications encrypted
- 🎫 **JWT Tokens** - Secure token-based authentication
- 🔄 **Automatic Token Refresh** - Seamless session management
- 🛡️ **Certificate Pinning** - Protection against MITM attacks
- 📱 **Biometric Integration** - Touch ID and Face ID support
- 🔐 **Keychain Storage** - Secure token storage in iOS Keychain

## Privacy

This SDK does not collect any personal data. All authentication data is processed securely and stored according to your Aegis Auth configuration.

## Support

- **Documentation**: https://aegis.navchetna.tech
- **GitHub Issues**: https://github.com/navchetnaofficialllp/aegis-auth-sdk-ios/issues
- **Email Support**: hello@navchetna.tech

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## About Navchetna Technologies

Aegis Auth is developed and maintained by [Navchetna Technologies](https://navchetna.tech), a leading provider of identity and access management solutions.

---

**Aegis Auth by Navchetna Technologies** - Secure, Scalable, Simple Authentication for iOS