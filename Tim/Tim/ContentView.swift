//
//  ContentView.swift
//  Tim
//
//  Created by Andrew De la Cruz on 5/31/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        Group {
            if loginViewModel.isAuthenticated {
                // Main app content (placeholder for now)
                MainAppView(loginViewModel: loginViewModel)
            } else {
                // Login flow
                LoginView(viewModel: loginViewModel)
            }
        }
        .onAppear {
            Task {
                await loginViewModel.checkExistingAuth()
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
            
            // Bank Accounts Tab
            PlaidLinkView()
                .tabItem {
                    Image(systemName: "building.columns")
                    Text("Accounts")
                }
            
            // Profile Tab
            ProfileView(loginViewModel: loginViewModel)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

// Dashboard View
struct DashboardView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Tim!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let user = loginViewModel.currentUser {
                    Text("Hello, \(user.email)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text("🎉 Authentication Complete!")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Your backend is connected and working!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Quick Actions
                VStack(spacing: 16) {
                    NavigationLink(destination: PlaidLinkView()) {
                        HStack {
                            Image(systemName: "building.columns")
                            Text("Connect Bank Account")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                Spacer()
            }
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
            VStack(spacing: 20) {
                
                if let user = loginViewModel.currentUser {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.email)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Member since \(user.createdAt, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    loginViewModel.logout()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
