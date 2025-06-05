import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var isRegistering = false
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: TimSpacing.xl) {
                // Tim Character with Greeting
                VStack(spacing: TimSpacing.lg) {
                    TimCharacter(
                        message: "Hey, I'm Tim! Do you need help with your finances?",
                        size: .large
                    )
                    
                    Text("Time is money")
                        .font(TimTypography.callout)
                        .foregroundColor(TimColors.secondaryText)
                }
                .padding(.top, TimSpacing.xxl)
                
                Spacer()
                
                // Input Fields
                VStack(spacing: TimSpacing.md) {
                    // Email TextField
                    VStack(alignment: .leading, spacing: TimSpacing.sm) {
                        Text("Email")
                            .font(TimTypography.headline)
                            .foregroundColor(TimColors.primaryText)
                        
                        TimTextField("Enter your email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // PIN SecureField
                    VStack(alignment: .leading, spacing: TimSpacing.sm) {
                        Text("PIN")
                            .font(TimTypography.headline)
                            .foregroundColor(TimColors.primaryText)
                        
                        TimTextField("Enter 4-digit PIN", text: $viewModel.pin, isSecure: true)
                            .keyboardType(.numberPad)
                    }
                }
                .padding(.horizontal, TimSpacing.xl)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(TimColors.error)
                        .font(TimTypography.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, TimSpacing.xl)
                }
                
                // Buttons
                VStack(spacing: TimSpacing.md) {
                    // Login Button
                    TimButton(
                        title: viewModel.isLoading ? "Signing In..." : "Sign In",
                        action: {
                            Task {
                                await viewModel.login()
                            }
                        },
                        style: .primary
                    )
                    .disabled(!viewModel.isLoginButtonEnabled || viewModel.isLoading)
                    .opacity(viewModel.isLoginButtonEnabled && !viewModel.isLoading ? 1.0 : 0.6)
                    
                    // Register Button
                    TimButton(
                        title: "Create Account",
                        action: {
                            Task {
                                await viewModel.register()
                            }
                        },
                        style: .outline
                    )
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                }
                .padding(.horizontal, TimSpacing.xl)
                
                Spacer()
                
                // Footer
                Text("Secure authentication with PIN")
                    .font(TimTypography.caption)
                    .foregroundColor(TimColors.secondaryText)
                    .padding(.bottom, TimSpacing.lg)
            }
            .timBackground()
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.checkExistingAuth()
                }
            }
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel())
} 