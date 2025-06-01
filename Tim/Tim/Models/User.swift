import Foundation

struct User: Codable, Equatable {
    let id: String
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
    
    init(id: String, email: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        
        // Handle date decoding from ISO string with multiple format support
        let dateString = try container.decode(String.self, forKey: .createdAt)
        
        // Try ISO8601 with fractional seconds first (matches backend format)
        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter1.date(from: dateString) {
            createdAt = date
            return
        }
        
        // Try custom format with milliseconds
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter2.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter2.date(from: dateString) {
            createdAt = date
            return
        }
        
        // Try standard ISO8601 as fallback
        let formatter3 = ISO8601DateFormatter()
        if let date = formatter3.date(from: dateString) {
            createdAt = date
            return
        }
        
        throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format: \(dateString)")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        
        // Encode date as ISO string with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: createdAt)
        try container.encode(dateString, forKey: .createdAt)
    }
} 