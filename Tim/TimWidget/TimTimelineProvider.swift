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
        do {
            // Try to fetch fresh data
            let balanceData = try await BalanceService.shared.fetchCurrentMonthBalance()
            let entry = TimWidgetEntry(
                date: Date(),
                inflow: balanceData.inflow,
                outflow: balanceData.outflow,
                lastUpdated: Date()
            )
            
            // Cache the successful result
            cacheEntry(entry)
            return entry
            
        } catch {
            print("Widget failed to fetch balance data: \(error)")
            
            // Try to use cached data
            if let cachedEntry = getCachedEntry() {
                return cachedEntry
            }
            
            // Fallback to placeholder
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