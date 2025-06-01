import Foundation
import SwiftUI

@MainActor
class PlaidLinkViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var linkToken: String?
    @Published var errorMessage: String?
    @Published var showingPlaidLink = false
    @Published var connectedAccounts: [PlaidAccount] = []
    
    // MARK: - Private Properties
    
    private let plaidService: PlaidServiceProtocol
    
    // MARK: - Initialization
    
    nonisolated init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self.plaidService = plaidService
    }
    
    // MARK: - Public Methods
    
    func loadSavedAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let accounts = try await plaidService.fetchAccounts()
            connectedAccounts = accounts
        } catch let error as PlaidError {
            // Don't show error for empty accounts - this is normal for new users
            if error != .accountsFetchFailed {
                errorMessage = error.localizedDescription
            }
        } catch {
            // Don't show error for empty accounts
            print("Could not load saved accounts: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func fetchLinkToken() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await plaidService.fetchLinkToken()
            linkToken = response.linkToken
        } catch let error as PlaidError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Unknown error occurred"
        }
        
        isLoading = false
    }
    
    func startPlaidLink() async {
        // If we don't have a link token, fetch one first
        if linkToken == nil {
            await fetchLinkToken()
        }
        
        // Only show Plaid Link if we successfully got a token
        if linkToken != nil && errorMessage == nil {
            showingPlaidLink = true
        }
    }
    
    func startPlaidLinkSync() {
        // Synchronous version for UI button actions
        Task {
            await startPlaidLink()
        }
    }
    
    func handlePlaidSuccess(publicToken: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Exchange the public token for account data
            let exchangeResponse = try await plaidService.exchangePublicToken(publicToken: publicToken)
            
            // Convert raw Plaid accounts to our app format
            let convertedAccounts = exchangeResponse.data.accounts.map { rawAccount in
                PlaidAccount(
                    id: rawAccount.account_id,
                    name: rawAccount.name,
                    accountType: rawAccount.subtype.capitalized,
                    institutionName: "Connected Bank", // We'll get this from institution data later
                    isInflow: false, // Default values - user can update later
                    isOutflow: false,
                    needsReauthentication: false,
                    createdAt: Date()
                )
            }
            
            connectedAccounts = convertedAccounts
            
            // Hide Plaid Link
            showingPlaidLink = false
            
        } catch let error as PlaidError {
            errorMessage = error.localizedDescription
            showingPlaidLink = false
        } catch {
            errorMessage = "Unknown error occurred: \(error.localizedDescription)"
            showingPlaidLink = false
        }
        
        isLoading = false
    }
    
    func handlePlaidExit() {
        showingPlaidLink = false
    }
    
    func refreshAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let accounts = try await plaidService.fetchAccounts()
            connectedAccounts = accounts
        } catch let error as PlaidError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Unknown error occurred"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
} 