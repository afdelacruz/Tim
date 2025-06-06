//
//  ContentView.swift
//  Tim
//
//  Created by Andrew De la Cruz on 5/31/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    // DEVELOPMENT: Set to true to bypass login during development
    private let isDevelopmentMode = false
    
    var body: some View {
        Group {
            if isDevelopmentMode || loginViewModel.isAuthenticated {
                // Main app content with TabView navigation
                MainAppView(loginViewModel: loginViewModel)
            } else if !hasSeenOnboarding {
                // Show onboarding for first-time users
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                })
            } else {
                // Login flow for returning users
                LoginView(viewModel: loginViewModel)
            }
        }
        .onAppear {
            if !isDevelopmentMode {
                Task {
                    await loginViewModel.checkExistingAuth()
                }
            }
        }
    }
}

// Main app content with TabView navigation
struct MainAppView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView(loginViewModel: loginViewModel)
                .tabItem {
                    Image(systemName: "house")
                    Text("Dashboard")
                }
            
            // Profile Tab
            ProfileView(loginViewModel: loginViewModel)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(TimColors.black)
    }
}

// Dashboard View
struct DashboardView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: TimSpacing.xl) {
                // Tim Character and User Greeting
                VStack(spacing: TimSpacing.lg) {
                    TimCharacter(
                        message: "",
                        size: .medium
                    )
                    
                    if let user = loginViewModel.currentUser {
                        Text("Hello, \(user.email.components(separatedBy: "@").first ?? "there")!")
                            .font(TimTypography.headline)
                            .foregroundColor(TimColors.primaryText)
                    }
                }
                .padding(.top, TimSpacing.lg)
                
                // Quick Actions
                VStack(spacing: TimSpacing.md) {
                    NavigationLink(destination: PlaidConnectView()) {
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundColor(TimColors.primaryText)
                            Text("Connect Bank Account")
                                .font(TimTypography.body)
                                .foregroundColor(TimColors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(TimColors.primaryText)
                        }
                        .padding(TimSpacing.md)
                        .background(TimColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                .stroke(TimColors.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                    }
                    
                    NavigationLink(destination: AccountOverviewView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(TimColors.primaryText)
                            Text("Configure Categories")
                                .font(TimTypography.body)
                                .foregroundColor(TimColors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(TimColors.primaryText)
                        }
                        .padding(TimSpacing.md)
                        .background(TimColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                .stroke(TimColors.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                    }
                }
                .padding(.horizontal, TimSpacing.xl)
                
                Spacer()
            }
            .timBackground()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Profile View
struct ProfileView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: TimSpacing.xl) {
                
                if let user = loginViewModel.currentUser {
                    VStack(spacing: TimSpacing.lg) {
                        // Tim Character for Profile
                        TimCharacter(
                            message: "Here's your profile info!",
                            size: .medium
                        )
                        
                        VStack(spacing: TimSpacing.sm) {
                            Text(user.email)
                                .font(TimTypography.title2)
                                .foregroundColor(TimColors.primaryText)
                            
                            Text("Member since \(user.createdAt, style: .date)")
                                .font(TimTypography.callout)
                                .foregroundColor(TimColors.secondaryText)
                        }
                    }
                    .padding(.top, TimSpacing.xl)
                }
                
                Spacer()
                
                TimButton(
                    title: "Sign Out",
                    action: {
                        loginViewModel.logout()
                    },
                    style: .outline
                )
                .padding(.horizontal, TimSpacing.xl)
                .padding(.bottom, TimSpacing.xl)
            }
            .timBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
