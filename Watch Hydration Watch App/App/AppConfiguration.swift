//
//  AppConfiguration.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
struct AppConfiguration {
    static let shared = AppConfiguration()
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let hydrationGoal = "hydrationGoal"
        static let useHealthKit = "useHealthKit"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastResetDate = "lastResetDate"
    }
    
    // MARK: - App Group
    static let appGroupIdentifier = "group.com.thomaschatting.Watch-Hydration.Shared"
    
    // MARK: - Widget Configuration
    struct Widget {
        static let kind = "HydrationWidget"
    }
    
    // MARK: - Default Values
    struct Defaults {
        static let hydrationGoal: Double = 2000 // mL
        static let quickAddAmounts: [Double] = [100, 250, 500, 750, 1000]
    }
    
    private init() {}
}

// MARK: - Environment Setup
extension View {
    func configureHydrationApp() -> some View {
        self.onAppear {
            // Setup any app-wide configurations here
            setupAppDefaults()
        }
    }
    
    private func setupAppDefaults() {
        let defaults = UserDefaults.standard
        
        // Set default goal if not set
        if defaults.double(forKey: AppConfiguration.UserDefaultsKeys.hydrationGoal) == 0 {
            defaults.set(AppConfiguration.Defaults.hydrationGoal,
                        forKey: AppConfiguration.UserDefaultsKeys.hydrationGoal)
        }
    }
}

// MARK: - Dependency Injection Container
class DIContainer {
    static let shared = DIContainer()
    
    private let userDefaults: UserDefaults
    private let sharedDefaults: UserDefaults?
    
    var useHealthKit: Bool {
        userDefaults.bool(forKey: AppConfiguration.UserDefaultsKeys.useHealthKit)
    }
    
    private init() {
        self.userDefaults = .standard
        self.sharedDefaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)
    }
    
    // Factory methods that can be called from MainActor context
    @MainActor
    func createWaterIntakeService() -> WaterIntakeService {
        WaterIntakeService(
            useHealthKit: useHealthKit,
            userDefaults: userDefaults,
            sharedDefaults: sharedDefaults
        )
    }
    
    @MainActor
    func createHydrationViewModel() -> HydrationViewModel {
        HydrationViewModel(useHealthKit: useHealthKit)
    }
    
    func toggleHealthKit() {
        let newValue = !useHealthKit
        userDefaults.set(newValue, forKey: AppConfiguration.UserDefaultsKeys.useHealthKit)
    }
}

// MARK: - Environment Keys
struct WaterIntakeServiceKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = DIContainer.shared.createWaterIntakeService()
}

extension EnvironmentValues {
    var waterIntakeService: WaterIntakeService {
        get { self[WaterIntakeServiceKey.self] }
        set { self[WaterIntakeServiceKey.self] = newValue }
    }
}
