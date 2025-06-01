import Foundation
import Security

protocol KeychainServiceProtocol {
    func storeAccessToken(_ token: String)
    func storeRefreshToken(_ token: String)
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func clearTokens()
}

class KeychainService: KeychainServiceProtocol {
    
    static let shared = KeychainService()
    
    private let accessTokenKey = "tim_access_token"
    private let refreshTokenKey = "tim_refresh_token"
    private let service = "com.tim.app"
    
    private init() {}
    
    func storeAccessToken(_ token: String) {
        store(token, forKey: accessTokenKey)
    }
    
    func storeRefreshToken(_ token: String) {
        store(token, forKey: refreshTokenKey)
    }
    
    func getAccessToken() -> String? {
        return retrieve(forKey: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return retrieve(forKey: refreshTokenKey)
    }
    
    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }
    
    // MARK: - Private Methods
    
    private func store(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain store error for key \(key): \(status)")
        }
    }
    
    private func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Keychain delete error for key \(key): \(status)")
        }
    }
} 