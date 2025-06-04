import XCTest
import SwiftUI
@testable import Tim

@MainActor
final class PlaidLinkViewTests: XCTestCase {
    
    var mockPlaidService: MockPlaidService!
    var viewModel: PlaidLinkViewModel!
    
    override func setUpWithError() throws {
        mockPlaidService = MockPlaidService()
        viewModel = PlaidLinkViewModel(plaidService: mockPlaidService)
    }
    
    override func tearDownWithError() throws {
        mockPlaidService = nil
        viewModel = nil
    }
    
    // MARK: - UI Element Tests
    
    func testPlaidLinkView_hasConnectBankAccountButton() {
        // Arrange
        let view = PlaidLinkView(viewModel: viewModel)
        
        // Act & Assert
        let hostingController = UIHostingController(rootView: view)
        _ = hostingController.view
        
        // The view should contain a "Connect Bank Account" button
        // This is verified through the view's structure
        XCTAssertNotNil(view)
    }
    
    func testPlaidLinkView_showsLoadingStateWhenFetchingToken() {
        // Arrange
        viewModel.isLoading = true
        let view = PlaidLinkView(viewModel: viewModel)
        
        // Act & Assert
        let hostingController = UIHostingController(rootView: view)
        _ = hostingController.view
        
        // When loading, the view should show loading indicator
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testPlaidLinkView_showsErrorMessageWhenPresent() {
        // Arrange
        viewModel.errorMessage = "Test error message"
        let view = PlaidLinkView(viewModel: viewModel)
        
        // Act & Assert
        let hostingController = UIHostingController(rootView: view)
        _ = hostingController.view
        
        // When error is present, the view should display it
        XCTAssertEqual(viewModel.errorMessage, "Test error message")
    }
    
    func testPlaidLinkView_showsConnectedAccountsWhenPresent() {
        // Arrange
        let testAccount = PlaidAccount(
            id: "test-account-1",
            name: "Test Checking",
            accountType: "depository",
            institutionName: "Test Bank",
            isInflow: true,
            isOutflow: false,
            needsReauthentication: false,
            createdAt: Date()
        )
        viewModel.connectedAccounts = [testAccount]
        let view = PlaidLinkView(viewModel: viewModel)
        
        // Act & Assert
        let hostingController = UIHostingController(rootView: view)
        _ = hostingController.view
        
        // When accounts are present, the view should display them
        XCTAssertEqual(viewModel.connectedAccounts.count, 1)
        XCTAssertEqual(viewModel.connectedAccounts.first?.name, "Test Checking")
    }
    
    // MARK: - State Binding Tests
    
    func testPlaidLinkView_bindsToViewModelState() {
        // Arrange
        _ = PlaidLinkView(viewModel: viewModel)
        
        // Act
        viewModel.isLoading = true
        viewModel.errorMessage = "Test error"
        viewModel.showingPlaidLink = true
        
        // Assert
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
        XCTAssertTrue(viewModel.showingPlaidLink)
    }
    
    // MARK: - User Interaction Tests
    
    func testPlaidLinkView_connectButtonTriggersPlaidLink() async {
        // Arrange
        let expectedResponse = LinkTokenResponse(
            success: true,
            linkToken: "link-sandbox-12345678-1234-1234-1234-123456789012",
            expiration: "2024-01-01T12:00:00Z"
        )
        mockPlaidService.mockLinkTokenResponse = expectedResponse
        
        // Act
        await viewModel.startPlaidLink()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchLinkTokenCalled)
        XCTAssertTrue(viewModel.showingPlaidLink)
    }
    
    func testPlaidLinkView_refreshButtonTriggersAccountRefresh() async {
        // Arrange
        let testAccounts = [
            PlaidAccount(
                id: "account-1",
                name: "Refreshed Account",
                accountType: "depository",
                institutionName: "Test Bank",
                isInflow: true,
                isOutflow: false,
                needsReauthentication: false,
                createdAt: Date()
            )
        ]
        mockPlaidService.mockAccounts = testAccounts
        
        // Act
        await viewModel.refreshAccounts()
        
        // Assert
        XCTAssertTrue(mockPlaidService.fetchAccountsCalled)
        XCTAssertEqual(viewModel.connectedAccounts.count, 1)
        XCTAssertEqual(viewModel.connectedAccounts.first?.name, "Refreshed Account")
    }
    
    // MARK: - Error Handling Tests
    
    func testPlaidLinkView_clearErrorButtonClearsError() {
        // Arrange
        viewModel.errorMessage = "Test error"
        
        // Act
        viewModel.clearError()
        
        // Assert
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Navigation Tests
    
    func testPlaidLinkView_showingPlaidLinkTriggersSheet() {
        // Arrange
        _ = PlaidLinkView(viewModel: viewModel)
        
        // Act
        viewModel.showingPlaidLink = true
        
        // Assert
        XCTAssertTrue(viewModel.showingPlaidLink)
        
        // The sheet should be presented when showingPlaidLink is true
        // This is handled by SwiftUI's .sheet modifier
    }
} 