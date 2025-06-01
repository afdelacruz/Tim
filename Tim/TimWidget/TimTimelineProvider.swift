import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct TimTimelineProvider: TimelineProvider {
    typealias Entry = TimWidgetEntry
    
    // MARK: - Cache Management
    private let cacheKey = "TimWidgetCache"
    private let cacheTimestampKey = "TimWidgetCacheTimestamp"
    private let maxCacheAge: TimeInterval = 48 * 60 * 60 // 48 hours
    
    // MARK: - Timeline Provider Methods
    func placeholder(in context: Context) -> TimWidgetEntry {
        TimWidgetEntry(date: Date(), isPlaceholder: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimWidgetEntry) -> Void) {
        Task {
            let entry = await fetchBalanceEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimWidgetEntry>) -> Void) {
        Task {
            let entry = await fetchBalanceEntry()
            
            // Schedule next update in 24 hours
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date().addingTimeInterval(86400)
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    // MARK: - Data Fetching
    private func fetchBalanceEntry() async -> TimWidgetEntry {
        print("🔄 Widget: Starting balance data fetch...")
        
        do {
            // Try to fetch fresh data
            print("📡 Widget: Calling BalanceService.fetchCurrentMonthBalance()")
            let balanceData = try await BalanceService.shared.fetchCurrentMonthBalance()
            
            print("✅ Widget: Successfully received balance data:")
            print("   📈 Inflow: $\(balanceData.inflow)")
            print("   📉 Outflow: $\(balanceData.outflow)")
            print("   📅 Month: \(balanceData.month) \(balanceData.year)")
            
            let entry = TimWidgetEntry(
                date: Date(),
                inflow: balanceData.inflow,
                outflow: balanceData.outflow,
                lastUpdated: Date()
            )
            
            // Cache the successful result
            print("💾 Widget: Caching successful result")
            cacheEntry(entry)
            return entry
            
        } catch {
            print("❌ Widget: Failed to fetch balance data")
            print("   Error: \(error)")
            print("   Error type: \(type(of: error))")
            
            if let balanceError = error as? BalanceError {
                print("   BalanceError details: \(balanceError.localizedDescription)")
            }
            
            // Try to use cached data
            print("🔍 Widget: Checking for cached data...")
            if let cachedEntry = getCachedEntry() {
                print("✅ Widget: Using cached data:")
                print("   📈 Cached Inflow: $\(cachedEntry.inflow)")
                print("   📉 Cached Outflow: $\(cachedEntry.outflow)")
                print("   🕐 Last Updated: \(cachedEntry.lastUpdated?.description ?? "Unknown")")
                return cachedEntry
            }
            
            // Fallback to placeholder
            print("⚠️ Widget: No cached data available, using placeholder")
            return TimWidgetEntry(date: Date(), isPlaceholder: true)
        }
    }
    
    // MARK: - Cache Implementation
    private func cacheEntry(_ entry: TimWidgetEntry) {
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        
        do {
            let data = try JSONEncoder().encode(CachedEntry(
                inflow: entry.inflow,
                outflow: entry.outflow,
                lastUpdated: entry.lastUpdated ?? Date()
            ))
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(Date(), forKey: cacheTimestampKey)
        } catch {
            print("Failed to cache widget entry: \(error)")
        }
    }
    
    private func getCachedEntry() -> TimWidgetEntry? {
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheTimestamp = userDefaults.object(forKey: cacheTimestampKey) as? Date else {
            return nil
        }
        
        // Check if cache is too old
        let cacheAge = Date().timeIntervalSince(cacheTimestamp)
        if cacheAge > maxCacheAge {
            return nil
        }
        
        do {
            let cachedEntry = try JSONDecoder().decode(CachedEntry.self, from: data)
            return TimWidgetEntry(
                date: Date(),
                inflow: cachedEntry.inflow,
                outflow: cachedEntry.outflow,
                lastUpdated: cachedEntry.lastUpdated
            )
        } catch {
            print("Failed to decode cached widget entry: \(error)")
            return nil
        }
    }
}

// MARK: - Cached Entry Model
private struct CachedEntry: Codable {
    let inflow: Double
    let outflow: Double
    let lastUpdated: Date
} 