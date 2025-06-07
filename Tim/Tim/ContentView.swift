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
                    
                    NavigationLink(destination: CategoryConfigView()) {
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
                
                // Widget Preview
                VStack(spacing: TimSpacing.sm) {
                    HStack {
                        Text("Your Widget")
                            .font(TimTypography.headline)
                            .foregroundColor(TimColors.primaryText)
                        Spacer()
                    }
                    
                    // Square Widget Preview Container
                    TimWidgetPreview()
                        .frame(width: 155, height: 155) // iOS small widget size
                        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.lg))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

// MARK: - Widget Preview Component
struct WidgetData {
    let inflow: Double
    let outflow: Double
    let isPlaceholder: Bool
    let lastUpdated: Date?
    
    init(inflow: Double = 0, outflow: Double = 0, isPlaceholder: Bool = false, lastUpdated: Date? = nil) {
        self.inflow = inflow
        self.outflow = outflow
        self.isPlaceholder = isPlaceholder
        self.lastUpdated = lastUpdated
    }
}

struct TimWidgetPreview: View {
    @State private var widgetData: WidgetData = WidgetData(isPlaceholder: true)
    
    var body: some View {
        VStack(spacing: 4) {
            // Status indicator in top-right
            HStack {
                Spacer()
                Circle()
                    .fill(widgetData.isPlaceholder ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            // Centered numbers
            VStack(spacing: 4) {
                Text(widgetData.isPlaceholder ? "+--" : "+$\(Int(widgetData.inflow))")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(widgetData.isPlaceholder ? "-+--" : "-$\(Int(widgetData.outflow))")
                    .foregroundColor(.red)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Spacer()
            
            // Last updated at bottom
            Text(widgetData.lastUpdated != nil ? "Updated" : "Loading...")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.white)
        .onAppear {
            Task {
                await loadWidgetData()
            }
        }
    }
    
    private func loadWidgetData() async {
        // Try to get cached widget data or fetch fresh data
        if let cachedData = getCachedWidgetData() {
            widgetData = cachedData
        } else {
            // Show placeholder while loading
            widgetData = WidgetData(isPlaceholder: true)
            
            // Try to fetch fresh data
            if let freshData = await fetchWidgetData() {
                widgetData = freshData
            }
        }
    }
    
    private func getCachedWidgetData() -> WidgetData? {
        // Check shared UserDefaults for cached widget data
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget"),
              let cachedInflow = sharedDefaults.object(forKey: "cached_inflow") as? Double,
              let cachedOutflow = sharedDefaults.object(forKey: "cached_outflow") as? Double,
              let lastUpdatedTimestamp = sharedDefaults.object(forKey: "last_updated") as? TimeInterval else {
            return nil
        }
        
        let lastUpdated = Date(timeIntervalSince1970: lastUpdatedTimestamp)
        
        // Check if data is recent (within last hour)
        if Date().timeIntervalSince(lastUpdated) < 3600 {
            return WidgetData(
                inflow: cachedInflow,
                outflow: cachedOutflow,
                isPlaceholder: false,
                lastUpdated: lastUpdated
            )
        }
        
        return nil
    }
    
    private func fetchWidgetData() async -> WidgetData? {
        // Use sample data for now - in real implementation, this would call your API
        let sampleData = WidgetData(
            inflow: 2340,
            outflow: 1890,
            isPlaceholder: false,
            lastUpdated: Date()
        )
        
        // Cache the data
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tim.widget") {
            sharedDefaults.set(sampleData.inflow, forKey: "cached_inflow")
            sharedDefaults.set(sampleData.outflow, forKey: "cached_outflow")
            sharedDefaults.set(sampleData.lastUpdated?.timeIntervalSince1970 ?? 0, forKey: "last_updated")
        }
        
        return sampleData
    }
}

#Preview {
    ContentView()
}
