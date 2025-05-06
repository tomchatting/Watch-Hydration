import SwiftUI
import UserNotifications

struct ContentView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    private let defaultGoal: Double = 2000

    var body: some View {
        TabView {
            if !hasOnboarded {
                OnboardingView {
                    hasOnboarded = true
                }
            } else {
                WaterInputView()
                WaterProgressView()
                SettingsView()
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .onAppear {
            if hasOnboarded {
                if goal == 0 {
                    goal = defaultGoal
                    UserDefaults.standard.set(goal, forKey: "hydrationGoal")
                }

                NotificationManager.requestAuthorizationIfNeeded()
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        NotificationManager.scheduleHydrationSummaryIfNeeded()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
