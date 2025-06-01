import XCTest
@testable import Tim

@MainActor
final class CategoryConfigViewModelTests: XCTestCase {
    
    var viewModel: CategoryConfigViewModel!
    var mockPlaidService: MockPlaidService!
    
    override func setUpWithError() throws {
        mockPlaidService = MockPlaidService()
        viewModel = CategoryConfigViewModel(plaidService: mockPlaidService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockPlaidService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInit_setsInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.accounts.isEmpty)
    }
    
    // MARK: - Load Accounts Tests
    
    func testLoadAccounts_whenServiceSucceeds_updatesAccountsAndClearsLoading() async {
        // Given
        let expectedAccounts = [
            PlaidAccount(id: "1", name: "Chase Checking", accountType: "Checking", institutionName: "Chase", isInflow: true, isOutflow: false, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "2", name: "Ally Savings", accountType: "Savings", institutionName: "Ally", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date())
        ]
        mockPlaidService.mockAccounts = expectedAccounts
        
        // When
        await viewModel.loadAccounts()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.accounts.count, 2)
        XCTAssertEqual(viewModel.accounts[0].name, "Chase Checking")
        XCTAssertEqual(viewModel.accounts[1].name, "Ally Savings")
    }
    
    func testLoadAccounts_whenServiceFails_updatesErrorStateAndClearsLoading() async {
        // Given
        mockPlaidService.shouldFailFetchAccounts = true
        
        // When
        await viewModel.loadAccounts()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.accounts.isEmpty)
    }
    
    func testLoadAccounts_setsLoadingStateDuringOperation() async {
        // Given
        mockPlaidService.fetchAccountsDelay = 0.1
        
        // When
        let loadTask = Task {
            await viewModel.loadAccounts()
        }
        
        // Then - Check loading state is set
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Update Category Tests
    
    func testUpdateAccountCategory_whenServiceSucceeds_updatesLocalAccountAndClearsError() async {
        // Given
        let account = PlaidAccount(id: "1", name: "Chase Checking", accountType: "Checking", institutionName: "Chase", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date())
        viewModel.accounts = [account]
        mockPlaidService.shouldSucceedUpdateCategories = true
        
        // When
        await viewModel.updateAccountCategory(accountId: "1", isInflow: true, isOutflow: false)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.accounts[0].isInflow, true)
        XCTAssertEqual(viewModel.accounts[0].isOutflow, false)
    }
    
    func testUpdateAccountCategory_whenServiceFails_keepsOriginalStateAndShowsError() async {
        // Given
        let account = PlaidAccount(id: "1", name: "Chase Checking", accountType: "Checking", institutionName: "Chase", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date())
        viewModel.accounts = [account]
        mockPlaidService.shouldFailUpdateCategories = true
        
        // When
        await viewModel.updateAccountCategory(accountId: "1", isInflow: true, isOutflow: false)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        // Original state should be preserved
        XCTAssertEqual(viewModel.accounts[0].isInflow, false)
        XCTAssertEqual(viewModel.accounts[0].isOutflow, false)
    }
    
    func testUpdateAccountCategory_forNonExistentAccount_showsError() async {
        // Given
        viewModel.accounts = []
        
        // When
        await viewModel.updateAccountCategory(accountId: "nonexistent", isInflow: true, isOutflow: false)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Account not found") == true)
    }
    
    // MARK: - Toggle Category Tests
    
    func testToggleInflowCategory_updatesAccountCorrectly() async {
        // Given
        let account = PlaidAccount(id: "1", name: "Chase Checking", accountType: "Checking", institutionName: "Chase", isInflow: false, isOutflow: true, needsReauthentication: false, createdAt: Date())
        viewModel.accounts = [account]
        mockPlaidService.shouldSucceedUpdateCategories = true
        
        // When
        await viewModel.toggleInflowCategory(for: account)
        
        // Then
        XCTAssertEqual(viewModel.accounts[0].isInflow, true)
        XCTAssertEqual(viewModel.accounts[0].isOutflow, true) // Should preserve outflow setting
    }
    
    func testToggleOutflowCategory_updatesAccountCorrectly() async {
        // Given
        let account = PlaidAccount(id: "1", name: "Chase Checking", accountType: "Checking", institutionName: "Chase", isInflow: true, isOutflow: false, needsReauthentication: false, createdAt: Date())
        viewModel.accounts = [account]
        mockPlaidService.shouldSucceedUpdateCategories = true
        
        // When
        await viewModel.toggleOutflowCategory(for: account)
        
        // Then
        XCTAssertEqual(viewModel.accounts[0].isInflow, true) // Should preserve inflow setting
        XCTAssertEqual(viewModel.accounts[0].isOutflow, true)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_resetsErrorMessage() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Account Filtering Tests
    
    func testInflowAccounts_returnsOnlyInflowAccounts() {
        // Given
        let accounts = [
            PlaidAccount(id: "1", name: "Inflow Only", accountType: "Checking", institutionName: "Bank1", isInflow: true, isOutflow: false, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "2", name: "Outflow Only", accountType: "Credit", institutionName: "Bank2", isInflow: false, isOutflow: true, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "3", name: "Both", accountType: "Checking", institutionName: "Bank3", isInflow: true, isOutflow: true, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "4", name: "Neither", accountType: "Savings", institutionName: "Bank4", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date())
        ]
        viewModel.accounts = accounts
        
        // When
        let inflowAccounts = viewModel.inflowAccounts
        
        // Then
        XCTAssertEqual(inflowAccounts.count, 2)
        XCTAssertTrue(inflowAccounts.contains { $0.name == "Inflow Only" })
        XCTAssertTrue(inflowAccounts.contains { $0.name == "Both" })
    }
    
    func testOutflowAccounts_returnsOnlyOutflowAccounts() {
        // Given
        let accounts = [
            PlaidAccount(id: "1", name: "Inflow Only", accountType: "Checking", institutionName: "Bank1", isInflow: true, isOutflow: false, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "2", name: "Outflow Only", accountType: "Credit", institutionName: "Bank2", isInflow: false, isOutflow: true, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "3", name: "Both", accountType: "Checking", institutionName: "Bank3", isInflow: true, isOutflow: true, needsReauthentication: false, createdAt: Date()),
            PlaidAccount(id: "4", name: "Neither", accountType: "Savings", institutionName: "Bank4", isInflow: false, isOutflow: false, needsReauthentication: false, createdAt: Date())
        ]
        viewModel.accounts = accounts
        
        // When
        let outflowAccounts = viewModel.outflowAccounts
        
        // Then
        XCTAssertEqual(outflowAccounts.count, 2)
        XCTAssertTrue(outflowAccounts.contains { $0.name == "Outflow Only" })
        XCTAssertTrue(outflowAccounts.contains { $0.name == "Both" })
    }
} 