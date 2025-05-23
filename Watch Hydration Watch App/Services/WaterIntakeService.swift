//
//  WaterIntakeService.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
class WaterIntakeService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var todaysEntries: [WaterLogEntry] = []
    @Published var total: Double = 0
    @Published var goal: Double = 2000
    @Published var isHealthKitAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var progress: Double {
        HydrationCalculator.calculateProgress(entries: todaysEntries, goal: goal)
    }
    
    var remaining: Double {
        HydrationCalculator.calculateRemaining(entries: todaysEntries, goal: goal)
    }
    
    var isGoalReached: Bool {
        HydrationCalculator.isGoalReached(entries: todaysEntries, goal: goal)
    }
    
    var hourlyDistribution: [Int: Double] {
        HydrationCalculator.calculateHourlyDistribution(entries: todaysEntries)
    }
    
    // MARK: - Private Properties
    private var repository: WaterIntakeRepository
    private let healthKitRepository: HealthKitWaterRepository
    private let localRepository: LocalWaterRepository
    private let notificationService: NotificationService
    private let userDefaults: UserDefaults
    private let sharedDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadDate: Date = Date()
    
    // MARK: - Initialization
    init(
        useHealthKit: Bool = false,
        userDefaults: UserDefaults = .standard,
        sharedDefaults: UserDefaults? = nil
    ) {
        self.userDefaults = userDefaults
        self.sharedDefaults = sharedDefaults ?? UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? userDefaults
        self.notificationService = NotificationService()
        
        // Create both repositories
        self.healthKitRepository = HealthKitWaterRepository()
        self.localRepository = LocalWaterRepository(userDefaults: userDefaults)
        
        // Choose initial repository based on actual HealthKit status
        let healthKitAuthorized = healthKitRepository.isAuthorized()
        self.repository = (useHealthKit && healthKitAuthorized) ? healthKitRepository : localRepository
        
        // Set authorization status
        self.isHealthKitAuthorized = healthKitAuthorized
        
        loadSettings()
        setupObservers()
        
        Task {
            await checkAuthorizationAndLoad()
        }
    }
    
    // MARK: - Public Methods
    
    func requestHealthKitPermissions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check current status before requesting
            let wasAlreadyAuthorized = healthKitRepository.isAuthorized()
            
            let granted = try await healthKitRepository.requestPermissions()
            
            await MainActor.run {
                isHealthKitAuthorized = granted
                
                if granted {
                    // Switch to HealthKit repository
                    repository = healthKitRepository
                } else {
                    // Stay with local repository
                    repository = localRepository
                    
                    // If we weren't already authorized and still aren't,
                    // the user likely needs to enable in Settings
                    if !wasAlreadyAuthorized {
                        errorMessage = "HealthKit access was not granted. Please enable it in Settings > Privacy & Security > Health > Watch Hydration."
                    }
                }
                
                // Notify observers of the change
                objectWillChange.send()
            }
            
            if granted {
                await loadTodaysData()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to request permissions: \(error.localizedDescription)"
                isHealthKitAuthorized = false
                repository = localRepository
                objectWillChange.send()
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func addWaterEntry(amount: Double, date: Date = Date()) async {
        let entry = WaterLogEntry(date: date, amount: amount)
        
        do {
            try await repository.addEntry(entry)
            await loadTodaysData()
            
            if isGoalReached {
                await notificationService.notifyGoalReached()
            }
            
        } catch {
            errorMessage = "Failed to add entry: \(error.localizedDescription)"
        }
    }
    
    func clearTodaysEntries() async {
        do {
            try await repository.clearTodaysEntries()
            await loadTodaysData()
        } catch {
            errorMessage = "Failed to clear entries: \(error.localizedDescription)"
        }
    }
    
    func refreshData() async {
        await checkForDayChangeAndLoad()
    }
    
    func updateGoal(_ newGoal: Double) {
        goal = newGoal
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationAndLoad() async {
        // Check actual HealthKit authorization status
        let healthKitAuthorized = healthKitRepository.isAuthorized()
        
        await MainActor.run {
            isHealthKitAuthorized = healthKitAuthorized
            
            // Switch repository based on authorization
            if healthKitAuthorized {
                repository = healthKitRepository
            } else {
                repository = localRepository
            }
            
            // Notify observers of the change
            objectWillChange.send()
        }
        
        await loadTodaysData()
    }
    
    private func loadTodaysData() async {
        isLoading = true
        
        do {
            todaysEntries = try await repository.getTodaysEntries()
            total = HydrationCalculator.calculateTotal(entries: todaysEntries)
            saveToSharedDefaults()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func checkForDayChangeAndLoad() async {
        let calendar = Calendar.current
        if !calendar.isDate(lastLoadDate, inSameDayAs: Date()) {
            lastLoadDate = Date()
            await loadTodaysData()
        }
    }
    
    private func setupObservers() {
        // Watch for goal changes
        $goal
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.saveSettings()
                self?.saveToSharedDefaults()
            }
            .store(in: &cancellables)
        
        // Watch for total changes to update widgets
        $total
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.saveToSharedDefaults()
                self?.notificationService.scheduleWidgetUpdate()
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        let savedGoal = userDefaults.double(forKey: "hydrationGoal")
        if savedGoal > 0 {
            goal = savedGoal
        }
    }
    
    private func saveSettings() {
        userDefaults.set(goal, forKey: "hydrationGoal")
    }
    
    private func saveToSharedDefaults() {
        sharedDefaults.set(total, forKey: "hydrationTotal")
        sharedDefaults.set(goal, forKey: "hydrationGoal")
        sharedDefaults.synchronize()
    }
}

// MARK: - Notification Service
@MainActor
class NotificationService {
    
    func notifyGoalReached() async {
        // Implement goal reached notification
        print("🎉 Goal reached!")
    }
    
    func scheduleWidgetUpdate() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
    }
}
