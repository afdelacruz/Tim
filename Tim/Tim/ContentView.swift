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

// Placeholder for the main app content
struct MainAppView: View {
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
                
                Spacer()
                
                Button("Sign Out") {
                    loginViewModel.logout()
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Tim")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
