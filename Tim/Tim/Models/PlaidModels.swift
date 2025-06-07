import Foundation

// MARK: - Link Token Models

struct LinkTokenResponse: Codable {
    let success: Bool
    let linkToken: String
    let expiration: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case linkToken = "linkToken"  // Backend sends camelCase
        case expiration
    }
}

struct LinkTokenRequest: Codable {
    // No additional fields needed - backend handles user context via JWT
}

// MARK: - Exchange Token Models

struct ExchangeTokenRequest: Codable {
    let publicToken: String
    
    enum CodingKeys: String, CodingKey {
        case publicToken = "publicToken"  // Backend expects camelCase
    }
}

struct ExchangeTokenResponse: Codable {
    let success: Bool
    let data: ExchangeTokenData
}

struct ExchangeTokenData: Codable {
    let accessToken: String
    let itemId: String
    let accounts: [PlaidAccountRaw]
}

// MARK: - Account Models

struct PlaidAccountRaw: Codable {
    let account_id: String
    let name: String
    let official_name: String?
    let type: String
    let subtype: String
    let mask: String
    let balances: PlaidBalances
}

struct PlaidBalances: Codable {
    let available: Double?
    let current: Double?
    let iso_currency_code: String?
}

struct PlaidAccount: Codable, Identifiable {
    let id: String
    let name: String
    let accountType: String
    let institutionName: String
    let isInflow: Bool
    let isOutflow: Bool
    let needsReauthentication: Bool
    let createdAt: Date
    let currentBalance: Double
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "account_name"
        case accountType = "account_type"
        case institutionName = "institution_name"
        case isInflow = "is_inflow"
        case isOutflow = "is_outflow"
        case needsReauthentication = "needs_reauthentication"
        case createdAt = "created_at"
        case currentBalance = "current_balance"
        case lastUpdated = "last_updated"
    }
    
    // Direct initializer for tests and manual creation
    init(id: String, name: String, accountType: String, institutionName: String, isInflow: Bool, isOutflow: Bool, needsReauthentication: Bool, createdAt: Date, currentBalance: Double = 0.0, lastUpdated: Date? = nil) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.institutionName = institutionName
        self.isInflow = isInflow
        self.isOutflow = isOutflow
        self.needsReauthentication = needsReauthentication
        self.createdAt = createdAt
        self.currentBalance = currentBalance
        self.lastUpdated = lastUpdated
    }
    
    // Decoder initializer for JSON decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        accountType = try container.decode(String.self, forKey: .accountType)
        institutionName = try container.decode(String.self, forKey: .institutionName)
        isInflow = try container.decode(Bool.self, forKey: .isInflow)
        isOutflow = try container.decode(Bool.self, forKey: .isOutflow)
        needsReauthentication = try container.decode(Bool.self, forKey: .needsReauthentication)
        // Handle currentBalance as either Double or String (from backend)
        if let balanceDouble = try? container.decodeIfPresent(Double.self, forKey: .currentBalance) {
            currentBalance = balanceDouble
        } else if let balanceString = try? container.decodeIfPresent(String.self, forKey: .currentBalance) {
            currentBalance = Double(balanceString) ?? 0.0
        } else {
            currentBalance = 0.0
        }
        
        // Handle date decoding similar to User model
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            createdAt = formatter.date(from: dateString) ?? Date()
        }
        
        // Handle lastUpdated date decoding
        if let lastUpdatedString = try container.decodeIfPresent(String.self, forKey: .lastUpdated) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: lastUpdatedString) {
                lastUpdated = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                lastUpdated = formatter.date(from: lastUpdatedString)
            }
        } else {
            lastUpdated = nil
        }
    }
}

// MARK: - Saved Account Models (from backend)

struct SavedPlaidAccount: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let institutionName: String
    let currentBalance: Double
    let lastUpdated: String?
    let needsReauth: Bool
    let createdAt: String
    let isInflow: Bool
    let isOutflow: Bool
    
    // Convert to PlaidAccount for UI consistency
    func toPlaidAccount() -> PlaidAccount {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdDate: Date
        if let date = formatter.date(from: createdAt) {
            createdDate = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            createdDate = formatter.date(from: createdAt) ?? Date()
        }
        
        let lastUpdatedDate: Date?
        if let lastUpdated = lastUpdated {
            if let date = formatter.date(from: lastUpdated) {
                lastUpdatedDate = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                lastUpdatedDate = formatter.date(from: lastUpdated)
            }
        } else {
            lastUpdatedDate = nil
        }
        
        return PlaidAccount(
            id: id,
            name: name,
            accountType: type.capitalized,
            institutionName: institutionName,
            isInflow: isInflow, // Use the persisted category settings
            isOutflow: isOutflow,
            needsReauthentication: needsReauth,
            createdAt: createdDate,
            currentBalance: currentBalance,
            lastUpdated: lastUpdatedDate
        )
    }
}

struct AccountsResponse: Codable {
    let success: Bool
    let data: AccountsData
}

struct AccountsData: Codable {
    let accounts: [SavedPlaidAccount]
    let count: Int
}

// MARK: - Category Update Models

struct UpdateCategoriesRequest: Codable {
    let isInflow: Bool
    let isOutflow: Bool
    
    enum CodingKeys: String, CodingKey {
        case isInflow = "is_inflow"
        case isOutflow = "is_outflow"
    }
}

struct UpdateCategoriesResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Error Models

enum PlaidError: Error, Equatable {
    case invalidLinkToken
    case exchangeFailed
    case accountsFetchFailed
    case categoryUpdateFailed
    case networkError
    case decodingError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidLinkToken:
            return "Invalid link token"
        case .exchangeFailed:
            return "Failed to exchange public token"
        case .accountsFetchFailed:
            return "Failed to fetch accounts"
        case .categoryUpdateFailed:
            return "Failed to update account categories"
        case .networkError:
            return "Network connection error"
        case .decodingError:
            return "Failed to decode response"
        case .unknown:
            return "Unknown error occurred"
        }
    }
} 