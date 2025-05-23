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
    @StateObject private var viewModel = DIContainer.shared.createHydrationViewModel()

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
                        // First request HealthKit permissions
                        await viewModel.requestHealthKitPermissions()
                        
                        // Then handle notifications
                        NotificationManager.requestAuthorizationIfNeeded()
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            if settings.authorizationStatus == .authorized {
                                NotificationManager.scheduleHydrationSummaryIfNeeded()
                            }
                        }
                        
                        // Continue to main app
                        onContinue()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 30)
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }
}
