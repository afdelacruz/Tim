import Foundation

protocol PlaidServiceProtocol {
    func fetchLinkToken() async throws -> LinkTokenResponse
    func exchangePublicToken(publicToken: String) async throws -> ExchangeTokenResponse
    func fetchAccounts() async throws -> [PlaidAccount]
    func updateAccountCategories(accountId: String, isInflow: Bool, isOutflow: Bool) async throws -> UpdateCategoriesResponse
}

class PlaidService: PlaidServiceProtocol {
    
    private let networkManager: NetworkManagerProtocol
    private let keychainService: KeychainServiceProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared, keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkManager = networkManager
        self.keychainService = keychainService
    }
    
    func fetchLinkToken() async throws -> LinkTokenResponse {
        guard let url = NetworkManager.shared.buildURL(path: "/api/plaid/link-token") else {
            throw PlaidError.invalidLinkToken
        }
        
        let requestBody = LinkTokenRequest()
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: LinkTokenResponse = try await networkManager.request(
                url: url,
                method: .POST,
                body: bodyData,
                headers: getAuthHeaders()
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error, defaultError: .invalidLinkToken)
        }
    }
    
    func exchangePublicToken(publicToken: String) async throws -> ExchangeTokenResponse {
        // Validate input
        guard !publicToken.isEmpty else {
            throw PlaidError.exchangeFailed
        }
        
        guard let url = NetworkManager.shared.buildURL(path: "/api/plaid/exchange-token") else {
            throw PlaidError.exchangeFailed
        }
        
        let requestBody = ExchangeTokenRequest(publicToken: publicToken)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: ExchangeTokenResponse = try await networkManager.request(
                url: url,
                method: .POST,
                body: bodyData,
                headers: getAuthHeaders()
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error, defaultError: .exchangeFailed)
        }
    }
    
    func fetchAccounts() async throws -> [PlaidAccount] {
        guard let url = NetworkManager.shared.buildURL(path: "/api/accounts") else {
            throw PlaidError.accountsFetchFailed
        }
        
        do {
            let response: AccountsResponse = try await networkManager.request(
                url: url,
                method: .GET,
                body: nil,
                headers: getAuthHeaders()
            )
            // Convert SavedPlaidAccount to PlaidAccount for UI consistency
            return response.data.accounts.map { $0.toPlaidAccount() }
        } catch let error as NetworkError {
            throw mapNetworkError(error, defaultError: .accountsFetchFailed)
        }
    }
    
    func updateAccountCategories(accountId: String, isInflow: Bool, isOutflow: Bool) async throws -> UpdateCategoriesResponse {
        guard let url = NetworkManager.shared.buildURL(path: "/api/accounts/\(accountId)/categories") else {
            throw PlaidError.categoryUpdateFailed
        }
        
        let requestBody = UpdateCategoriesRequest(isInflow: isInflow, isOutflow: isOutflow)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        do {
            let response: UpdateCategoriesResponse = try await networkManager.request(
                url: url,
                method: .PUT,
                body: bodyData,
                headers: getAuthHeaders()
            )
            return response
        } catch let error as NetworkError {
            throw mapNetworkError(error, defaultError: .categoryUpdateFailed)
        }
    }
    
    // MARK: - Private Methods
    
    private func getAuthHeaders() -> [String: String]? {
        guard let accessToken = keychainService.getAccessToken() else {
            return nil
        }
        
        return [
            "Authorization": "Bearer \(accessToken)"
        ]
    }
    
    private func mapNetworkError(_ error: NetworkError, defaultError: PlaidError) -> PlaidError {
        switch error {
        case .networkUnavailable:
            return .networkError
        case .decodingError:
            return .decodingError
        case .httpError(let code):
            // Map specific HTTP errors to appropriate Plaid errors
            switch code {
            case 400...499:
                return defaultError
            case 500...599:
                return defaultError
            default:
                return .unknown
            }
        default:
            return defaultError
        }
    }
} 