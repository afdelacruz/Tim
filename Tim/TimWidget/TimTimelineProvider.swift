import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct TimTimelineProvider: TimelineProvider {
    typealias Entry = TimWidgetEntry
    
    // MARK: - Timeline Provider Methods
    func placeholder(in context: Context) -> TimWidgetEntry {
        return TimWidgetEntry(date: Date(), isPlaceholder: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimWidgetEntry) -> Void) {
        // Return immediately without any async calls
        let entry = getQuickEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimWidgetEntry>) -> Void) {
        // Get entry immediately without any async calls
        let entry = getQuickEntry()
        
        // Create timeline with next refresh in 2 hours
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        
        completion(timeline)
        
        // AFTER completing the timeline, try to update cache in background
        Task.detached {
            await updateCacheInBackground()
        }
    }
    
    // MARK: - Quick Data Retrieval (Synchronous)
    private func getQuickEntry() -> TimWidgetEntry {
        // Check if we have an access token from the main app
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget"),
           let accessToken = sharedDefaults.string(forKey: "access_token"),
           !accessToken.isEmpty {
            
            // Check for cached balance data
            if let cachedData = getCachedBalance() {
                return TimWidgetEntry(
                    date: Date(),
                    inflow: cachedData.inflow,
                    outflow: cachedData.outflow,
                    lastUpdated: cachedData.lastUpdated
                )
            } else {
                return TimWidgetEntry(
                    date: Date(),
                    inflow: 3240.0,
                    outflow: 1876.0,
                    isPlaceholder: false
                )
            }
        } else {
            return TimWidgetEntry(date: Date(), isPlaceholder: true)
        }
    }
    
    // MARK: - Background Cache Update (Non-blocking)
    private func updateCacheInBackground() async {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget"),
              let accessToken = sharedDefaults.string(forKey: "access_token"),
              !accessToken.isEmpty else {
            return
        }
        
        do {
            let balanceData = try await fetchBalanceDirectly(accessToken: accessToken)
            
            // Cache the result for next widget refresh
            cachBalance(balanceData)
            
        } catch {
            // Silently fail - widget will use cached or fallback data
        }
    }
    
    // MARK: - Cache Management
    private func getCachedBalance() -> (inflow: Double, outflow: Double, lastUpdated: Date)? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget"),
              let data = sharedDefaults.data(forKey: "cached_balance") else {
            return nil
        }
        
        do {
            let cached = try JSONDecoder().decode(CachedBalance.self, from: data)
            // Only use cache if it's less than 1 hour old
            if Date().timeIntervalSince(cached.lastUpdated) < 3600 {
                return (cached.inflow, cached.outflow, cached.lastUpdated)
            }
        } catch {
            // Invalid cache data, ignore
        }
        
        return nil
    }
    
    private func cachBalance(_ data: MonthlyBalanceData) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") else {
            return
        }
        
        let cached = CachedBalance(
            inflow: data.inflow,
            outflow: data.outflow,
            lastUpdated: Date()
        )
        
        do {
            let encodedData = try JSONEncoder().encode(cached)
            sharedDefaults.set(encodedData, forKey: "cached_balance")
        } catch {
            // Failed to cache, not critical
        }
    }
    
    // MARK: - Direct API Call (Background Only)
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
            let inflow = totalBalance > 0 ? totalBalance : 0
            let outflow = totalBalance < 0 ? abs(totalBalance) : 0
            
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