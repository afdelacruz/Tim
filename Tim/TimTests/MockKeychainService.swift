import Foundation
@testable import Tim

class MockKeychainService: KeychainServiceProtocol {
    
    // Mock storage
    var storedAccessToken: String?
    var storedRefreshToken: String?
    
    // Tracking calls for verification
    var storeAccessTokenCallCount = 0
    var storeRefreshTokenCallCount = 0
    var getAccessTokenCallCount = 0
    var getRefreshTokenCallCount = 0
    var clearTokensCallCount = 0
    
    func storeAccessToken(_ token: String) {
        storeAccessTokenCallCount += 1
        storedAccessToken = token
    }
    
    func storeRefreshToken(_ token: String) {
        storeRefreshTokenCallCount += 1
        storedRefreshToken = token
    }
    
    func getAccessToken() -> String? {
        getAccessTokenCallCount += 1
        return storedAccessToken
    }
    
    func getRefreshToken() -> String? {
        getRefreshTokenCallCount += 1
        return storedRefreshToken
    }
    
    func clearTokens() {
        clearTokensCallCount += 1
        storedAccessToken = nil
        storedRefreshToken = nil
    }
    
    func reset() {
        storedAccessToken = nil
        storedRefreshToken = nil
        storeAccessTokenCallCount = 0
        storeRefreshTokenCallCount = 0
        getAccessTokenCallCount = 0
        getRefreshTokenCallCount = 0
        clearTokensCallCount = 0
    }
} 