import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let totalPages = 3
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1 - Main Introduction
            OnboardingPage1()
                .tag(0)
            
            // Page 2 - How it works (placeholder for now)
            OnboardingPage2()
                .tag(1)
            
            // Page 3 - Widget preview (placeholder for now)
            OnboardingPage3()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .timBackground()
        .overlay(
            // Skip button
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        // TODO: Navigate to login/register
                        print("Skip tapped")
                    }
                    .font(TimTypography.body)
                    .foregroundColor(TimColors.primaryText)
                    .padding(.trailing, TimSpacing.lg)
                    .padding(.top, TimSpacing.lg)
                }
                Spacer()
            }
        )
        .overlay(
            // Page indicators
            VStack {
                Spacer()
                HStack(spacing: TimSpacing.sm) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? TimColors.primaryText : TimColors.secondaryText)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 120) // Space for Get Started button
            }
        )
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: TimSpacing.xl) {
            // Top spacing
            Spacer()
                .frame(height: TimSpacing.xxl)
            
            // Title
            Text("Time is Money")
                .font(TimTypography.largeTitle)
                .foregroundColor(TimColors.primaryText)
                .padding(.top, TimSpacing.lg)
            
            // Middle content with Tim character
            VStack(spacing: TimSpacing.lg) {
                Text("Checking your money should be as easy as checking the time")
                    .font(TimTypography.title2)
                    .foregroundColor(TimColors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Tim character below the text
                TimCharacter(
                    message: "",
                    size: .extraLarge
                )
                .padding(.top, TimSpacing.md)
            }
            .padding(.horizontal, TimSpacing.xl)
            
            Spacer()
            
            // Get Started button
            TimButton(
                title: "Get Started",
                action: {
                    // TODO: Navigate to registration
                    print("Get Started tapped")
                },
                style: .primary
            )
            .padding(.horizontal, TimSpacing.xl)
            .padding(.bottom, TimSpacing.xxl)
        }
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: TimSpacing.xl) {
            // Top spacing
            Spacer()
                .frame(height: TimSpacing.xl)
            
            // How it works image
            Image("TimHowItWorks")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
                .padding(.top, TimSpacing.lg)
            
            // Steps
            VStack(spacing: TimSpacing.lg) {
                OnboardingStep(number: "1", text: "Connect your bank accounts securely")
                OnboardingStep(number: "2", text: "Choose which are for inflows/outflows")
                OnboardingStep(number: "3", text: "Add the widget to your home screen")
                OnboardingStep(number: "4", text: "Glance anytime to see your money flow!")
            }
            .padding(.horizontal, TimSpacing.xl)
            
            Spacer()
            
            // Next button
            TimButton(
                title: "Next",
                action: {
                    // TODO: Navigate to next page
                    print("Next tapped")
                },
                style: .primary
            )
            .padding(.horizontal, TimSpacing.xl)
            .padding(.bottom, TimSpacing.xxl)
        }
    }
}

struct OnboardingStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: TimSpacing.md) {
            // Step number
            Text(number)
                .font(TimTypography.headline)
                .foregroundColor(TimColors.white)
                .frame(width: 32, height: 32)
                .background(TimColors.black)
                .clipShape(Circle())
            
            // Step text
            Text(text)
                .font(TimTypography.body)
                .foregroundColor(TimColors.primaryText)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: TimSpacing.xl) {
            // Top spacing
            Spacer()
            
            // Widget preview section
            VStack(spacing: TimSpacing.lg) {
                Text("And now you have your widget!")
                    .font(TimTypography.title2)
                    .foregroundColor(TimColors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Small square widget preview (iOS standard size)
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Centered content
                    VStack(spacing: TimSpacing.xs) {
                        // Inflow
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("+$2,340")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(TimColors.primaryText)
                            Spacer()
                        }
                        
                        // Outflow
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("-$1,890")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(TimColors.primaryText)
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    // Date at bottom
                    HStack {
                        Text("Jan 1-31")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(TimColors.secondaryText)
                        Spacer()
                    }
                }
                .padding(8)
                .background(TimColors.creamBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(width: 120, height: 120)
                
                Text("Simple and clean!")
                    .font(TimTypography.body)
                    .foregroundColor(TimColors.secondaryText)
            }
            .padding(.horizontal, TimSpacing.xl)
            
            Spacer()
            
            // Final CTA button
            TimButton(
                title: "Let's Set It Up!",
                action: {
                    // TODO: Navigate to login/register
                    print("Let's Set It Up tapped")
                },
                style: .primary
            )
            .padding(.horizontal, TimSpacing.xl)
            .padding(.bottom, TimSpacing.xxl)
        }
    }
}

#Preview {
    OnboardingView()
} 