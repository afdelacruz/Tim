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
    case networkUnavailable
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .unknown:
            return "Unknown network error"
        }
    }
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
        
        print("🌐 NetworkManager: Making \(method.rawValue) request to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = 30.0
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            print("📤 Request body: \(String(data: body, encoding: .utf8) ?? "Unable to decode body")")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("📥 Response received: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NetworkError.unknown
            }
            
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Error response: \(responseString)")
                }
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let result = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response")
                return result
            } catch {
                print("❌ Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(responseString)")
                }
                throw NetworkError.decodingError
            }
            
        } catch let urlError as URLError {
            print("❌ URL Error: \(urlError.localizedDescription)")
            print("❌ URL Error Code: \(urlError.code.rawValue)")
            
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.networkUnavailable
            default:
                throw NetworkError.unknown
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            print("❌ Unknown error: \(error)")
            throw NetworkError.unknown
        }
    }
    
    func buildURL(path: String) -> URL? {
        let fullURL = baseURL + path
        print("🔗 Building URL: \(fullURL)")
        return URL(string: fullURL)
    }
} 