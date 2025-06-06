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
                    HStack(alignment: .center, spacing: TimSpacing.xl) {
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
                            .frame(width: 115, height: 115)
                    }
                    .padding(.top, TimSpacing.xxl * 2 + 6)
                    
                    Spacer()
                        .frame(maxHeight: TimSpacing.xl)
                    
                    // Input Fields Section - Card Container
                    VStack(spacing: TimSpacing.md) {
                        // Email Field with Label
                        VStack(alignment: .leading, spacing: TimSpacing.xs) {
                            Text("Email Address")
                                .font(.custom("SF Pro Display", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(TimColors.primaryText)
                            
                            TextField("you@example.com", text: $viewModel.email)
                                .font(.custom("SF Pro Display", size: 16))
                                .foregroundColor(TimColors.primaryText)
                                .padding(TimSpacing.md)
                                .background(TimColors.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                        .stroke(TimColors.black, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // PIN Field with Label
                        VStack(alignment: .leading, spacing: TimSpacing.xs) {
                            Text("PIN (4 digits)")
                                .font(.custom("SF Pro Display", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(TimColors.primaryText)
                            
                            SecureField("••••", text: $viewModel.pin)
                                .font(.custom("SF Pro Display", size: 16))
                                .foregroundColor(TimColors.primaryText)
                                .padding(TimSpacing.md)
                                .background(TimColors.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                        .stroke(TimColors.black, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(20)
                    .background(TimColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: TimCornerRadius.lg)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, TimSpacing.xl)
                    
                    Spacer()
                        .frame(height: TimSpacing.lg)
                    
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
                        // Sign In Button - Primary filled, full-width, 48px height
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                                .font(.custom("SF Pro Display", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(TimColors.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(TimColors.black)
                                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                        }
                        .disabled(viewModel.isLoading || !viewModel.isLoginButtonEnabled)
                        .opacity((viewModel.isLoading || !viewModel.isLoginButtonEnabled) ? 0.6 : 1.0)
                        
                        // Create Account Button - Secondary outline, full-width
                        Button(action: {
                            Task {
                                await viewModel.register()
                            }
                        }) {
                            Text("Create Account")
                                .font(.custom("SF Pro Display", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(TimColors.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                        .stroke(TimColors.black, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                        }
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