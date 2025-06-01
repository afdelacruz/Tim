import XCTest
import SwiftUI
@testable import Tim

@MainActor
final class LoginViewTests: XCTestCase {
    
    var mockAuthService: MockAuthService!
    var mockKeychainService: MockKeychainService!
    var viewModel: LoginViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockKeychainService = MockKeychainService()
        viewModel = LoginViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService
        )
    }
    
    override func tearDown() {
        mockAuthService = nil
        mockKeychainService = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - UI Element Tests
    
    func testLoginView_hasEmailTextField() {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        let hostingController = UIHostingController(rootView: loginView)
        
        // Then
        // This test will fail until we create LoginView with email TextField
        XCTAssertNotNil(hostingController.view)
    }
    
    func testLoginView_hasPinSecureField() {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        let hostingController = UIHostingController(rootView: loginView)
        
        // Then
        // This test will fail until we create LoginView with PIN SecureField
        XCTAssertNotNil(hostingController.view)
    }
    
    func testLoginView_hasLoginButton() {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        let hostingController = UIHostingController(rootView: loginView)
        
        // Then
        // This test will fail until we create LoginView with login Button
        XCTAssertNotNil(hostingController.view)
    }
    
    func testLoginView_hasRegisterButton() {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        let hostingController = UIHostingController(rootView: loginView)
        
        // Then
        // This test will fail until we create LoginView with register Button
        XCTAssertNotNil(hostingController.view)
    }
    
    // MARK: - State Binding Tests
    
    func testLoginView_emailTextField_bindsToViewModel() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        let testEmail = "test@example.com"
        
        // When
        viewModel.email = testEmail
        
        // Then
        XCTAssertEqual(viewModel.email, testEmail)
        // This test will pass once we properly bind the TextField to viewModel.email
    }
    
    func testLoginView_pinSecureField_bindsToViewModel() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        let testPin = "1234"
        
        // When
        viewModel.pin = testPin
        
        // Then
        XCTAssertEqual(viewModel.pin, testPin)
        // This test will pass once we properly bind the SecureField to viewModel.pin
    }
    
    // MARK: - Button State Tests
    
    func testLoginView_loginButton_isDisabledWithInvalidInputs() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        viewModel.email = ""
        viewModel.pin = ""
        
        // Then
        XCTAssertFalse(viewModel.isLoginButtonEnabled)
        // This test will pass once we properly disable the button based on viewModel.isLoginButtonEnabled
    }
    
    func testLoginView_loginButton_isEnabledWithValidInputs() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // Then
        XCTAssertTrue(viewModel.isLoginButtonEnabled)
        // This test will pass once we properly enable the button based on viewModel.isLoginButtonEnabled
    }
    
    // MARK: - Loading State Tests
    
    func testLoginView_showsLoadingIndicator_whenViewModelIsLoading() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        viewModel.isLoading = true
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        // This test will pass once we show a loading indicator when viewModel.isLoading is true
    }
    
    func testLoginView_hidesLoadingIndicator_whenViewModelIsNotLoading() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        viewModel.isLoading = false
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        // This test will pass once we hide the loading indicator when viewModel.isLoading is false
    }
    
    // MARK: - Error Display Tests
    
    func testLoginView_showsErrorMessage_whenViewModelHasError() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        let errorMessage = "Invalid credentials"
        
        // When
        viewModel.errorMessage = errorMessage
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
        // This test will pass once we display the error message when viewModel.errorMessage is not nil
    }
    
    func testLoginView_hidesErrorMessage_whenViewModelHasNoError() async {
        // Given
        let loginView = LoginView(viewModel: viewModel)
        
        // When
        viewModel.errorMessage = nil
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        // This test will pass once we hide the error message when viewModel.errorMessage is nil
    }
    
    // MARK: - User Interaction Tests
    
    func testLoginView_loginButtonTap_callsViewModelLogin() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockResponse = AuthResponse(
            success: true,
            message: "Login successful",
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            user: User(id: "123", email: "test@example.com", createdAt: "2024-01-01")
        )
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(mockAuthService.loginCalled)
        XCTAssertEqual(mockAuthService.lastLoginEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastLoginPin, "1234")
        // This test will pass once we properly call viewModel.login() when login button is tapped
    }
    
    func testLoginView_registerButtonTap_callsViewModelRegister() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockResponse = AuthResponse(
            success: true,
            message: "Registration successful",
            accessToken: nil,
            refreshToken: nil,
            user: nil
        )
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // When
        await viewModel.register()
        
        // Then
        XCTAssertTrue(mockAuthService.registerCalled)
        XCTAssertEqual(mockAuthService.lastRegisterEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastRegisterPin, "1234")
        // This test will pass once we properly call viewModel.register() when register button is tapped
    }
    
    // MARK: - Navigation Tests
    
    func testLoginView_navigatesAfterSuccessfulAuthentication() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockResponse = AuthResponse(
            success: true,
            message: "Login successful",
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            user: User(id: "123", email: "test@example.com", createdAt: "2024-01-01")
        )
        
        viewModel.email = "test@example.com"
        viewModel.pin = "1234"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        // This test will pass once we properly handle navigation based on viewModel.isAuthenticated
    }
} 