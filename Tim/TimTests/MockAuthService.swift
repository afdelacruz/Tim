import Foundation
@testable import Tim

class MockAuthService: AuthServiceProtocol {
    
    // Mock properties
    var mockAccessToken: String?
    var shouldSucceed = true
    var ensureValidTokenCalled = false
    
    // Mock results to return
    var registerResult: Result<AuthResponse, Error> = .success(AuthResponse(success: true))
    var loginResult: Result<AuthResponse, Error> = .success(AuthResponse(success: true))
    var refreshTokenResult: Result<AuthResponse, Error> = .success(AuthResponse(success: true))
    var getCurrentUserResult: Result<User, Error> = .failure(AuthError.unauthorized)
    
    // Delay for testing loading states
    var registerDelay: TimeInterval = 0
    var loginDelay: TimeInterval = 0
    var refreshTokenDelay: TimeInterval = 0
    
    // Tracking calls for verification
    var registerCallCount = 0
    var loginCallCount = 0
    var refreshTokenCallCount = 0
    var getCurrentUserCallCount = 0
    var logoutCallCount = 0
    var refreshAccessTokenCallCount = 0
    var ensureValidAccessTokenCallCount = 0
    
    var lastRegisterEmail: String?
    var lastRegisterPin: String?
    var lastLoginEmail: String?
    var lastLoginPin: String?
    var lastRefreshToken: String?
    
    // MARK: - AuthServiceProtocol Implementation
    
    var accessToken: String? {
        return mockAccessToken
    }
    
    func register(email: String, pin: String) async throws -> AuthResponse {
        registerCallCount += 1
        lastRegisterEmail = email
        lastRegisterPin = pin
        
        if registerDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(registerDelay * 1_000_000_000))
        }
        
        switch registerResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func login(email: String, pin: String) async throws -> AuthResponse {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPin = pin
        
        if loginDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(loginDelay * 1_000_000_000))
        }
        
        switch loginResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func logout() async {
        logoutCallCount += 1
        mockAccessToken = nil
    }
    
    func refreshAccessToken() async throws -> String {
        refreshAccessTokenCallCount += 1
        
        if !shouldSucceed {
            throw AuthError.tokenExpired
        }
        
        let newToken = "refreshed_access_token"
        mockAccessToken = newToken
        return newToken
    }
    
    func ensureValidAccessToken() async throws {
        ensureValidAccessTokenCallCount += 1
        ensureValidTokenCalled = true
        
        if !shouldSucceed {
            throw AuthError.tokenExpired
        }
        
        // If no access token, try to refresh
        if mockAccessToken == nil {
            _ = try await refreshAccessToken()
        }
    }
    
    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        refreshTokenCallCount += 1
        lastRefreshToken = refreshToken
        
        if refreshTokenDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(refreshTokenDelay * 1_000_000_000))
        }
        
        switch refreshTokenResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func getCurrentUser() async throws -> User {
        getCurrentUserCallCount += 1
        
        switch getCurrentUserResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func reset() {
        registerCallCount = 0
        loginCallCount = 0
        refreshTokenCallCount = 0
        getCurrentUserCallCount = 0
        logoutCallCount = 0
        refreshAccessTokenCallCount = 0
        ensureValidAccessTokenCallCount = 0
        ensureValidTokenCalled = false
        
        lastRegisterEmail = nil
        lastRegisterPin = nil
        lastLoginEmail = nil
        lastLoginPin = nil
        lastRefreshToken = nil
        
        mockAccessToken = nil
        shouldSucceed = true
        
        registerResult = .success(AuthResponse(success: true))
        loginResult = .success(AuthResponse(success: true))
        refreshTokenResult = .success(AuthResponse(success: true))
        getCurrentUserResult = .failure(AuthError.unauthorized)
        
        registerDelay = 0
        loginDelay = 0
        refreshTokenDelay = 0
    }
} 