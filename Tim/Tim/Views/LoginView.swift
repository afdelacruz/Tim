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
                VStack(spacing: TimSpacing.lg) {
                    // Header with side-by-side layout
                    HStack(alignment: .center, spacing: TimSpacing.lg) {
                        // Text section
                        VStack(alignment: .leading, spacing: TimSpacing.xs) {
                            Text("Welcome to Tim")
                                .font(.custom("SF Pro Display", size: 32))
                                .fontWeight(.semibold)
                                .foregroundColor(TimColors.primaryText)
                            
                            Text("Your personal finance companion")
                                .font(.custom("SF Pro Display", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#4A4A4A"))
                        }
                        
                        // Tim figure section
                        Image("TimWaving")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                    .padding(.top, TimSpacing.xxl * 2)
                    
                    Spacer()
                        .frame(maxHeight: TimSpacing.xl)
                    
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
                            style: viewModel.isLoginButtonEnabled && !viewModel.isLoading ? .primary : .outline
                        )
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        
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