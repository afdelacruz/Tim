import SwiftUI

struct CategoryConfigView: View {
    
    @StateObject private var viewModel: CategoryConfigViewModel
    
    @MainActor init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self._viewModel = StateObject(wrappedValue: CategoryConfigViewModel(plaidService: plaidService))
    }
    
    // For testing with pre-configured ViewModel
    @MainActor init(viewModel: CategoryConfigViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            
                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Loading State
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Updating categories...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Account Categories Section
                    if !viewModel.accounts.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Section Header
                            HStack {
                                Text("Account Categories")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text("\(viewModel.accounts.count) accounts")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Category Legend
                            HStack(spacing: 20) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                    Text("Inflow")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                    Text("Outflow")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Account List
                            VStack(spacing: 12) {
                                ForEach(viewModel.accounts) { account in
                                    CategoryAccountRowView(
                                        account: account,
                                        isLoading: viewModel.isLoading,
                                        onInflowToggle: {
                                            print("🔄 Inflow toggle tapped for account: \(account.name)")
                                            Task {
                                                await viewModel.toggleInflowCategory(for: account)
                                            }
                                        },
                                        onOutflowToggle: {
                                            print("🔄 Outflow toggle tapped for account: \(account.name)")
                                            Task {
                                                await viewModel.toggleOutflowCategory(for: account)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    } else if !viewModel.isLoading {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No Accounts Found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Connect bank accounts first to configure categories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .timBackground()
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadAccounts()
        }
    }
}

// MARK: - Category Account Row View

struct CategoryAccountRowView: View {
    let account: PlaidAccount
    let isLoading: Bool
    let onInflowToggle: () -> Void
    let onOutflowToggle: () -> Void
    
    var body: some View {
        HStack(spacing: TimSpacing.md) {
            // Account Icon
            Circle()
                .fill(TimColors.black)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(account.institutionName.prefix(1)))
                        .font(.custom("SF Pro Display", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TimColors.white)
                )
            
            // Account Details
            VStack(alignment: .leading, spacing: TimSpacing.xs) {
                Text(account.name)
                    .font(.custom("SF Pro Display", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(TimColors.primaryText)
                    .lineLimit(1)
                
                Text(account.institutionName)
                    .font(.custom("SF Pro Display", size: 14))
                    .foregroundColor(TimColors.secondaryText)
                    .lineLimit(1)
                
                Text(account.accountType)
                    .font(.custom("SF Pro Display", size: 12))
                    .foregroundColor(TimColors.secondaryText)
                    .lineLimit(1)
                
                // Balance Display
                Text(formatBalance(account.currentBalance))
                    .font(.custom("SF Pro Display", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(balanceColor(for: account))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Category Toggles
            VStack(alignment: .trailing, spacing: TimSpacing.sm) {
                // Inflow Toggle
                HStack(spacing: TimSpacing.xs) {
                    Text("Inflow")
                        .font(.custom("SF Pro Display", size: 12))
                        .foregroundColor(TimColors.primaryText)
                    
                    Button(action: {
                        print("🟢 BUTTON ACTION CALLED - Inflow for \(account.name)")
                        onInflowToggle()
                    }) {
                        Image(systemName: account.isInflow ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(account.isInflow ? Color.green : TimColors.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLoading)
                }
                
                // Outflow Toggle
                HStack(spacing: TimSpacing.xs) {
                    Text("Outflow")
                        .font(.custom("SF Pro Display", size: 12))
                        .foregroundColor(TimColors.primaryText)
                    
                    Button(action: {
                        print("🟢 BUTTON ACTION CALLED - Outflow for \(account.name)")
                        onOutflowToggle()
                    }) {
                        Image(systemName: account.isOutflow ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(account.isOutflow ? Color.red : TimColors.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLoading)
                }
            }
        }
        .padding(TimSpacing.lg)
        .background(TimColors.white)
        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, TimSpacing.lg)
    }
    
    // MARK: - Helper Functions
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        if balance == 0 {
            return "No balance data"
        }
        
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }
    
    private func balanceColor(for account: PlaidAccount) -> Color {
        if account.currentBalance == 0 {
            return TimColors.secondaryText
        }
        
        // Color based on account type and balance
        let type = account.accountType.lowercased()
        
        if type.contains("credit") {
            // For credit cards, higher balance is bad (more debt)
            return account.currentBalance > 1000 ? .red : .orange
        } else if type.contains("loan") || type.contains("mortgage") {
            // For loans, any balance is debt
            return .red
        } else {
            // For deposit accounts, positive balance is good
            return account.currentBalance > 0 ? .green : .red
        }
    }
    
    // MARK: - Computed Properties
    
    private var accountIcon: String {
        let type = account.accountType.lowercased()
        
        if type.contains("checking") {
            return "creditcard"
        } else if type.contains("savings") || type.contains("saving") {
            return "banknote"
        } else if type.contains("credit") {
            return "creditcard.circle"
        } else if type.contains("investment") || type.contains("401k") || type.contains("ira") {
            return "chart.line.uptrend.xyaxis"
        } else if type.contains("loan") || type.contains("mortgage") {
            return "house"
        } else if type.contains("cd") {
            return "clock"
        } else if type.contains("money market") {
            return "dollarsign.circle"
        } else if type.contains("hsa") {
            return "cross.case"
        } else {
            return "building.columns"
        }
    }
    
    private var accountColor: Color {
        let type = account.accountType.lowercased()
        
        if type.contains("checking") {
            return .blue
        } else if type.contains("savings") || type.contains("saving") {
            return .green
        } else if type.contains("credit") {
            return .purple
        } else if type.contains("investment") || type.contains("401k") || type.contains("ira") {
            return .orange
        } else if type.contains("loan") || type.contains("mortgage") {
            return .red
        } else if type.contains("cd") {
            return .indigo
        } else if type.contains("money market") {
            return .mint
        } else if type.contains("hsa") {
            return .pink
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

struct CategoryConfigView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryConfigView()
    }
} 