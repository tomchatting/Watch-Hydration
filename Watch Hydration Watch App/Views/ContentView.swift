import SwiftUI
import UserNotifications

struct ContentView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000 

        let defaultGoal: Double = 2000
    
    var body: some View {
        TabView {
            WaterInputView()
            WaterProgressView()
            SettingsView()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .onAppear {
            HealthKitManager.shared.requestAuthorization { success, error in
                if !success {
                    print("HealthKit not authorized: \(error?.localizedDescription ?? "Unknown")")
                }
            }
            
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
#Preview {
    ContentView()
}
