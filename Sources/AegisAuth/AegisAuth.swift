import Foundation
import Alamofire
import SwiftyJSON

/**
 * Aegis Auth iOS SDK
 *
 * A comprehensive authentication SDK for iOS applications providing:
 * - Email/Password authentication
 * - WebAuthn/Passkey support
 * - Multi-factor authentication (MFA)
 * - Biometric authentication
 * - OAuth/SSO integration
 * - JWT token management with automatic refresh
 */
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public class AegisAuth {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL: String
    private let session: Session
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?
    
    // MARK: - Initialization
    
    public init(apiKey: String, baseURL: String = "https://05card1j5b.execute-api.ap-south-1.amazonaws.com/prod") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let interceptor = AegisInterceptor(apiKey: apiKey)
        self.session = Session(configuration: configuration, interceptor: interceptor)
    }
    
    // MARK: - Authentication Methods
    
    /**
     * Register a new user with email and password
     */
    public func register(
        email: String,
        password: String,
        firstName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (Result<User, AegisError>) -> Void
    ) {
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "firstName": firstName as Any,
            "lastName": lastName as Any
        ].compactMapValues { $0 }
        
        session.request(
            "\(baseURL)/auth/register",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).responseJSON { response in
            self.handleAuthResponse(response: response, completion: completion)
        }
    }
    
    /**
     * Login with email and password
     */
    public func login(
        email: String,
        password: String,
        completion: @escaping (Result<User, AegisError>) -> Void
    ) {
        let parameters = [
            "email": email,
            "password": password
        ]
        
        session.request(
            "\(baseURL)/auth/login",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).responseJSON { response in
            self.handleAuthResponse(response: response, completion: completion)
        }
    }
    
    /**
     * Logout current user
     */
    public func logout(completion: @escaping (Result<Void, AegisError>) -> Void) {
        guard let token = accessToken else {
            clearTokens()
            completion(.success(()))
            return
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        session.request(
            "\(baseURL)/auth/logout",
            method: .post,
            headers: headers
        ).responseJSON { response in
            self.clearTokens()
            
            switch response.result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.networkError(error.localizedDescription)))
            }
        }
    }
    
    /**
     * Get current user profile
     */
    public func getCurrentUser(completion: @escaping (Result<User, AegisError>) -> Void) {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                self?.makeAuthenticatedRequest(
                    endpoint: "/auth/profile",
                    method: .get,
                    completion: { (result: Result<User, AegisError>) in
                        completion(result)
                    }
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Initiate WebAuthn registration
     */
    public func initiateWebAuthnRegistration(completion: @escaping (Result<WebAuthnChallenge, AegisError>) -> Void) {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                self?.makeAuthenticatedRequest(
                    endpoint: "/auth/webauthn/register/initiate",
                    method: .post,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Complete WebAuthn registration
     */
    public func completeWebAuthnRegistration(
        credential: String,
        completion: @escaping (Result<Void, AegisError>) -> Void
    ) {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                let parameters = ["credential": credential]
                self?.makeAuthenticatedRequest(
                    endpoint: "/auth/webauthn/register/complete",
                    method: .post,
                    parameters: parameters,
                    completion: { (result: Result<EmptyResponse, AegisError>) in
                        switch result {
                        case .success:
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Enable MFA for current user
     */
    public func enableMFA(completion: @escaping (Result<MFASetup, AegisError>) -> Void) {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                self?.makeAuthenticatedRequest(
                    endpoint: "/auth/mfa/enable",
                    method: .post,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Verify MFA token
     */
    public func verifyMFA(token: String, completion: @escaping (Result<Void, AegisError>) -> Void) {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                let parameters = ["token": token]
                self?.makeAuthenticatedRequest(
                    endpoint: "/auth/mfa/verify",
                    method: .post,
                    parameters: parameters,
                    completion: { (result: Result<EmptyResponse, AegisError>) in
                        switch result {
                        case .success:
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Check if user is authenticated
     */
    public func isAuthenticated() -> Bool {
        guard let token = accessToken,
              let expiresAt = tokenExpiresAt else {
            return false
        }
        return Date() < expiresAt
    }
    
    // MARK: - Private Methods
    
    private func handleAuthResponse(
        response: AFDataResponse<Any>,
        completion: @escaping (Result<User, AegisError>) -> Void
    ) {
        switch response.result {
        case .success(let value):
            let json = JSON(value)
            
            if json["success"].boolValue {
                let data = json["data"]
                
                // Store tokens
                let accessToken = data["accessToken"].stringValue
                let refreshToken = data["refreshToken"].stringValue
                let expiresIn = data["expiresIn"].doubleValue
                
                storeTokens(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expiresIn
                )
                
                // Parse user
                let userData = data["user"]
                let user = User(
                    id: userData["id"].stringValue,
                    email: userData["email"].stringValue,
                    firstName: userData["firstName"].string,
                    lastName: userData["lastName"].string,
                    emailVerified: userData["emailVerified"].boolValue,
                    mfaEnabled: userData["mfaEnabled"].boolValue,
                    createdAt: userData["createdAt"].stringValue
                )
                
                completion(.success(user))
            } else {
                let message = json["message"].stringValue
                completion(.failure(.authenticationFailed(message)))
            }
            
        case .failure(let error):
            completion(.failure(.networkError(error.localizedDescription)))
        }
    }
    
    private func makeAuthenticatedRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, AegisError>) -> Void
    ) {
        guard let token = accessToken else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        session.request(
            "\(baseURL)\(endpoint)",
            method: method,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        ).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                
                if json["success"].boolValue {
                    do {
                        let data = try json["data"].rawData()
                        let result = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(result))
                    } catch {
                        completion(.failure(.decodingError(error.localizedDescription)))
                    }
                } else {
                    let message = json["message"].stringValue
                    completion(.failure(.apiError(message)))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error.localizedDescription)))
            }
        }
    }
    
    private func ensureValidToken(completion: @escaping (Result<Void, AegisError>) -> Void) {
        guard let expiresAt = tokenExpiresAt else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        if Date() >= expiresAt {
            refreshAccessToken(completion: completion)
        } else {
            completion(.success(()))
        }
    }
    
    private func refreshAccessToken(completion: @escaping (Result<Void, AegisError>) -> Void) {
        guard let refreshToken = refreshToken else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        let parameters = ["refreshToken": refreshToken]
        
        session.request(
            "\(baseURL)/auth/refresh",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                
                if json["success"].boolValue {
                    let data = json["data"]
                    let accessToken = data["accessToken"].stringValue
                    let refreshToken = data["refreshToken"].stringValue
                    let expiresIn = data["expiresIn"].doubleValue
                    
                    self.storeTokens(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: expiresIn
                    )
                    
                    completion(.success(()))
                } else {
                    self.clearTokens()
                    completion(.failure(.notAuthenticated))
                }
                
            case .failure(let error):
                self.clearTokens()
                completion(.failure(.networkError(error.localizedDescription)))
            }
        }
    }
    
    private func storeTokens(accessToken: String, refreshToken: String, expiresIn: Double) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiresAt = Date().addingTimeInterval(expiresIn)
    }
    
    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
    }
}

// MARK: - Data Models

public struct User: Codable {
    public let id: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let emailVerified: Bool
    public let mfaEnabled: Bool
    public let createdAt: String
}

public struct WebAuthnChallenge: Codable {
    public let challenge: String
    public let timeout: Int
    public let rpId: String
    public let allowCredentials: [String]
}

public struct MFASetup: Codable {
    public let secret: String
    public let qrCode: String
    public let backupCodes: [String]
}

private struct EmptyResponse: Codable {}

// MARK: - Error Types

public enum AegisError: Error, LocalizedError {
    case networkError(String)
    case authenticationFailed(String)
    case notAuthenticated
    case apiError(String)
    case decodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .notAuthenticated:
            return "User not authenticated"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

// MARK: - Request Interceptor

private class AegisInterceptor: RequestInterceptor {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        urlRequest.setValue("AegisAuth-iOS/1.0.0", forHTTPHeaderField: "User-Agent")
        completion(.success(urlRequest))
    }
}