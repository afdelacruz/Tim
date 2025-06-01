import XCTest
@testable import Tim

final class PlaidServiceTests: XCTestCase {
    
    var plaidService: PlaidService!
    var mockNetworkManager: MockNetworkManager!
    
    override func setUpWithError() throws {
        mockNetworkManager = MockNetworkManager()
        plaidService = PlaidService(networkManager: mockNetworkManager)
    }
    
    override func tearDownWithError() throws {
        plaidService = nil
        mockNetworkManager = nil
    }
    
    // MARK: - Link Token Tests
    
    func testFetchLinkToken_callsApiAndReturnsTokenForPlaidSdk() async throws {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await plaidService.fetchLinkToken()
        
        // Assert
        XCTAssertEqual(response.linkToken, "link-sandbox-12345678-1234-1234-1234-123456789012")
        XCTAssertTrue(response.success)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/plaid/link-token")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "POST")
    }
    
    func testFetchLinkToken_whenNetworkFails_throwsNetworkError() async {
        // Arrange
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = NetworkError.networkUnavailable
        
        // Act & Assert
        do {
            _ = try await plaidService.fetchLinkToken()
            XCTFail("Expected network error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.networkError)
        } catch {
            XCTFail("Expected PlaidError.networkError, got \(error)")
        }
    }
    
    func testFetchLinkToken_whenDecodingFails_throwsDecodingError() async {
        // Arrange
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = NetworkError.decodingError
        
        // Act & Assert
        do {
            _ = try await plaidService.fetchLinkToken()
            XCTFail("Expected decoding error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.decodingError)
        } catch {
            XCTFail("Expected PlaidError.decodingError, got \(error)")
        }
    }
    
    // MARK: - Exchange Token Tests
    
    func testExchangePublicToken_givenPlaidSdkSuccess_callsApiAndHandlesAccountResponse() async throws {
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
        let expectedResponse = ExchangeTokenResponse(
            success: true,
            message: "Accounts linked successfully",
            accounts: expectedAccounts
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await plaidService.exchangePublicToken(publicToken: publicToken)
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.accounts.count, 1)
        XCTAssertEqual(response.accounts.first?.name, "Chase Checking")
        XCTAssertEqual(response.accounts.first?.institutionName, "Chase")
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/plaid/exchange-token")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "POST")
    }
    
    func testExchangePublicToken_withInvalidToken_throwsExchangeFailedError() async {
        // Arrange
        let invalidToken = "invalid-token"
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = NetworkError.httpError(400)
        
        // Act & Assert
        do {
            _ = try await plaidService.exchangePublicToken(publicToken: invalidToken)
            XCTFail("Expected exchange failed error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.exchangeFailed)
        } catch {
            XCTFail("Expected PlaidError.exchangeFailed, got \(error)")
        }
    }
    
    func testExchangePublicToken_withEmptyToken_throwsExchangeFailedError() async {
        // Arrange
        let emptyToken = ""
        
        // Act & Assert
        do {
            _ = try await plaidService.exchangePublicToken(publicToken: emptyToken)
            XCTFail("Expected exchange failed error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.exchangeFailed)
        } catch {
            XCTFail("Expected PlaidError.exchangeFailed, got \(error)")
        }
    }
    
    // MARK: - Fetch Accounts Tests
    
    func testFetchAccounts_whenServiceReturnsData_returnsAccountList() async throws {
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
        let expectedResponse = AccountsResponse(
            success: true,
            accounts: expectedAccounts
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let accounts = try await plaidService.fetchAccounts()
        
        // Assert
        XCTAssertEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0].name, "Chase Checking")
        XCTAssertEqual(accounts[0].isInflow, true)
        XCTAssertEqual(accounts[1].name, "Chase Credit")
        XCTAssertEqual(accounts[1].isOutflow, true)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/accounts")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "GET")
    }
    
    func testFetchAccounts_whenServiceFails_throwsAccountsFetchFailedError() async {
        // Arrange
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = NetworkError.httpError(500)
        
        // Act & Assert
        do {
            _ = try await plaidService.fetchAccounts()
            XCTFail("Expected accounts fetch failed error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.accountsFetchFailed)
        } catch {
            XCTFail("Expected PlaidError.accountsFetchFailed, got \(error)")
        }
    }
    
    func testFetchAccounts_withNoAccounts_returnsEmptyArray() async throws {
        // Arrange
        let expectedResponse = AccountsResponse(
            success: true,
            accounts: []
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let accounts = try await plaidService.fetchAccounts()
        
        // Assert
        XCTAssertEqual(accounts.count, 0)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/accounts")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "GET")
    }
    
    // MARK: - Update Account Categories Tests
    
    func testUpdateAccountCategories_callsApiWithCorrectParametersAndHandlesResponse() async throws {
        // Arrange
        let accountId = "account-123"
        let isInflow = true
        let isOutflow = false
        let expectedResponse = UpdateCategoriesResponse(
            success: true,
            message: "Account categories updated successfully"
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await plaidService.updateAccountCategories(
            accountId: accountId,
            isInflow: isInflow,
            isOutflow: isOutflow
        )
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Account categories updated successfully")
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/accounts/\(accountId)/categories")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "PUT")
    }
    
    func testUpdateAccountCategories_forNonExistentAccount_throwsCategoryUpdateFailedError() async {
        // Arrange
        let nonExistentAccountId = "non-existent-account"
        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = NetworkError.httpError(404)
        
        // Act & Assert
        do {
            _ = try await plaidService.updateAccountCategories(
                accountId: nonExistentAccountId,
                isInflow: true,
                isOutflow: false
            )
            XCTFail("Expected category update failed error to be thrown")
        } catch let error as PlaidError {
            XCTAssertEqual(error, PlaidError.categoryUpdateFailed)
        } catch {
            XCTFail("Expected PlaidError.categoryUpdateFailed, got \(error)")
        }
    }
    
    func testUpdateAccountCategories_withBothCategoriesTrue_updatesSuccessfully() async throws {
        // Arrange
        let accountId = "account-123"
        let expectedResponse = UpdateCategoriesResponse(
            success: true,
            message: "Account categories updated successfully"
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await plaidService.updateAccountCategories(
            accountId: accountId,
            isInflow: true,
            isOutflow: true
        )
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/accounts/\(accountId)/categories")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "PUT")
    }
    
    func testUpdateAccountCategories_withBothCategoriesFalse_updatesSuccessfully() async throws {
        // Arrange
        let accountId = "account-123"
        let expectedResponse = UpdateCategoriesResponse(
            success: true,
            message: "Account categories updated successfully"
        )
        mockNetworkManager.mockResponse = expectedResponse
        
        // Act
        let response = try await plaidService.updateAccountCategories(
            accountId: accountId,
            isInflow: false,
            isOutflow: false
        )
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(mockNetworkManager.lastRequestURL?.path, "/api/accounts/\(accountId)/categories")
        XCTAssertEqual(mockNetworkManager.lastRequestMethod, "PUT")
    }
} 