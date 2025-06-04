import WidgetKit
import SwiftUI

// MARK: - Widget Data Models
struct MonthlyBalanceData {
    let inflow: Double
    let outflow: Double
    let month: String
    let year: Int
}

// MARK: - Timeline Provider
struct TimTimelineProvider: TimelineProvider {
    typealias Entry = TimWidgetEntry
    
    // MARK: - Timeline Provider Methods
    func placeholder(in context: Context) -> TimWidgetEntry {
        print("🔵 TimTimelineProvider: placeholder() called")
        return TimWidgetEntry(date: Date(), isPlaceholder: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimWidgetEntry) -> Void) {
        print("🟡 TimTimelineProvider: getSnapshot() called")
        // Return immediately without any async calls
        let entry = getQuickEntry()
        print("🟡 TimTimelineProvider: getSnapshot() returning entry with inflow: \(entry.inflow), outflow: \(entry.outflow)")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimWidgetEntry>) -> Void) {
        print("🟢 TimTimelineProvider: getTimeline() called - REAL WIDGET REQUEST!")
        print("🟢 TimTimelineProvider: Context family: \(context.family), isPreview: \(context.isPreview)")
        
        // Get entry immediately without any async calls
        let entry = getQuickEntry()
        print("🟢 TimTimelineProvider: getTimeline() got entry with inflow: \(entry.inflow), outflow: \(entry.outflow)")
        
        // Create timeline with next refresh in 2 hours
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        print("🟢 TimTimelineProvider: getTimeline() completing with timeline, next refresh: \(nextRefresh)")
        
        completion(timeline)
        
        // AFTER completing the timeline, try to update cache in background
        Task.detached {
            await updateCacheInBackground()
        }
    }
    
    // MARK: - Quick Data Retrieval (Synchronous)
    private func getQuickEntry() -> TimWidgetEntry {
        print("🔍 TimTimelineProvider: getQuickEntry() called")
        
        // Check for cached balance data first
        if let cachedData = getCachedBalance() {
            print("📦 TimTimelineProvider: Using cached data - inflow: \(cachedData.inflow), outflow: \(cachedData.outflow)")
            return TimWidgetEntry(
                date: Date(),
                inflow: cachedData.inflow,
                outflow: cachedData.outflow,
                lastUpdated: cachedData.lastUpdated
            )
        } else {
            print("🔄 TimTimelineProvider: No cached data, showing placeholder")
            return TimWidgetEntry(
                date: Date(),
                inflow: 0.0,
                outflow: 0.0,
                isPlaceholder: true
            )
        }
    }
    
    // MARK: - Background Cache Update (Non-blocking)
    private func updateCacheInBackground() async {
        print("🔄 TimTimelineProvider: Starting background cache update...")
        
        do {
            // Authenticate directly and get balance data
            let balanceData = try await authenticateAndFetchBalance()
            
            // Cache the result for next widget refresh
            cachBalance(balanceData)
            print("✅ TimTimelineProvider: Successfully cached new balance data")
            
        } catch {
            print("❌ TimTimelineProvider: Background update failed: \(error)")
            // Silently fail - widget will use cached or fallback data
        }
    }
    
    // MARK: - Cache Management
    private func getCachedBalance() -> (inflow: Double, outflow: Double, lastUpdated: Date)? {
        guard let data = UserDefaults.standard.data(forKey: "widget_cached_balance") else {
            print("📦 TimTimelineProvider: No cached balance data found")
            return nil
        }
        
        do {
            let cached = try JSONDecoder().decode(CachedBalance.self, from: data)
            // Always return cached data regardless of age - never show zeros if we have data
            return (cached.inflow, cached.outflow, cached.lastUpdated)
        } catch {
            print("❌ TimTimelineProvider: Invalid cache data, ignoring")
            // Invalid cache data, ignore
        }
        
        return nil
    }
    
    private func cachBalance(_ data: MonthlyBalanceData) {
        let cached = CachedBalance(
            inflow: data.inflow,
            outflow: data.outflow,
            lastUpdated: Date()
        )
        
        do {
            let encodedData = try JSONEncoder().encode(cached)
            UserDefaults.standard.set(encodedData, forKey: "widget_cached_balance")
            print("✅ TimTimelineProvider: Cached balance data successfully")
        } catch {
            print("❌ TimTimelineProvider: Failed to cache balance data: \(error)")
        }
    }
    
    // MARK: - Direct Authentication and API Call
    private func authenticateAndFetchBalance() async throws -> MonthlyBalanceData {
        print("🔐 TimTimelineProvider: Authenticating with hardcoded credentials...")
        
        // Step 1: Login to get access token
        let accessToken = try await loginForWidget()
        print("✅ TimTimelineProvider: Got access token (length: \(accessToken.count))")
        
        // Step 2: Fetch balance data
        let balanceData = try await fetchBalanceDirectly(accessToken: accessToken)
        print("✅ TimTimelineProvider: Got balance data")
        
        return balanceData
    }
    
    private func loginForWidget() async throws -> String {
        guard let url = URL(string: "https://tim-production.up.railway.app/api/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let loginData = [
            "email": "test@example.com",
            "pin": "1234"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        guard loginResponse.success, let accessToken = loginResponse.accessToken else {
            throw URLError(.badServerResponse)
        }
        
        return accessToken
    }
    
    private func fetchBalanceDirectly(accessToken: String) async throws -> MonthlyBalanceData {
        guard let url = URL(string: "https://tim-production.up.railway.app/api/balances") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }
        
        // Parse the actual backend response format
        let balanceResponse = try JSONDecoder().decode(BackendBalanceResponse.self, from: data)
        
        if balanceResponse.success, let balanceData = balanceResponse.data {
            // Calculate total inflow and outflow from accounts
            let totalBalance = balanceData.totalBalance
            var inflow = totalBalance > 0 ? totalBalance : 0
            var outflow = totalBalance < 0 ? abs(totalBalance) : 0
            
            // For testing: Show mock data when balance is 0
            if totalBalance == 0 {
                inflow = 2450.75
                outflow = 1823.50
                print("💰 TimTimelineProvider: Using mock data for testing - inflow: \(inflow), outflow: \(outflow)")
            } else {
                print("💰 TimTimelineProvider: Real balance data - totalBalance: \(totalBalance), inflow: \(inflow), outflow: \(outflow)")
            }
            
            // Create MonthlyBalanceData from the backend response
            return MonthlyBalanceData(
                inflow: inflow,
                outflow: outflow,
                month: getCurrentMonthName(),
                year: getCurrentYear()
            )
        } else {
            throw URLError(.badServerResponse)
        }
    }
    
    // Helper functions
    private func getCurrentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
}

// MARK: - Backend Response Models
private struct LoginResponse: Codable {
    let success: Bool
    let accessToken: String?
    let refreshToken: String?
    let user: User?
    let message: String?
}

private struct User: Codable {
    let id: String
    let email: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

private struct BackendBalanceResponse: Codable {
    let success: Bool
    let data: BackendBalanceData?
}

private struct BackendBalanceData: Codable {
    let accounts: [BackendAccount]
    let totalBalance: Double
}

private struct BackendAccount: Codable {
    let id: String
    let name: String
    let type: String
    let institution: String
    let currentBalance: Double
    let lastUpdated: String?
    let needsReauthentication: Bool
}

// MARK: - Cache Model
private struct CachedBalance: Codable {
    let inflow: Double
    let outflow: Double
    let lastUpdated: Date
} 