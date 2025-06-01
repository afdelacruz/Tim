import Foundation
@testable import Tim

class MockNetworkManager: NetworkManagerProtocol {
    
    // Mock response data
    var mockResponse: Any?
    var shouldThrowError = false
    var errorToThrow: Error?
    
    // Tracking properties for verification
    var lastRequestURL: URL?
    var lastRequestMethod: String?
    var lastRequestBody: Data?
    var lastRequestHeaders: [String: String]?
    
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        
        // Track the request for verification
        lastRequestURL = url
        lastRequestMethod = method.rawValue
        lastRequestBody = body
        lastRequestHeaders = headers
        
        // Simulate error if configured
        if shouldThrowError {
            throw errorToThrow ?? NetworkError.unknown
        }
        
        // Return mock response
        guard let response = mockResponse as? T else {
            throw NetworkError.decodingError
        }
        
        return response
    }
    
    func reset() {
        mockResponse = nil
        shouldThrowError = false
        errorToThrow = nil
        lastRequestURL = nil
        lastRequestMethod = nil
        lastRequestBody = nil
        lastRequestHeaders = nil
    }
} 