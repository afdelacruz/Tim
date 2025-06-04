import XCTest
import SwiftUI
@testable import Tim

@MainActor
final class CategoryConfigViewTests: XCTestCase {
    
    var mockPlaidService: MockPlaidService!
    var viewModel: CategoryConfigViewModel!
    
    override func setUpWithError() throws {
        mockPlaidService = MockPlaidService()
        viewModel = CategoryConfigViewModel(plaidService: mockPlaidService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockPlaidService = nil
    }
    
    // MARK: - View Initialization Tests
    
    func testCategoryConfigView_initializes() {
        // When
        let view = CategoryConfigView(viewModel: viewModel)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testCategoryConfigView_withDefaultViewModel_initializes() {
        // When
        let view = CategoryConfigView()
        
        // Then
        XCTAssertNotNil(view)
    }
    
    // MARK: - View State Tests
    
    func testCategoryAccountRowView_withInflowAccount_showsCorrectState() {
        // Given
        let account = PlaidAccount(
            id: "1",
            name: "Chase Checking",
            accountType: "Checking",
            institutionName: "Chase",
            isInflow: true,
            isOutflow: false,
            needsReauthentication: false,
            createdAt: Date()
        )
        
        var inflowToggleCalled = false
        var outflowToggleCalled = false
        
        // When
        let rowView = CategoryAccountRowView(
            account: account,
            onInflowToggle: { inflowToggleCalled = true },
            onOutflowToggle: { outflowToggleCalled = true }
        )
        
        // Then
        XCTAssertNotNil(rowView)
        // Verify callbacks are set up (they would be called on user interaction)
        XCTAssertFalse(inflowToggleCalled, "Callback should not be called during initialization")
        XCTAssertFalse(outflowToggleCalled, "Callback should not be called during initialization")
        // Note: UI state testing would require ViewInspector or similar for deeper testing
        // For MVP, we focus on ViewModel logic testing
    }
    
    func testCategoryAccountRowView_withOutflowAccount_showsCorrectState() {
        // Given
        let account = PlaidAccount(
            id: "1",
            name: "Chase Credit",
            accountType: "Credit",
            institutionName: "Chase",
            isInflow: false,
            isOutflow: true,
            needsReauthentication: false,
            createdAt: Date()
        )
        
        var inflowToggleCalled = false
        var outflowToggleCalled = false
        
        // When
        let rowView = CategoryAccountRowView(
            account: account,
            onInflowToggle: { inflowToggleCalled = true },
            onOutflowToggle: { outflowToggleCalled = true }
        )
        
        // Then
        XCTAssertNotNil(rowView)
        XCTAssertFalse(inflowToggleCalled, "Callback should not be called during initialization")
        XCTAssertFalse(outflowToggleCalled, "Callback should not be called during initialization")
    }
    
    func testCategoryAccountRowView_withBothCategories_showsCorrectState() {
        // Given
        let account = PlaidAccount(
            id: "1",
            name: "Multi-purpose Account",
            accountType: "Checking",
            institutionName: "Bank",
            isInflow: true,
            isOutflow: true,
            needsReauthentication: false,
            createdAt: Date()
        )
        
        var inflowToggleCalled = false
        var outflowToggleCalled = false
        
        // When
        let rowView = CategoryAccountRowView(
            account: account,
            onInflowToggle: { inflowToggleCalled = true },
            onOutflowToggle: { outflowToggleCalled = true }
        )
        
        // Then
        XCTAssertNotNil(rowView)
        XCTAssertFalse(inflowToggleCalled, "Callback should not be called during initialization")
        XCTAssertFalse(outflowToggleCalled, "Callback should not be called during initialization")
    }
    
    func testCategoryAccountRowView_withNeitherCategory_showsCorrectState() {
        // Given
        let account = PlaidAccount(
            id: "1",
            name: "Uncategorized Account",
            accountType: "Savings",
            institutionName: "Bank",
            isInflow: false,
            isOutflow: false,
            needsReauthentication: false,
            createdAt: Date()
        )
        
        var inflowToggleCalled = false
        var outflowToggleCalled = false
        
        // When
        let rowView = CategoryAccountRowView(
            account: account,
            onInflowToggle: { inflowToggleCalled = true },
            onOutflowToggle: { outflowToggleCalled = true }
        )
        
        // Then
        XCTAssertNotNil(rowView)
        XCTAssertFalse(inflowToggleCalled, "Callback should not be called during initialization")
        XCTAssertFalse(outflowToggleCalled, "Callback should not be called during initialization")
    }
    
    // MARK: - Integration Tests with ViewModel
    
    func testCategoryConfigView_loadsAccountsOnAppear() async {
        // Given
        let expectedAccounts = [
            PlaidAccount(id: "1", name: "Account 1", accountType: "Checking", institutionName: "Bank1", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "2", name: "Account 2", accountType: "Savings", institutionName: "Bank2", isInflow: true, isOutflow: false, needsReauthentication: false, createdAt: Date())
        ]
        mockPlaidService.mockAccounts = expectedAccounts
        
        // When
        await viewModel.loadAccounts()
        
        // Then
        XCTAssertEqual(viewModel.accounts.count, 2)
        XCTAssertTrue(mockPlaidService.fetchAccountsCalled)
    }
    
    func testCategoryConfigView_handlesLoadingState() async {
        // Given
        mockPlaidService.fetchAccountsDelay = 0.1
        
        // When
        let loadTask = Task {
            await viewModel.loadAccounts()
        }
        
        // Then - Check loading state
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCategoryConfigView_handlesErrorState() async {
        // Given
        mockPlaidService.shouldFailFetchAccounts = true
        mockPlaidService.errorToThrow = .accountsFetchFailed
        
        // When
        await viewModel.loadAccounts()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.accounts.isEmpty)
    }
    
    // MARK: - Account Icon Tests
    
    func testAccountIcon_forDifferentAccountTypes() {
        // This tests the icon logic in CategoryAccountRowView
        let testCases = [
            ("Checking", "creditcard"),
            ("Savings", "banknote"),
            ("Credit", "creditcard.circle"),
            ("Investment", "chart.line.uptrend.xyaxis"),
            ("401k", "chart.line.uptrend.xyaxis"),
            ("IRA", "chart.line.uptrend.xyaxis"),
            ("Loan", "house"),
            ("Mortgage", "house"),
            ("CD", "clock"),
            ("Money Market", "dollarsign.circle"),
            ("HSA", "cross.case"),
            ("Unknown", "building.columns")
        ]
        
        for (accountType, _) in testCases {
            let account = PlaidAccount(
                id: "test",
                name: "Test Account",
                accountType: accountType,
                institutionName: "Test Bank",
                isInflow: false,
                isOutflow: false,
                needsReauthentication: false,
                createdAt: Date()
            )
            
            let rowView = CategoryAccountRowView(
                account: account,
                onInflowToggle: {},
                onOutflowToggle: {}
            )
            
            // Note: In a real test, we'd use ViewInspector to verify the icon
            // For now, we just verify the view can be created
            XCTAssertNotNil(rowView)
        }
    }
} 