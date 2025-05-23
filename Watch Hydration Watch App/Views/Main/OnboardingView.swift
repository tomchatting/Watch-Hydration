//
//  OnboardingView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var onContinue: () -> Void
    @State private var isCompletingOnboarding = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Welcome to Watch Hydration")
                        .font(.title3)
                        .bold()
                }
                
                Text("This app allows you to easily log your liquid intake, with HealthKit integration.")
                
                Text("Watch Hydration uses HealthKit to:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Log your water intake")
                    Text("• Show your hydration progress")
                }
                .font(.body)

                Text("Your data stays on-device and is never shared.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                Button("Continue") {
                    Task {
                        isCompletingOnboarding = true
                        
                        // Request HealthKit permissions (show dialog)
                        let healthKitRepo = HealthKitWaterRepository()
                        try? await healthKitRepo.requestPermissions()
                        
                        // Request notification permissions
                        NotificationManager.requestAuthorizationIfNeeded()
                        
                        // Small delay to let permission dialogs dismiss
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        // Mark onboarding as complete and restart
                        await MainActor.run {
                            onContinue()
                        }
                    }
                }
                .disabled(isCompletingOnboarding)
                .buttonStyle(.borderedProminent)
                .padding(.top, 30)
                
                if isCompletingOnboarding {
                    ProgressView()
                        .padding(.top, 10)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }
}
