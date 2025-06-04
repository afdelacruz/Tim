import XCTest
@testable import Tim

final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var mockNetworkManager: MockNetworkManager!
    
    override func setUpWithError() throws {
        mockNetworkManager = MockNetworkManager()
        authService = AuthService(networkManager: mockNetworkManager)
    }
    
    override func tearDownWithError() throws {
        authService = nil
        mockNetworkManager = nil
    }
    
    // MARK: - Registration Tests
    
    func testRegister_withValidCredentials_callsAPISuccessfully() async throws {
        // Arrange
        let email = "test@example.com"
        let pin = "1234"
        let expectedResponse = AuthResponse(
            success: true,
            message: "User registered successfully",
            accessToken: nil,
            refreshToken: nil,
            user: nil
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act & Assert
        let response = try await authService.register(email: email, pin: pin)
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "User registered successfully")
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/auth/register")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "POST")
    }
    
    func testRegister_withInvalidEmail_throwsValidationError() async {
        // Arrange
        let invalidEmail = "invalid-email"
        let pin = "1234"
        
        // Act & Assert
        do {
            _ = try await authService.register(email: invalidEmail, pin: pin)
            XCTFail("Expected validation error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.invalidEmail)
        } catch {
            XCTFail("Expected AuthError.invalidEmail, got \(error)")
        }
    }
    
    func testRegister_withInvalidPin_throwsValidationError() async {
        // Arrange
        let email = "test@example.com"
        let invalidPin = "123" // Too short
        
        // Act & Assert
        do {
            _ = try await authService.register(email: email, pin: invalidPin)
            XCTFail("Expected validation error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.invalidPin)
        } catch {
            XCTFail("Expected AuthError.invalidPin, got \(error)")
        }
    }
    
    // MARK: - Login Tests
    
    func testLogin_withValidCredentials_returnsTokens() async throws {
        // Arrange
        let email = "test@example.com"
        let pin = "1234"
        let expectedUser = User(id: "123", email: email, createdAt: Date())
        let expectedResponse = AuthResponse(
            success: true,
            message: nil,
            accessToken: "access_token_123",
            refreshToken: "refresh_token_123",
            user: expectedUser
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await authService.login(email: email, pin: pin)
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.accessToken, "access_token_123")
        XCTAssertEqual(response.refreshToken, "refresh_token_123")
        XCTAssertEqual(response.user?.email, email)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/auth/login")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "POST")
    }
    
    func testLogin_withInvalidCredentials_throwsUnauthorizedError() async {
        // Arrange
        let email = "test@example.com"
        let pin = "9999"
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = AuthError.unauthorized
        
        // Act & Assert
        do {
            _ = try await authService.login(email: email, pin: pin)
            XCTFail("Expected unauthorized error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.unauthorized)
        } catch {
            XCTFail("Expected AuthError.unauthorized, got \(error)")
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshAccessToken_withValidRefreshToken_returnsNewAccessToken() async throws {
        // Arrange
        let expectedToken = "new_access_token"
        
        // Mock the keychain to have a refresh token
        let mockKeychainService = MockKeychainService()
        mockKeychainService.storedRefreshToken = "valid_refresh_token"
        
        let authServiceWithMockKeychain = AuthService(
            networkManager: mockNetworkManager,
            keychainService: mockKeychainService
        )
        
        let expectedResponse = AuthResponse(
            success: true,
            message: nil,
            accessToken: expectedToken,
            refreshToken: nil,
            user: nil
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let newToken = try await authServiceWithMockKeychain.refreshAccessToken()
        
        // Assert
        XCTAssertEqual(newToken, expectedToken)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/auth/refresh-token")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "POST")
    }
    
    func testRefreshAccessToken_withInvalidRefreshToken_throwsUnauthorizedError() async {
        // Arrange
        let mockKeychainService = MockKeychainService()
        mockKeychainService.storedRefreshToken = nil // No refresh token
        
        let authServiceWithMockKeychain = AuthService(
            networkManager: mockNetworkManager,
            keychainService: mockKeychainService
        )
        
        // Act & Assert
        do {
            _ = try await authServiceWithMockKeychain.refreshAccessToken()
            XCTFail("Expected token expired error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.tokenExpired)
        } catch {
            XCTFail("Expected AuthError.tokenExpired, got \(error)")
        }
    }
} 