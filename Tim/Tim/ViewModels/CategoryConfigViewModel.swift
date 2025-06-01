import Foundation
import SwiftUI

@MainActor
class CategoryConfigViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var accounts: [PlaidAccount] = []
    
    // MARK: - Private Properties
    
    private let plaidService: PlaidServiceProtocol
    
    // MARK: - Computed Properties
    
    var inflowAccounts: [PlaidAccount] {
        accounts.filter { $0.isInflow }
    }
    
    var outflowAccounts: [PlaidAccount] {
        accounts.filter { $0.isOutflow }
    }
    
    // MARK: - Initialization
    
    nonisolated init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self.plaidService = plaidService
    }
    
    // MARK: - Public Methods
    
    func loadAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedAccounts = try await plaidService.fetchAccounts()
            accounts = fetchedAccounts
        } catch let error as PlaidError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateAccountCategory(accountId: String, isInflow: Bool, isOutflow: Bool) async {
        // Find the account first
        guard let accountIndex = accounts.firstIndex(where: { $0.id == accountId }) else {
            errorMessage = "Account not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Store original state in case we need to revert
        let originalAccount = accounts[accountIndex]
        
        do {
            // Optimistically update local state
            accounts[accountIndex] = PlaidAccount(
                id: originalAccount.id,
                name: originalAccount.name,
                accountType: originalAccount.accountType,
                institutionName: originalAccount.institutionName,
                isInflow: isInflow,
                isOutflow: isOutflow,
                needsReauthentication: originalAccount.needsReauthentication,
                createdAt: originalAccount.createdAt
            )
            
            // Update on backend
            _ = try await plaidService.updateAccountCategories(
                accountId: accountId,
                isInflow: isInflow,
                isOutflow: isOutflow
            )
            
        } catch let error as PlaidError {
            // Revert local state on error
            accounts[accountIndex] = originalAccount
            errorMessage = error.localizedDescription
        } catch {
            // Revert local state on error
            accounts[accountIndex] = originalAccount
            errorMessage = "Failed to update account categories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleInflowCategory(for account: PlaidAccount) async {
        await updateAccountCategory(
            accountId: account.id,
            isInflow: !account.isInflow,
            isOutflow: account.isOutflow
        )
    }
    
    func toggleOutflowCategory(for account: PlaidAccount) async {
        await updateAccountCategory(
            accountId: account.id,
            isInflow: account.isInflow,
            isOutflow: !account.isOutflow
        )
    }
    
    func clearError() {
        errorMessage = nil
    }
} 