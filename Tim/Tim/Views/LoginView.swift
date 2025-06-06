import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var isRegistering = false
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: TimSpacing.xl) {
                    // Header with Tim branding
                    VStack(spacing: TimSpacing.sm) {
                        Text("Tim")
                            .font(TimTypography.largeTitle)
                            .foregroundColor(TimColors.primaryText)
                            .fontWeight(.bold)
                        
                        Text("Time is money")
                            .font(TimTypography.title3)
                            .foregroundColor(TimColors.secondaryText)
                    }
                    .padding(.top, TimSpacing.xxl * 2)
                    
                    Spacer()
                    
                    // Input Fields Section
                    VStack(spacing: TimSpacing.lg) {
                        // Email TextField
                        TimTextField("Enter your email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        // PIN SecureField
                        TimTextField("Enter 4-digit PIN", text: $viewModel.pin, isSecure: true)
                            .keyboardType(.numberPad)
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
                    
                    // Buttons Section
                    VStack(spacing: TimSpacing.md) {
                        // Sign In Button
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
                        
                        // Create Account Button
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
                    Spacer()
                }
                
                // Small Tim character in bottom left corner
                VStack {
                    Spacer()
                    HStack {
                        TimCharacter(
                            message: "Ready to help!",
                            size: .small
                        )
                        Spacer()
                    }
                    .padding(.leading, TimSpacing.lg)
                    .padding(.bottom, TimSpacing.lg)
                }
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