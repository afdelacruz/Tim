import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var pin: String = ""
    @Published var isLoading: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    // MARK: - Computed Properties
    var isLoginButtonEnabled: Bool {
        isValidEmail(email) && isValidPin(pin)
    }
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let keychainService: KeychainServiceProtocol
    
    // MARK: - Initialization
    init(
        authService: AuthServiceProtocol = AuthService(),
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.authService = authService
        self.keychainService = keychainService
    }
    
    // MARK: - Public Methods
    
    func login() async {
        guard isLoginButtonEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authService.login(email: email, pin: pin)
            
            if response.success {
                // Store tokens securely
                if let accessToken = response.accessToken {
                    keychainService.storeAccessToken(accessToken)
                    
                    // ALSO store in shared UserDefaults for widget access
                    if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") {
                        sharedDefaults.set(accessToken, forKey: "access_token")
                        print("🔑 LoginViewModel: Stored access token in shared UserDefaults during login (length: \(accessToken.count))")
                        
                        // Verify it was stored
                        if let storedToken = sharedDefaults.string(forKey: "access_token") {
                            print("✅ LoginViewModel: Verified token storage - retrieved length: \(storedToken.count)")
                        } else {
                            print("❌ LoginViewModel: Failed to retrieve token after storing!")
                        }
                        
                        // Force synchronization
                        sharedDefaults.synchronize()
                        print("🔄 LoginViewModel: Forced UserDefaults synchronization")
                        
                        // Debug: List all keys to see what's actually in there
                        let allKeys = sharedDefaults.dictionaryRepresentation().keys
                        print("🔍 LoginViewModel: All keys in shared UserDefaults after storage: \(Array(allKeys))")
                        
                        // Double-check the access_token key specifically
                        if allKeys.contains("access_token") {
                            print("✅ LoginViewModel: access_token key confirmed in shared UserDefaults")
                        } else {
                            print("❌ LoginViewModel: access_token key NOT found in shared UserDefaults after storage!")
                        }
                    } else {
                        print("❌ LoginViewModel: Failed to get shared UserDefaults during login")
                    }
                }
                if let refreshToken = response.refreshToken {
                    keychainService.storeRefreshToken(refreshToken)
                }
                
                // Update authentication state
                currentUser = response.user
                isAuthenticated = true
                
                // Clear form
                clearForm()
            } else {
                errorMessage = response.message ?? "Login failed"
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func register() async {
        guard isLoginButtonEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authService.register(email: email, pin: pin)
            
            if response.success {
                // Registration successful - user can now login
                // Note: We don't automatically authenticate after registration
                clearForm()
            } else {
                errorMessage = response.message ?? "Registration failed"
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func checkExistingAuth() async {
        // Check if we have stored tokens
        guard let accessToken = keychainService.getAccessToken(),
              !accessToken.isEmpty else {
            return
        }
        
        do {
            // Try to get current user with stored token
            let user = try await authService.getCurrentUser()
            currentUser = user
            isAuthenticated = true
            
            // ALSO store in shared UserDefaults for widget access
            if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") {
                sharedDefaults.set(accessToken, forKey: "access_token")
                print("🔑 LoginViewModel: Stored access token in shared UserDefaults (length: \(accessToken.count))")
            } else {
                print("❌ LoginViewModel: Failed to get shared UserDefaults")
            }
        } catch {
            // Token might be expired or invalid, clear it
            keychainService.clearTokens()
            
            // ALSO clear from shared UserDefaults
            if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") {
                sharedDefaults.removeObject(forKey: "access_token")
            }
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        keychainService.clearTokens()
        
        // ALSO clear from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") {
            sharedDefaults.removeObject(forKey: "access_token")
        }
        
        clearForm()
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func clearForm() {
        email = ""
        pin = ""
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPin(_ pin: String) -> Bool {
        return pin.count == 4 && pin.allSatisfy({ $0.isNumber })
    }
} 