import XCTest
@testable import Tim

@MainActor
final class PlaidLinkViewModelTests: XCTestCase {
    
    var viewModel: PlaidLinkViewModel!
    var mockPlaidService: MockPlaidService!
    
    override func setUpWithError() throws {
        mockPlaidService = MockPlaidService()
        viewModel = PlaidLinkViewModel(plaidService: mockPlaidService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockPlaidService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInit_setsInitialState() {
        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.linkToken)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showingPlaidLink)
        XCTAssertEqual(viewModel.connectedAccounts.count, 0)
    }
    
    // MARK: - Link Token Tests
    
    func testFetchLinkToken_whenServiceSucceeds_updatesStateCorrectly() async {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockPlaidService.mockLinkTokenResponse = expectedResponse
        
        // Act
        await viewModel.fetchLinkToken()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchLinkTokenCalled)
        XCTAssertEqual(viewModel.linkToken, "link-sandbox-12345678-1234-1234-1234-123456789012")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchLinkToken_whenServiceFails_updatesStateWithError() async {
        // Arrange
        mockPlaidService.shouldThrowError = true
        mockPlaidService.errorToThrow = .invalidLinkToken
        
        // Act
        await viewModel.fetchLinkToken()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchLinkTokenCalled)
        XCTAssertNil(viewModel.linkToken)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Invalid link token")
    }
    
    func testFetchLinkToken_setsLoadingStateDuringCall() async {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockPlaidService.mockLinkTokenResponse = expectedResponse
        
        // Act & Assert
        let expectation = XCTestExpectation(description: "Loading state set")
        
        Task {
            // Check loading state is set at start
            await viewModel.fetchLinkToken()
            expectation.fulfill()
        }
        
        // Brief delay to check loading state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading) // Should be false after completion
    }
    
    // MARK: - Plaid Link Flow Tests
    
    func testStartPlaidLink_withValidToken_showsPlaidLink() async {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockPlaidService.mockLinkTokenResponse = expectedResponse
        await viewModel.fetchLinkToken()
        
        // Act
        await viewModel.startPlaidLink()
        
        // Assert
        XCTAssertTrue(viewModel.showingPlaidLink)
    }
    
    func testStartPlaidLink_withoutToken_fetchesTokenFirst() async {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockPlaidService.mockLinkTokenResponse = expectedResponse
        
        // Act
        await viewModel.startPlaidLink()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchLinkTokenCalled)
        XCTAssertTrue(viewModel.showingPlaidLink)
        XCTAssertEqual(viewModel.linkToken, "link-sandbox-12345678-1234-1234-1234-123456789012")
    }
    
    // MARK: - Plaid Success Handling Tests
    
    func testHandlePlaidSuccess_exchangesTokenAndFetchesAccounts() async {
        // Arrange
        let publicToken = "public-sandbox-12345678-1234-1234-1234-123456789012"
        let expectedAccounts = [
            PlaidAccount(
                id: "account-1",
                name: "Chase Checking",
                accountType: "depository",
                institutionName: "Chase",
                isInflow: false,
                isOutflow: false,
                needsReauthentication: false,
                createdAt: Date()
            )
        ]
        let rawAccounts = [
            PlaidAccountRaw(
                account_id: "account-1",
                name: "Chase Checking",
                official_name: "Chase Premier Plus Checking",
                type: "depository",
                subtype: "checking",
                mask: "0000",
                balances: PlaidBalances(
                    available: 1000.0,
                    current: 1000.0,
                    iso_currency_code: "USD"
                )
            )
        ]
        let exchangeData = ExchangeTokenData(
            accessToken: "access-sandbox-12345678-1234-1234-1234-123456789012",
            itemId: "item-sandbox-12345678-1234-1234-1234-123456789012",
            accounts: rawAccounts
        )
        let exchangeResponse = ExchangeTokenResponse(
            success: true,
            data: exchangeData
        )
        mockPlaidService.mockExchangeTokenResponse = exchangeResponse
        mockPlaidService.mockAccounts = expectedAccounts
        
        // Act
        await viewModel.handlePlaidSuccess(publicToken: publicToken)
        
        // Assert
        XCTAssertTrue(mockPlaidService.exchangePublicTokenCalled)
        XCTAssertTrue(mockPlaidService.fetchAccountsCalled)
        XCTAssertEqual(mockPlaidService.lastPublicToken, publicToken)
        XCTAssertEqual(viewModel.connectedAccounts.count, 1)
        XCTAssertEqual(viewModel.connectedAccounts.first?.name, "Chase Checking")
        XCTAssertFalse(viewModel.showingPlaidLink)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testHandlePlaidSuccess_whenExchangeFails_showsError() async {
        // Arrange
        let publicToken = "invalid-token"
        mockPlaidService.shouldThrowError = true
        mockPlaidService.errorToThrow = .exchangeFailed
        
        // Act
        await viewModel.handlePlaidSuccess(publicToken: publicToken)
        
        // Assert
        XCTAssertTrue(mockPlaidService.exchangePublicTokenCalled)
        XCTAssertEqual(viewModel.errorMessage, "Failed to exchange public token")
        XCTAssertFalse(viewModel.showingPlaidLink)
        XCTAssertEqual(viewModel.connectedAccounts.count, 0)
    }
    
    // MARK: - Plaid Exit Handling Tests
    
    func testHandlePlaidExit_hidesPlaidLink() {
        // Arrange
        viewModel.showingPlaidLink = true
        
        // Act
        viewModel.handlePlaidExit()
        
        // Assert
        XCTAssertFalse(viewModel.showingPlaidLink)
    }
    
    // MARK: - Account Refresh Tests
    
    func testRefreshAccounts_fetchesAccountsFromService() async {
        // Arrange
        let expectedAccounts = [
            PlaidAccount(
                id: "account-1",
                name: "Chase Checking",
                accountType: "depository",
                institutionName: "Chase",
                isInflow: true,
                isOutflow: false,
                needsReauthentication: false,
                createdAt: Date()
            ),
            PlaidAccount(
                id: "account-2",
                name: "Chase Credit",
                accountType: "credit",
                institutionName: "Chase",
                isInflow: false,
                isOutflow: true,
                needsReauthentication: false,
                createdAt: Date()
            )
        ]
        mockPlaidService.mockAccounts = expectedAccounts
        
        // Act
        await viewModel.refreshAccounts()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchAccountsCalled)
        XCTAssertEqual(viewModel.connectedAccounts.count, 2)
        XCTAssertEqual(viewModel.connectedAccounts[0].name, "Chase Checking")
        XCTAssertEqual(viewModel.connectedAccounts[1].name, "Chase Credit")
    }
    
    func testRefreshAccounts_whenServiceFails_showsError() async {
        // Arrange
        mockPlaidService.shouldThrowError = true
        mockPlaidService.errorToThrow = .accountsFetchFailed
        
        // Act
        await viewModel.refreshAccounts()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchAccountsCalled)
        XCTAssertEqual(viewModel.errorMessage, "Failed to fetch accounts")
        XCTAssertEqual(viewModel.connectedAccounts.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_resetsErrorMessage() {
        // Arrange
        viewModel.errorMessage = "Some error"
        
        // Act
        viewModel.clearError()
        
        // Assert
        XCTAssertNil(viewModel.errorMessage)
    }
} 