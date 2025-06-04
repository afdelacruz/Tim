import XCTest
@testable import Tim

// MARK: - Balance Service Tests
@MainActor
class BalanceServiceTests: XCTestCase {
    var balanceService: BalanceService!
    var mockNetworkManager: MockNetworkManager!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockNetworkManager = MockNetworkManager()
        mockAuthService = MockAuthService()
        balanceService = BalanceService(
            networkManager: mockNetworkManager,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        balanceService = nil
        mockNetworkManager = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    func testFetchCurrentMonthBalance_withValidData_returnsBalanceData() async throws {
        // Given
        let expectedData = MonthlyBalanceData(
            inflow: 1240.0,
            outflow: 890.0,
            month: "December",
            year: 2024
        )
        let mockResponse = BalanceResponse(
            success: true,
            data: expectedData,
            error: nil
        )
        
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = "valid_token"
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockResponse = mockResponse
        
        // When
        let result = try await balanceService.fetchCurrentMonthBalance()
        
        // Then
        XCTAssertTrue(mockAuthService.ensureValidTokenCalled)
        XCTAssertEqual(result.inflow, expectedData.inflow)
        XCTAssertEqual(result.outflow, expectedData.outflow)
        XCTAssertEqual(result.month, expectedData.month)
        XCTAssertEqual(result.year, expectedData.year)
    }
    
    func testFetchCurrentMonthBalance_withZeroBalances_returnsZeroData() async throws {
        // Given
        let expectedData = MonthlyBalanceData(
            inflow: 0.0,
            outflow: 0.0,
            month: "December",
            year: 2024
        )
        let mockResponse = BalanceResponse(
            success: true,
            data: expectedData,
            error: nil
        )
        
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = "valid_token"
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockResponse = mockResponse
        
        // When
        let result = try await balanceService.fetchCurrentMonthBalance()
        
        // Then
        XCTAssertEqual(result.inflow, 0.0)
        XCTAssertEqual(result.outflow, 0.0)
    }
    
    // MARK: - Authentication Error Cases
    func testFetchCurrentMonthBalance_whenNotAuthenticated_throwsNotAuthenticatedError() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = nil // No access token
        
        // When/Then
        do {
            _ = try await balanceService.fetchCurrentMonthBalance()
            XCTFail("Expected BalanceError.notAuthenticated to be thrown")
        } catch let error as BalanceError {
            XCTAssertEqual(error, BalanceError.notAuthenticated)
            XCTAssertTrue(mockAuthService.ensureValidTokenCalled)
        } catch {
            XCTFail("Expected BalanceError.notAuthenticated, got \(error)")
        }
    }
    
    func testFetchCurrentMonthBalance_whenTokenRefreshFails_throwsError() async {
        // Given
        mockAuthService.shouldSucceed = false // Token refresh fails
        mockAuthService.mockAccessToken = "expired_token"
        
        // When/Then
        do {
            _ = try await balanceService.fetchCurrentMonthBalance()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockAuthService.ensureValidTokenCalled)
        }
    }
    
    // MARK: - Network Error Cases
    func testFetchCurrentMonthBalance_whenNetworkFails_throwsNetworkError() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = "valid_token"
        mockNetworkManager.mockError = NetworkError.networkUnavailable
        
        // When/Then
        do {
            _ = try await balanceService.fetchCurrentMonthBalance()
            XCTFail("Expected BalanceError.networkError to be thrown")
        } catch let error as BalanceError {
            if case .networkError(let message) = error {
                XCTAssertTrue(message.contains("connection") || message.contains("network"))
            } else {
                XCTFail("Expected BalanceError.networkError, got \(error)")
            }
        } catch {
            XCTFail("Expected BalanceError.networkError, got \(error)")
        }
    }
    
    // MARK: - API Error Cases
    func testFetchCurrentMonthBalance_whenApiReturnsError_throwsApiError() async {
        // Given
        let errorResponse = ErrorResponse(code: "INSUFFICIENT_DATA", message: "Not enough balance data")
        let mockResponse = BalanceResponse(
            success: false,
            data: nil,
            error: errorResponse
        )
        
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = "valid_token"
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockResponse = mockResponse
        
        // When/Then
        do {
            _ = try await balanceService.fetchCurrentMonthBalance()
            XCTFail("Expected BalanceError.apiError to be thrown")
        } catch let error as BalanceError {
            if case .apiError(let message) = error {
                XCTAssertEqual(message, "Not enough balance data")
            } else {
                XCTFail("Expected BalanceError.apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected BalanceError.apiError, got \(error)")
        }
    }
    
    func testFetchCurrentMonthBalance_whenApiReturnsSuccessButNoData_throwsInvalidResponseError() async {
        // Given
        let mockResponse = BalanceResponse(
            success: true,
            data: nil, // Success but no data
            error: nil
        )
        
        mockAuthService.shouldSucceed = true
        mockAuthService.mockAccessToken = "valid_token"
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockResponse = mockResponse
        
        // When/Then
        do {
            _ = try await balanceService.fetchCurrentMonthBalance()
            XCTFail("Expected BalanceError.invalidResponse to be thrown")
        } catch let error as BalanceError {
            XCTAssertEqual(error, BalanceError.invalidResponse)
        } catch {
            XCTFail("Expected BalanceError.invalidResponse, got \(error)")
        }
    }
    
    // MARK: - Error Description Tests
    func testBalanceError_errorDescriptions_areCorrect() {
        XCTAssertEqual(BalanceError.notAuthenticated.errorDescription, "User not authenticated")
        XCTAssertEqual(BalanceError.networkError("Connection failed").errorDescription, "Network error: Connection failed")
        XCTAssertEqual(BalanceError.apiError("Server error").errorDescription, "API error: Server error")
        XCTAssertEqual(BalanceError.invalidResponse.errorDescription, "Invalid response from server")
    }
} 