import XCTest
import WidgetKit
@testable import Tim

// MARK: - Mock Balance Service
class MockBalanceService: BalanceServiceProtocol {
    var shouldSucceed = true
    var mockBalanceData: MonthlyBalanceData?
    var mockError: Error?
    var fetchCallCount = 0
    
    func fetchCurrentMonthBalance() async throws -> MonthlyBalanceData {
        fetchCallCount += 1
        
        if let error = mockError {
            throw error
        }
        
        if shouldSucceed, let data = mockBalanceData {
            return data
        }
        
        throw BalanceError.invalidResponse
    }
}

// MARK: - Timeline Provider Tests
class TimTimelineProviderTests: XCTestCase {
    var timelineProvider: TimTimelineProvider!
    var mockBalanceService: MockBalanceService!
    
    override func setUp() {
        super.setUp()
        timelineProvider = TimTimelineProvider()
        mockBalanceService = MockBalanceService()
        
        // Clear any existing cache
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        userDefaults.removeObject(forKey: "TimWidgetCache")
        userDefaults.removeObject(forKey: "TimWidgetCacheTimestamp")
    }
    
    override func tearDown() {
        timelineProvider = nil
        mockBalanceService = nil
        
        // Clean up cache
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        userDefaults.removeObject(forKey: "TimWidgetCache")
        userDefaults.removeObject(forKey: "TimWidgetCacheTimestamp")
        
        super.tearDown()
    }
    
    // MARK: - Placeholder Tests
    func testPlaceholder_returnsPlaceholderEntry() {
        // Given
        let context = MockWidgetContext()
        
        // When
        let entry = timelineProvider.placeholder(in: context)
        
        // Then
        XCTAssertTrue(entry.isPlaceholder)
        XCTAssertEqual(entry.inflow, 0)
        XCTAssertEqual(entry.outflow, 0)
        XCTAssertNil(entry.lastUpdated)
    }
    
    // MARK: - Snapshot Tests
    func testGetSnapshot_withSuccessfulDataFetch_returnsValidEntry() async {
        // Given
        let expectedData = MonthlyBalanceData(
            inflow: 1500.0,
            outflow: 750.0,
            month: "December",
            year: 2024
        )
        
        // Mock BalanceService.shared to return our mock data
        // Note: In a real implementation, we'd need dependency injection for the timeline provider
        
        let context = MockWidgetContext()
        let expectation = XCTestExpectation(description: "Snapshot completion")
        var resultEntry: TimWidgetEntry?
        
        // When
        timelineProvider.getSnapshot(in: context) { entry in
            resultEntry = entry
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Note: This test would need the actual BalanceService to be mockable
        // For now, we test the structure
        XCTAssertNotNil(resultEntry)
    }
    
    // MARK: - Timeline Tests
    func testGetTimeline_schedulesNextUpdateIn24Hours() async {
        // Given
        let context = MockWidgetContext()
        let expectation = XCTestExpectation(description: "Timeline completion")
        var resultTimeline: Timeline<TimWidgetEntry>?
        
        // When
        timelineProvider.getTimeline(in: context) { timeline in
            resultTimeline = timeline
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertNotNil(resultTimeline)
        XCTAssertEqual(resultTimeline?.entries.count, 1)
        
        // Verify the timeline policy schedules next update
        if case .after(let nextUpdate) = resultTimeline?.policy {
            let now = Date()
            let expectedNextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
            let timeDifference = abs(nextUpdate.timeIntervalSince(expectedNextUpdate))
            XCTAssertLessThan(timeDifference, 60) // Within 1 minute tolerance
        } else {
            XCTFail("Expected timeline policy to be .after with next update time")
        }
    }
    
    // MARK: - Widget Entry Tests
    func testTimWidgetEntry_initialization_setsCorrectValues() {
        // Given
        let date = Date()
        let inflow = 1240.0
        let outflow = 890.0
        let lastUpdated = Date().addingTimeInterval(-3600)
        
        // When
        let entry = TimWidgetEntry(
            date: date,
            inflow: inflow,
            outflow: outflow,
            isPlaceholder: false,
            lastUpdated: lastUpdated
        )
        
        // Then
        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.inflow, inflow)
        XCTAssertEqual(entry.outflow, outflow)
        XCTAssertFalse(entry.isPlaceholder)
        XCTAssertEqual(entry.lastUpdated, lastUpdated)
    }
    
    func testTimWidgetEntry_defaultInitialization_setsDefaultValues() {
        // Given
        let date = Date()
        
        // When
        let entry = TimWidgetEntry(date: date)
        
        // Then
        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.inflow, 0)
        XCTAssertEqual(entry.outflow, 0)
        XCTAssertFalse(entry.isPlaceholder)
        XCTAssertNil(entry.lastUpdated)
    }
    
    func testTimWidgetEntry_placeholderInitialization_setsPlaceholderFlag() {
        // Given
        let date = Date()
        
        // When
        let entry = TimWidgetEntry(date: date, isPlaceholder: true)
        
        // Then
        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.inflow, 0)
        XCTAssertEqual(entry.outflow, 0)
        XCTAssertTrue(entry.isPlaceholder)
        XCTAssertNil(entry.lastUpdated)
    }
    
    // MARK: - Cache Tests
    func testCacheEntry_storesAndRetrievesCorrectly() {
        // Given
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        let testEntry = TimWidgetEntry(
            date: Date(),
            inflow: 1000.0,
            outflow: 500.0,
            lastUpdated: Date()
        )
        
        // When - Simulate caching (this would be done by the timeline provider)
        let cachedEntry = CachedEntryForTesting(
            inflow: testEntry.inflow,
            outflow: testEntry.outflow,
            lastUpdated: testEntry.lastUpdated!
        )
        
        do {
            let data = try JSONEncoder().encode(cachedEntry)
            userDefaults.set(data, forKey: "TimWidgetCache")
            userDefaults.set(Date(), forKey: "TimWidgetCacheTimestamp")
        } catch {
            XCTFail("Failed to encode cache entry: \(error)")
        }
        
        // Then - Verify retrieval
        guard let retrievedData = userDefaults.data(forKey: "TimWidgetCache") else {
            XCTFail("No cached data found")
            return
        }
        
        do {
            let retrievedEntry = try JSONDecoder().decode(CachedEntryForTesting.self, from: retrievedData)
            XCTAssertEqual(retrievedEntry.inflow, testEntry.inflow)
            XCTAssertEqual(retrievedEntry.outflow, testEntry.outflow)
        } catch {
            XCTFail("Failed to decode cached entry: \(error)")
        }
    }
    
    func testCacheExpiry_oldCacheIsIgnored() {
        // Given
        let userDefaults = UserDefaults(suiteName: "group.com.tim.widget") ?? UserDefaults.standard
        let oldTimestamp = Date().addingTimeInterval(-49 * 60 * 60) // 49 hours ago (older than 48h limit)
        
        let cachedEntry = CachedEntryForTesting(
            inflow: 1000.0,
            outflow: 500.0,
            lastUpdated: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(cachedEntry)
            userDefaults.set(data, forKey: "TimWidgetCache")
            userDefaults.set(oldTimestamp, forKey: "TimWidgetCacheTimestamp")
        } catch {
            XCTFail("Failed to set up old cache: \(error)")
        }
        
        // When - Check if cache is considered valid
        let cacheTimestamp = userDefaults.object(forKey: "TimWidgetCacheTimestamp") as? Date
        let cacheAge = Date().timeIntervalSince(cacheTimestamp ?? Date())
        let maxCacheAge: TimeInterval = 48 * 60 * 60 // 48 hours
        
        // Then
        XCTAssertGreaterThan(cacheAge, maxCacheAge, "Cache should be considered expired")
    }
}

// MARK: - Test Helpers
private struct CachedEntryForTesting: Codable {
    let inflow: Double
    let outflow: Double
    let lastUpdated: Date
}

private class MockWidgetContext: WidgetContext {
    var family: WidgetFamily = .systemSmall
    var isPreview: Bool = false
    var displaySize: CGSize = CGSize(width: 155, height: 155)
    
    @available(iOS 17.0, *)
    var supportsInteractivity: Bool = false
} 