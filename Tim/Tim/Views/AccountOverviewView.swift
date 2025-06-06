import SwiftUI
import LinkKit

struct AccountOverviewView: View {
    @StateObject private var viewModel = AccountOverviewViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TimSpacing.lg) {
                    // Header Section
                    headerSection
                    
                    // Accounts List Section
                    accountsSection
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorMessageView(errorMessage)
                    }
                    
                    // Add Account Button
                    addAccountButton
                    
                    Spacer(minLength: TimSpacing.xl)
                }
                .padding(.horizontal, TimSpacing.xl)
                .padding(.bottom, TimSpacing.xl)
            }
            .timBackground()
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadAccounts()
                }
            }
        }
        .sheet(isPresented: $viewModel.showingPlaidLink) {
            if let linkToken = viewModel.linkToken {
                PlaidLinkRepresentable(
                    linkToken: linkToken,
                    onSuccess: { publicToken in
                        Task {
                            await viewModel.handlePlaidSuccess(publicToken: publicToken)
                        }
                    },
                    onExit: {
                        viewModel.handlePlaidExit()
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingAccountSettings) {
            if let account = viewModel.selectedAccount {
                AccountSettingsView(
                    account: account,
                    onDismiss: {
                        viewModel.showingAccountSettings = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: TimSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: TimSpacing.xs) {
                    Text("Configure Categories")
                        .font(.custom("SF Pro Display", size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(TimColors.primaryText)
                    
                    Text("Set up inflow and outflow accounts")
                        .font(.custom("SF Pro Display", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#4A4A4A"))
                }
                
                Spacer()
                
                // Tim character
                Image("TimWaving")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
        }
        .padding(.top, TimSpacing.xxl)
    }
    
    // MARK: - Accounts Section
    private var accountsSection: some View {
        VStack(spacing: TimSpacing.md) {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.accounts.isEmpty {
                emptyStateView
            } else {
                accountsList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: TimSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your accounts...")
                .font(.custom("SF Pro Display", size: 16))
                .foregroundColor(TimColors.secondaryText)
        }
        .frame(height: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: TimSpacing.lg) {
            VStack(spacing: TimSpacing.md) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 48))
                    .foregroundColor(TimColors.secondaryText)
                
                Text("No Accounts to Configure")
                    .font(.custom("SF Pro Display", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(TimColors.primaryText)
                
                Text("Connect bank accounts first, then return here to set up categories")
                    .font(.custom("SF Pro Display", size: 16))
                    .foregroundColor(TimColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(TimSpacing.xl)
            .background(TimColors.white)
            .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .frame(height: 200)
    }
    
    private var accountsList: some View {
        LazyVStack(spacing: TimSpacing.md) {
            ForEach(viewModel.accounts) { account in
                AccountOverviewRowView(account: account)
            }
        }
    }
    
    // MARK: - Error Message
    private func errorMessageView(_ message: String) -> some View {
        VStack(spacing: TimSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(TimColors.error)
                Text(message)
                    .font(.custom("SF Pro Display", size: 14))
                    .foregroundColor(TimColors.error)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            Button("Dismiss") {
                viewModel.clearError()
            }
            .font(.custom("SF Pro Display", size: 14))
            .foregroundColor(TimColors.error)
        }
        .padding(TimSpacing.md)
        .background(TimColors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
    }
    
    // MARK: - Add Account Button
    private var addAccountButton: some View {
        Button(action: {
            // TODO: Navigate to Plaid Link flow
            viewModel.addAccountTapped()
        }) {
            HStack(spacing: TimSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                
                Text(viewModel.accounts.isEmpty ? "Go to Dashboard" : "Add More Accounts")
                    .font(.custom("SF Pro Display", size: 16))
                    .fontWeight(.semibold)
            }
            .foregroundColor(TimColors.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(TimColors.black)
            .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
}

// MARK: - Account Overview Row View
struct AccountOverviewRowView: View {
    let account: PlaidAccount
    
    var body: some View {
        HStack(spacing: TimSpacing.md) {
            // Bank Icon
            bankIcon
            
            // Account Info
            VStack(alignment: .leading, spacing: TimSpacing.xs) {
                Text(account.name)
                    .font(.custom("SF Pro Display", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(TimColors.primaryText)
                
                Text(account.institutionName)
                    .font(.custom("SF Pro Display", size: 14))
                    .foregroundColor(TimColors.secondaryText)
                
                Text(account.accountType)
                    .font(.custom("SF Pro Display", size: 12))
                    .foregroundColor(TimColors.secondaryText)
            }
            
            Spacer()
            
            // Category Checkboxes
            VStack(alignment: .trailing, spacing: TimSpacing.sm) {
                // Inflow Checkbox
                HStack(spacing: TimSpacing.xs) {
                    Text("Inflow")
                        .font(.custom("SF Pro Display", size: 12))
                        .foregroundColor(TimColors.primaryText)
                    
                    Button(action: {
                        // TODO: Toggle inflow
                    }) {
                        Image(systemName: account.isInflow ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(account.isInflow ? Color.green : TimColors.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Outflow Checkbox
                HStack(spacing: TimSpacing.xs) {
                    Text("Outflow")
                        .font(.custom("SF Pro Display", size: 12))
                        .foregroundColor(TimColors.primaryText)
                    
                    Button(action: {
                        // TODO: Toggle outflow
                    }) {
                        Image(systemName: account.isOutflow ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(account.isOutflow ? Color.red : TimColors.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(TimSpacing.lg)
        .background(TimColors.white)
        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var bankIcon: some View {
        Circle()
            .fill(TimColors.black)
            .frame(width: 44, height: 44)
            .overlay(
                Text(String(account.institutionName.prefix(1)))
                    .font(.custom("SF Pro Display", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(TimColors.white)
            )
    }
    
    private var statusIndicator: some View {
        HStack(spacing: TimSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.custom("SF Pro Display", size: 12))
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        if account.needsReauthentication {
            return Color.orange
        } else {
            return Color.green
        }
    }
    
    private var statusText: String {
        if account.needsReauthentication {
            return "Needs Update"
        } else {
            return "Connected"
        }
    }
}

// MARK: - ViewModel
@MainActor
class AccountOverviewViewModel: ObservableObject {
    @Published var accounts: [PlaidAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPlaidLink = false
    @Published var linkToken: String?
    @Published var showingAccountSettings = false
    @Published var selectedAccount: PlaidAccount?
    
    private let plaidService: PlaidServiceProtocol
    
    init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self.plaidService = plaidService
    }
    
    func loadAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch real accounts from API
            accounts = try await plaidService.fetchAccounts()
        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
            accounts = []
        }
        
        isLoading = false
    }
    
    func addAccountTapped() {
        Task {
            await startPlaidLinkFlow()
        }
    }
    
    private func startPlaidLinkFlow() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await plaidService.fetchLinkToken()
            linkToken = response.linkToken
            showingPlaidLink = true
        } catch {
            errorMessage = "Failed to start account connection: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func handlePlaidSuccess(publicToken: String) async {
        do {
            _ = try await plaidService.exchangePublicToken(publicToken: publicToken)
            showingPlaidLink = false
            // Reload accounts to show the newly connected account
            await loadAccounts()
        } catch {
            errorMessage = "Failed to connect account: \(error.localizedDescription)"
            showingPlaidLink = false
        }
    }
    
    func handlePlaidExit() {
        showingPlaidLink = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func showAccountSettings(for account: PlaidAccount) {
        selectedAccount = account
        showingAccountSettings = true
    }
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    let account: PlaidAccount
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: TimSpacing.lg) {
                // Account Info Header
                VStack(spacing: TimSpacing.md) {
                    Circle()
                        .fill(TimColors.black)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(account.institutionName.prefix(1)))
                                .font(.custom("SF Pro Display", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(TimColors.white)
                        )
                    
                    VStack(spacing: TimSpacing.xs) {
                        Text(account.name)
                            .font(.custom("SF Pro Display", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(TimColors.primaryText)
                        
                        Text(account.institutionName)
                            .font(.custom("SF Pro Display", size: 16))
                            .foregroundColor(TimColors.secondaryText)
                        
                        Text(account.accountType)
                            .font(.custom("SF Pro Display", size: 14))
                            .foregroundColor(TimColors.secondaryText)
                    }
                }
                .padding(.top, TimSpacing.xl)
                
                // Settings Options
                VStack(spacing: TimSpacing.md) {
                    settingsRow(
                        icon: "arrow.clockwise",
                        title: "Refresh Account",
                        subtitle: "Update account information"
                    ) {
                        // TODO: Implement refresh
                    }
                    
                    settingsRow(
                        icon: "slider.horizontal.3",
                        title: "Update Categories",
                        subtitle: "Change inflow/outflow settings"
                    ) {
                        // TODO: Navigate to category config
                    }
                    
                    settingsRow(
                        icon: "trash",
                        title: "Disconnect Account",
                        subtitle: "Remove this account from Tim",
                        isDestructive: true
                    ) {
                        // TODO: Implement disconnect
                    }
                }
                .padding(.horizontal, TimSpacing.xl)
                
                Spacer()
            }
            .timBackground()
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(TimColors.black)
                }
            }
        }
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: TimSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isDestructive ? TimColors.error : TimColors.black)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: TimSpacing.xs) {
                    Text(title)
                        .font(.custom("SF Pro Display", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? TimColors.error : TimColors.primaryText)
                    
                    Text(subtitle)
                        .font(.custom("SF Pro Display", size: 14))
                        .foregroundColor(TimColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(TimColors.secondaryText)
            }
            .padding(TimSpacing.lg)
            .background(TimColors.white)
            .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AccountOverviewView()
} 