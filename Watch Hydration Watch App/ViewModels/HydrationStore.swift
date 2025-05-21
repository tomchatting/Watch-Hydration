// HydrationStore.swift
import SwiftUI
import Combine
import ClockKit

@MainActor
class HydrationStore: ObservableObject {
    @Published var logStore = WaterLogStore()
    @Published var healthKitStatus = HealthKitAuthStatus()
    @Published var progress = HydrationProgress()
    @Published var animationManager = BubbleConfettiManager()
    
    // Singleton pattern with a simpler implementation
    static let shared: HydrationStore = {
        let instance = HydrationStore()
        return instance
    }()
    
    private var cancellables = Set<AnyCancellable>()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration") ?? UserDefaults.standard
    
    private init() {
        // Set up observers for progress changes
        setupObservers()
        
        // Load any saved data from UserDefaults
        loadFromUserDefaults()
    }
    
    private func setupObservers() {
        // Listen for changes in hydration progress
        progress.objectWillChange.sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.updateComplications()
            // Explicitly tell SwiftUI we've changed
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        // Also observe logStore changes
        logStore.objectWillChange.sink { [weak self] _ in
            // When logStore changes, reload progress data
            Task {
                await self?.progress.loadToday()
                self?.saveToUserDefaults()
                self?.updateComplications()
                // Explicitly tell SwiftUI we've changed
                await MainActor.run {
                    self?.objectWillChange.send()
                }
            }
        }.store(in: &cancellables)
    }
    
    // Save hydration data to UserDefaults so complications can access it
    func saveToUserDefaults() {
        // Save to both standard and shared UserDefaults
        UserDefaults.standard.set(progress.total, forKey: "hydrationTotal")
        UserDefaults.standard.set(progress.goal, forKey: "hydrationGoal")
        
        // Also save to shared container for widgets
        sharedDefaults.set(progress.total, forKey: "hydrationTotal")
        sharedDefaults.set(progress.goal, forKey: "hydrationGoal")
    }
    
    // Load hydration data from UserDefaults
    func loadFromUserDefaults() {
        // Try shared defaults first
        var savedTotal = sharedDefaults.double(forKey: "hydrationTotal")
        var savedGoal = sharedDefaults.double(forKey: "hydrationGoal")
        
        // If not in shared defaults, try standard defaults
        if savedTotal == 0 {
            savedTotal = UserDefaults.standard.double(forKey: "hydrationTotal")
        }
        
        if savedGoal == 0 {
            savedGoal = UserDefaults.standard.double(forKey: "hydrationGoal")
        }
        
        // Only update if we have valid values
        if savedTotal > 0 {
            progress.total = savedTotal
        }
        
        if savedGoal > 0 {
            progress.goal = savedGoal
        }
    }
    
    // Update watch complications when data changes
    private func updateComplications() {
        #if os(watchOS)
        // Get the complication server
        let complicationServer = CLKComplicationServer.sharedInstance()
        
        // Reload all active complications
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
        #endif
    }
    
    func refreshData() async {
        await progress.loadToday()
        saveToUserDefaults()
        // Explicitly trigger UI update
        objectWillChange.send()
    }
    
    // Helper method to refresh UI across the app
    func notifyDataChanged() {
        objectWillChange.send()
    }
}
