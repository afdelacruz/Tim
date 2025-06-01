import Foundation
@testable import Tim

class MockPlaidService: PlaidServiceProtocol {
    
    // MARK: - Mock Control Properties
    
    var shouldThrowError = false
    var errorToThrow: PlaidError = .unknown
    
    // Specific control for different operations
    var shouldFailFetchAccounts = false
    var shouldSucceedUpdateCategories = true
    var shouldFailUpdateCategories = false
    var fetchAccountsDelay: TimeInterval = 0
    
    // MARK: - Mock Response Properties
    
    var mockLinkTokenResponse: LinkTokenResponse?
    var mockExchangeTokenResponse: ExchangeTokenResponse?
    var mockAccounts: [PlaidAccount] = []
    var mockUpdateCategoriesResponse: UpdateCategoriesResponse?
    
    // MARK: - Call Tracking Properties
    
    var fetchLinkTokenCalled = false
    var exchangePublicTokenCalled = false
    var fetchAccountsCalled = false
    var updateAccountCategoriesCalled = false
    
    var lastPublicToken: String?
    var lastAccountId: String?
    var lastIsInflow: Bool?
    var lastIsOutflow: Bool?
    
    // MARK: - PlaidServiceProtocol Implementation
    
    func fetchLinkToken() async throws -> LinkTokenResponse {
        fetchLinkTokenCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let response = mockLinkTokenResponse else {
            throw PlaidError.invalidLinkToken
        }
        
        return response
    }
    
    func exchangePublicToken(publicToken: String) async throws -> ExchangeTokenResponse {
        exchangePublicTokenCalled = true
        lastPublicToken = publicToken
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let response = mockExchangeTokenResponse {
            return response
        }
        
        // Default mock response
        let mockData = ExchangeTokenData(
            accessToken: "mock_access_token",
            itemId: "mock_item_id",
            accounts: []
        )
        
        return ExchangeTokenResponse(success: true, data: mockData)
    }
    
    func fetchAccounts() async throws -> [PlaidAccount] {
        fetchAccountsCalled = true
        
        if fetchAccountsDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchAccountsDelay * 1_000_000_000))
        }
        
        if shouldThrowError || shouldFailFetchAccounts {
            throw errorToThrow
        }
        
        return mockAccounts
    }
    
    func updateAccountCategories(accountId: String, isInflow: Bool, isOutflow: Bool) async throws -> UpdateCategoriesResponse {
        updateAccountCategoriesCalled = true
        lastAccountId = accountId
        lastIsInflow = isInflow
        lastIsOutflow = isOutflow
        
        if shouldThrowError || shouldFailUpdateCategories {
            throw errorToThrow
        }
        
        if shouldSucceedUpdateCategories {
            return UpdateCategoriesResponse(success: true, message: "Categories updated successfully")
        }
        
        guard let response = mockUpdateCategoriesResponse else {
            throw PlaidError.categoryUpdateFailed
        }
        
        return response
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        shouldThrowError = false
        errorToThrow = .unknown
        shouldFailFetchAccounts = false
        shouldSucceedUpdateCategories = true
        shouldFailUpdateCategories = false
        fetchAccountsDelay = 0
        
        mockLinkTokenResponse = nil
        mockExchangeTokenResponse = nil
        mockAccounts = []
        mockUpdateCategoriesResponse = nil
        
        fetchLinkTokenCalled = false
        exchangePublicTokenCalled = false
        fetchAccountsCalled = false
        updateAccountCategoriesCalled = false
        
        lastPublicToken = nil
        lastAccountId = nil
        lastIsInflow = nil
        lastIsOutflow = nil
    }
} 