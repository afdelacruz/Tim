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
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Account Categories")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Configure which accounts contribute to your monthly inflows and outflows")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
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
                                        onInflowToggle: {
                                            Task {
                                                await viewModel.toggleInflowCategory(for: account)
                                            }
                                        },
                                        onOutflowToggle: {
                                            Task {
                                                await viewModel.toggleOutflowCategory(for: account)
                                            }
                                        }
                                    )
                                    .disabled(viewModel.isLoading)
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
    let onInflowToggle: () -> Void
    let onOutflowToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Account Icon
            VStack {
                Image(systemName: accountIcon)
                    .font(.title2)
                    .foregroundColor(accountColor)
                    .frame(width: 40, height: 40)
                    .background(accountColor.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Account Details
            VStack(alignment: .leading, spacing: 6) {
                Text(account.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(account.accountType)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(account.institutionName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Category Toggles
            HStack(spacing: 16) {
                // Inflow Toggle
                Button(action: onInflowToggle) {
                    HStack(spacing: 6) {
                        Image(systemName: account.isInflow ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(account.isInflow ? .green : .gray)
                            .font(.title3)
                        
                        Text("In")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(account.isInflow ? .green : .gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Outflow Toggle
                Button(action: onOutflowToggle) {
                    HStack(spacing: 6) {
                        Image(systemName: account.isOutflow ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(account.isOutflow ? .red : .gray)
                            .font(.title3)
                        
                        Text("Out")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(account.isOutflow ? .red : .gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 16)
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