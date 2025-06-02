import Foundation

// MARK: - Balance Data Models
struct MonthlyBalanceData: Codable {
    let inflow: Double
    let outflow: Double
    let month: String
    let year: Int
}

struct BalanceResponse: Codable {
    let success: Bool
    let data: MonthlyBalanceData?
    let error: ErrorResponse?
}

// MARK: - Balance Service Protocol
protocol BalanceServiceProtocol {
    func fetchCurrentMonthBalance() async throws -> MonthlyBalanceData
}

// MARK: - Balance Service Implementation
@MainActor
class BalanceService: BalanceServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let authService: AuthServiceProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         authService: AuthServiceProtocol = AuthService.shared) {
        self.networkManager = networkManager
        self.authService = authService
    }
    
    func fetchCurrentMonthBalance() async throws -> MonthlyBalanceData {
        print("🔐 BalanceService: Checking authentication...")
        
        // Ensure we have a valid access token
        try await authService.ensureValidAccessToken()
        
        guard let accessToken = authService.accessToken else {
            print("❌ BalanceService: No access token available")
            throw BalanceError.notAuthenticated
        }
        
        print("✅ BalanceService: Access token found (length: \(accessToken.count))")
        print("🌐 BalanceService: Making API request to /api/balances/current-month")
        
        let endpoint = "/api/balances/current-month"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        guard let url = NetworkManager.shared.buildURL(path: endpoint) else {
            throw BalanceError.networkError("Invalid URL")
        }
        
        do {
            let response: BalanceResponse = try await networkManager.request(
                url: url,
                method: .GET,
                body: nil,
                headers: headers
            )
            
            print("📥 BalanceService: Received API response")
            print("   Success: \(response.success)")
            
            if response.success, let data = response.data {
                print("✅ BalanceService: Valid balance data received")
                print("   Inflow: $\(data.inflow)")
                print("   Outflow: $\(data.outflow)")
                print("   Month: \(data.month) \(data.year)")
                return data
            } else if let error = response.error {
                print("❌ BalanceService: API returned error")
                print("   Error code: \(error.code)")
                print("   Error message: \(error.message)")
                throw BalanceError.apiError(error.message)
            } else {
                print("❌ BalanceService: Invalid response - no data and no error")
                throw BalanceError.invalidResponse
            }
        } catch {
            print("❌ BalanceService: Request failed")
            print("   Error: \(error)")
            print("   Error type: \(type(of: error))")
            
            if error is BalanceError {
                throw error
            } else {
                throw BalanceError.networkError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Balance Errors
enum BalanceError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case apiError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - Shared Instance for Widget
extension BalanceService {
    static let shared = BalanceService()
} 