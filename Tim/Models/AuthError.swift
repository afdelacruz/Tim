import Foundation

enum AuthError: Error, Equatable {
    case invalidEmail
    case invalidPin
    case unauthorized
    case networkError
    case decodingError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPin:
            return "PIN must be exactly 4 digits"
        case .unauthorized:
            return "Invalid email or PIN"
        case .networkError:
            return "Network connection error. Please try again."
        case .decodingError:
            return "Unable to process server response"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
} 