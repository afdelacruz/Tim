import Foundation
@testable import Tim

class MockPlaidService: PlaidServiceProtocol {
    
    // MARK: - Mock Control Properties
    
    var shouldThrowError = false
    var errorToThrow: PlaidError = .unknown
    
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
        
        guard let response = mockExchangeTokenResponse else {
            throw PlaidError.exchangeFailed
        }
        
        return response
    }
    
    func fetchAccounts() async throws -> [PlaidAccount] {
        fetchAccountsCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockAccounts
    }
    
    func updateAccountCategories(accountId: String, isInflow: Bool, isOutflow: Bool) async throws -> UpdateCategoriesResponse {
        updateAccountCategoriesCalled = true
        lastAccountId = accountId
        lastIsInflow = isInflow
        lastIsOutflow = isOutflow
        
        if shouldThrowError {
            throw errorToThrow
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