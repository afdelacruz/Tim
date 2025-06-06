import SwiftUI
import LinkKit

struct PlaidConnectView: View {
    @StateObject private var viewModel = PlaidConnectViewModel()
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TimSpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Security Reassurance Section
                    securitySection
                    
                    // Connect Button
                    connectButton
                    
                    Spacer(minLength: TimSpacing.xl)
                }
                .padding(.horizontal, TimSpacing.xl)
                .padding(.bottom, TimSpacing.xl)
            }
            .timBackground()
            .navigationBarHidden(true)
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
        .alert("Account Connected!", isPresented: $viewModel.showingSuccessAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your bank account has been successfully connected to Tim!")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: TimSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TimSpacing.xs) {
                    Text("Connect Your Bank")
                        .font(.custom("SF Pro Display", size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(TimColors.primaryText)
                    
                    Text("Let's get your accounts connected safely")
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
        .padding(.top, TimSpacing.xl)
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: TimSpacing.lg) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.green)
                
                VStack(alignment: .leading, spacing: TimSpacing.xs) {
                    Text("Your data is safe with us")
                        .font(.custom("SF Pro Display", size: 20))
                        .fontWeight(.semibold)
                        .foregroundColor(TimColors.primaryText)
                    
                    Text("We use bank-level security to protect your information")
                        .font(.custom("SF Pro Display", size: 16))
                        .foregroundColor(TimColors.secondaryText)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: TimSpacing.md) {
                securityPoint("🔒 Read-only access - we can't move your money")
                securityPoint("🛡️ Your login details are never stored")
                securityPoint("✅ Powered by Plaid - trusted by millions")
            }
        }
        .padding(TimSpacing.xl)
        .background(Color.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: TimCornerRadius.lg)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func securityPoint(_ text: String) -> some View {
        Text(text)
            .font(.custom("SF Pro Display", size: 16))
            .foregroundColor(TimColors.primaryText)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Connect Button
    private var connectButton: some View {
        VStack(spacing: TimSpacing.md) {
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(TimColors.error)
                    Text(errorMessage)
                        .font(.custom("SF Pro Display", size: 14))
                        .foregroundColor(TimColors.error)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(TimSpacing.md)
                .background(TimColors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
            }
            
            Button(action: {
                Task {
                    await viewModel.startPlaidConnection()
                }
            }) {
                HStack(spacing: TimSpacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "building.columns")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(viewModel.isLoading ? "Connecting..." : "Connect Bank Account")
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
            .opacity(viewModel.isLoading ? 0.8 : 1.0)
        }
    }
}

// MARK: - ViewModel
@MainActor
class PlaidConnectViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPlaidLink = false
    @Published var linkToken: String?
    @Published var showingSuccessAlert = false
    
    private let plaidService: PlaidServiceProtocol
    
    init(plaidService: PlaidServiceProtocol = PlaidService()) {
        self.plaidService = plaidService
    }
    
    func startPlaidConnection() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await plaidService.fetchLinkToken()
            linkToken = response.linkToken
            showingPlaidLink = true
        } catch {
            errorMessage = "Failed to start connection: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func handlePlaidSuccess(publicToken: String) async {
        do {
            _ = try await plaidService.exchangePublicToken(publicToken: publicToken)
            showingPlaidLink = false
            showingSuccessAlert = true
        } catch {
            errorMessage = "Failed to connect account: \(error.localizedDescription)"
            showingPlaidLink = false
        }
    }
    
    func handlePlaidExit() {
        showingPlaidLink = false
    }
}

#Preview {
    PlaidConnectView()
} 