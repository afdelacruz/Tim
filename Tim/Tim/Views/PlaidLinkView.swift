import SwiftUI
import LinkKit

struct PlaidLinkView: View {
    
    @StateObject private var viewModel: PlaidLinkViewModel
    
    @MainActor init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self._viewModel = StateObject(wrappedValue: PlaidLinkViewModel(plaidService: plaidService))
    }
    
    // For testing with pre-configured ViewModel
    @MainActor init(viewModel: PlaidLinkViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                
                // Header
                if viewModel.connectedAccounts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Connect Your Bank")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Securely link your bank accounts to track your finances")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                // Connected Accounts Section
                if !viewModel.connectedAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Connected Accounts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(viewModel.connectedAccounts.count) accounts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.connectedAccounts) { account in
                                AccountRowView(account: account)
                                    .onTapGesture {
                                        // TODO: Navigate to account details
                                        print("Tapped account: \(account.name)")
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                
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
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    
                    // Connect Bank Account Button
                    Button(action: {
                        viewModel.startPlaidLinkSync()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle")
                            }
                            Text(viewModel.connectedAccounts.isEmpty ? "Connect Bank Account" : "Add Another Account")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Refresh Accounts Button (only show if accounts exist)
                    if !viewModel.connectedAccounts.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.refreshAccounts()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Accounts")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                }
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .navigationTitle("Bank Accounts")
            .navigationBarTitleDisplayMode(.inline)
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
        .task {
            // Always load saved accounts on view appear
            await viewModel.loadSavedAccounts()
        }
    }
}

// MARK: - Account Row View

struct AccountRowView: View {
    let account: PlaidAccount
    
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
                
                // Status badges
                HStack(spacing: 6) {
                    if account.isInflow {
                        StatusBadge(text: "Income", color: .green, icon: "arrow.down.circle")
                    }
                    
                    if account.isOutflow {
                        StatusBadge(text: "Expense", color: .red, icon: "arrow.up.circle")
                    }
                    
                    if account.needsReauthentication {
                        StatusBadge(text: "Reauth", color: .orange, icon: "exclamationmark.triangle")
                    }
                    
                    if !account.isInflow && !account.isOutflow && !account.needsReauthentication {
                        StatusBadge(text: "Connected", color: .blue, icon: "checkmark.circle")
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

// MARK: - Plaid Link UIViewControllerRepresentable

struct PlaidLinkRepresentable: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return PlaidLinkViewController(
            linkToken: linkToken,
            onSuccess: onSuccess,
            onExit: onExit
        )
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

class PlaidLinkViewController: UIViewController {
    private let linkToken: String
    private let onSuccess: (String) -> Void
    private let onExit: () -> Void
    private var handler: Handler?
    
    init(linkToken: String, onSuccess: @escaping (String) -> Void, onExit: @escaping () -> Void) {
        self.linkToken = linkToken
        self.onSuccess = onSuccess
        self.onExit = onExit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Only setup Plaid Link after the view is in the window hierarchy
        if handler == nil {
            setupPlaidLink()
        }
    }
    
    private func setupPlaidLink() {
        var linkConfiguration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { [weak self] linkSuccess in
                self?.onSuccess(linkSuccess.publicToken)
            }
        )
        
        linkConfiguration.onExit = { [weak self] linkExit in
            self?.onExit()
        }
        
        linkConfiguration.onEvent = { linkEvent in
            print("Plaid Link Event: \(linkEvent.eventName)")
        }
        
        let result = Plaid.create(linkConfiguration)
        switch result {
        case .failure(let error):
            print("Unable to create Plaid handler due to: \(error)")
            showError(error.localizedDescription)
            
        case .success(let handler):
            self.handler = handler
            let presentationMethod: PresentationMethod = .viewController(self)
            handler.open(presentUsing: presentationMethod)
        }
    }
    
    private func showError(_ message: String) {
        let alertController = UIAlertController(
            title: "Plaid Link Error",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onExit()
        })
        present(alertController, animated: true)
    }
}

// MARK: - Preview

struct PlaidLinkView_Previews: PreviewProvider {
    static var previews: some View {
        PlaidLinkView()
    }
} 