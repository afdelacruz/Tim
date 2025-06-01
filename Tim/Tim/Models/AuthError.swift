import Foundation

enum AuthError: Error, Equatable {
    case invalidEmail
    case invalidPin
    case unauthorized
    case emailAlreadyExists
    case networkError
    case decodingError
    case tokenExpired
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPin:
            return "PIN must be exactly 4 digits"
        case .unauthorized:
            return "Invalid email or PIN"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .decodingError:
            return "Unable to process server response"
        case .tokenExpired:
            return "Session expired. Please log in again."
        case .unknown:
            return "An unexpected error occurred"
        }
    }
} 