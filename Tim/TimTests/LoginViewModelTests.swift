import XCTest
@testable import Tim

@MainActor
final class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    var mockAuthService: MockAuthService!
    var mockKeychainService: MockKeychainService!
    
    override func setUpWithError() throws {
        mockAuthService = MockAuthService()
        mockKeychainService = MockKeychainService()
        viewModel = LoginViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockAuthService = nil
        mockKeychainService = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_hasCorrectDefaults() {
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.pin, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoginButtonEnabled)
    }
    
    // MARK: - Input Validation Tests
    
    func testIsLoginButtonEnabled_withValidInputs_returnsTrue() {
        // Arrange
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // Act & Assert
        XCTAssertTrue(viewModel.isLoginButtonEnabled)
    }
    
    func testIsLoginButtonEnabled_withInvalidEmail_returnsFalse() {
        // Arrange
        viewModel.email = "invalid-email"
        viewModel.pin = "1234"
        
        // Act & Assert
        XCTAssertFalse(viewModel.isLoginButtonEnabled)
    }
    
    func testIsLoginButtonEnabled_withInvalidPin_returnsFalse() {
        // Arrange
        viewModel.email = "test@example.com"
        viewModel.pin = "123" // Too short
        
        // Act & Assert
        XCTAssertFalse(viewModel.isLoginButtonEnabled)
    }
    
    func testIsLoginButtonEnabled_withEmptyInputs_returnsFalse() {
        // Arrange
        viewModel.email = ""
        viewModel.pin = ""
        
        // Act & Assert
        XCTAssertFalse(viewModel.isLoginButtonEnabled)
    }
    
    // MARK: - Login Tests
    
    func testLogin_withValidCredentials_setsAuthenticatedState() async {
        // Arrange
        let expectedUser = User(id: "123", email: "test@example.com", createdAt: Date())
        let authResponse = AuthResponse(
            success: true,
            message: nil,
            accessToken: "access_token",
            refreshToken: "refresh_token",
            user: expectedUser
        )
        mockAuthService.loginResult = .success(authResponse)
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // Act
        await viewModel.login()
        
        // Assert
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.currentUser?.email, "test@example.com")
        
        // Verify tokens were stored
        XCTAssertEqual(mockKeychainService.storedAccessToken, "access_token")
        XCTAssertEqual(mockKeychainService.storedRefreshToken, "refresh_token")
    }
    
    func testLogin_withInvalidCredentials_showsError() async {
        // Arrange
        mockAuthService.loginResult = .failure(AuthError.unauthorized)
        
        viewModel.email = "test@example.com"
        viewModel.pin = "9999"
        
        // Act
        await viewModel.login()
        
        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Invalid email or PIN")
        XCTAssertNil(viewModel.currentUser)
        
        // Verify no tokens were stored
        XCTAssertNil(mockKeychainService.storedAccessToken)
        XCTAssertNil(mockKeychainService.storedRefreshToken)
    }
    
    func testLogin_withNetworkError_showsError() async {
        // Arrange
        mockAuthService.loginResult = .failure(AuthError.networkError)
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // Act
        await viewModel.login()
        
        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Network connection error. Please try again.")
        XCTAssertNil(viewModel.currentUser)
    }
    
    func testLogin_setsLoadingStateDuringCall() async {
        // Arrange
        mockAuthService.loginDelay = 0.1 // Small delay to test loading state
        mockAuthService.loginResult = .success(AuthResponse(success: true))
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // Act
        let loginTask = Task {
            await viewModel.login()
        }
        
        // Assert loading state is set immediately
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        await loginTask.value
        
        // Assert loading state is cleared
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Registration Tests
    
    func testRegister_withValidCredentials_setsAuthenticatedState() async {
        // Arrange
        let authResponse = AuthResponse(
            success: true,
            message: "User registered successfully"
        )
        mockAuthService.registerResult = .success(authResponse)
        
        viewModel.email = "newuser@example.com"
        viewModel.pin = "5678"
        
        // Act
        await viewModel.register()
        
        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        // Note: Registration doesn't immediately authenticate, user needs to login
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testRegister_withExistingEmail_showsError() async {
        // Arrange
        mockAuthService.registerResult = .failure(AuthError.unauthorized) // Assuming 409 maps to unauthorized
        
        viewModel.email = "existing@example.com"
        viewModel.pin = "1234"
        
        // Act
        await viewModel.register()
        
        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Invalid email or PIN")
    }
    
    // MARK: - Auto-Login Tests
    
    func testCheckExistingAuth_withValidTokens_setsAuthenticatedState() async {
        // Arrange
        mockKeychainService.storedAccessToken = "valid_access_token"
        mockKeychainService.storedRefreshToken = "valid_refresh_token"
        
        let expectedUser = User(id: "123", email: "test@example.com", createdAt: Date())
        mockAuthService.getCurrentUserResult = .success(expectedUser)
        
        // Act
        await viewModel.checkExistingAuth()
        
        // Assert
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.email, "test@example.com")
    }
    
    func testCheckExistingAuth_withNoTokens_remainsUnauthenticated() async {
        // Arrange
        mockKeychainService.storedAccessToken = nil
        mockKeychainService.storedRefreshToken = nil
        
        // Act
        await viewModel.checkExistingAuth()
        
        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
    
    // MARK: - Logout Tests
    
    func testLogout_clearsAuthenticationState() {
        // Arrange
        viewModel.isAuthenticated = true
        viewModel.currentUser = User(id: "123", email: "test@example.com", createdAt: Date())
        mockKeychainService.storedAccessToken = "token"
        mockKeychainService.storedRefreshToken = "refresh"
        
        // Act
        viewModel.logout()
        
        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.pin, "")
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify tokens were cleared
        XCTAssertNil(mockKeychainService.storedAccessToken)
        XCTAssertNil(mockKeychainService.storedRefreshToken)
    }
} 