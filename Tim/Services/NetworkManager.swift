import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case httpError(Int)
    case unknown
}

protocol NetworkManagerProtocol {
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String]?
    ) async throws -> T
}

class NetworkManager: NetworkManagerProtocol {
    
    static let shared = NetworkManager()
    private let session = URLSession.shared
    private let baseURL = "https://tim-production.up.railway.app"
    
    private init() {}
    
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown
        }
    }
    
    func buildURL(path: String) -> URL? {
        return URL(string: baseURL + path)
    }
} 