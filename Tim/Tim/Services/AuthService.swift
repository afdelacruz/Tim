import Foundation

protocol AuthServiceProtocol {
    var accessToken: String? { get }
    func register(email: String, pin: String) async throws -> AuthResponse
    func login(email: String, pin: String) async throws -> AuthResponse
    func logout() async
    func refreshAccessToken() async throws -> String
    func ensureValidAccessToken() async throws
}

class AuthService: AuthServiceProtocol {
    
    private let networkManager: NetworkManagerProtocol
    private let keychainService: KeychainServiceProtocol
    
    var accessToken: String? {
        return keychainService.getAccessToken()
    }
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkManager = networkManager
        self.keychainService = keychainService
    }
    
    func register(email: String, pin: String) async throws -> AuthResponse {
        // Validate input
        try validateEmail(email)
        try validatePin(pin)
        
        guard let url = NetworkManager.shared.buildURL(path: "/api/auth/register") else {
            throw NetworkError.invalidURL
        }
        
        let requestBody = RegisterRequest(email: email, pin: pin)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: AuthResponse = try await networkManager.request(
                url: url,
                method: .POST,
                body: bodyData,
                headers: nil
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        }
    }
    
    func login(email: String, pin: String) async throws -> AuthResponse {
        // Validate input
        try validateEmail(email)
        try validatePin(pin)
        
        guard let url = NetworkManager.shared.buildURL(path: "/api/auth/login") else {
            throw NetworkError.invalidURL
        }
        
        let requestBody = LoginRequest(email: email, pin: pin)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: AuthResponse = try await networkManager.request(
                url: url,
                method: .POST,
                body: bodyData,
                headers: nil
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        }
    }
    

    
    // MARK: - Private Methods
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePin(_ pin: String) throws {
        if pin.count != 4 || !pin.allSatisfy({ $0.isNumber }) {
            throw AuthError.invalidPin
        }
    }
    

    
    private func mapNetworkError(_ error: NetworkError) -> AuthError {
        switch error {
        case .httpError(401):
            return .unauthorized
        case .httpError(409):
            return .emailAlreadyExists
        case .networkUnavailable:
            return .networkError
        case .decodingError:
            return .decodingError
        default:
            return .networkError
        }
    }
    
    func logout() async {
        keychainService.deleteAccessToken()
        keychainService.deleteRefreshToken()
    }
    
    func refreshAccessToken() async throws -> String {
        guard let refreshToken = keychainService.getRefreshToken() else {
            throw AuthError.tokenExpired
        }
        
        let response = try await refreshTokenRequest(refreshToken: refreshToken)
        
        if let newAccessToken = response.accessToken {
            keychainService.saveAccessToken(newAccessToken)
            return newAccessToken
        } else {
            throw AuthError.tokenExpired
        }
    }
    
    func ensureValidAccessToken() async throws {
        // For now, we'll assume the token is valid if it exists
        // In a production app, you'd want to check expiration
        if accessToken == nil {
            _ = try await refreshAccessToken()
        }
    }
    
    private func refreshTokenRequest(refreshToken: String) async throws -> AuthResponse {
        guard let url = NetworkManager.shared.buildURL(path: "/api/auth/refresh-token") else {
            throw NetworkError.invalidURL
        }
        
        let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: AuthResponse = try await networkManager.request(
                url: url,
                method: .POST,
                body: bodyData,
                headers: nil
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        }
    }
}

// MARK: - Shared Instance
extension AuthService {
    static let shared = AuthService()
}

// MARK: - Request Models

private struct RegisterRequest: Codable {
    let email: String
    let pin: String
}

private struct LoginRequest: Codable {
    let email: String
    let pin: String
}

private struct RefreshTokenRequest: Codable {
    let refreshToken: String
} 