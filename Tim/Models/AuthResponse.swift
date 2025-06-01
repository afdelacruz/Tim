import Foundation

struct AuthResponse: Codable, Equatable {
    let success: Bool
    let message: String?
    let accessToken: String?
    let refreshToken: String?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case accessToken
        case refreshToken
        case user
    }
    
    init(success: Bool, message: String? = nil, accessToken: String? = nil, refreshToken: String? = nil, user: User? = nil) {
        self.success = success
        self.message = message
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
    }
} 