// HydrationStore.swift
import SwiftUI
import Combine
import WidgetKit

@MainActor
class HydrationStore: ObservableObject {
    @Published var logStore = WaterLogStore()
    @Published var healthKitStatus = HealthKitAuthStatus()
    @Published var progress = HydrationProgress()
    @Published var animationManager = ConfettiManager()
    
    static let shared: HydrationStore = {
        let instance = HydrationStore()
        return instance
    }()
    
    private var cancellables = Set<AnyCancellable>()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    private var lastUpdateDate: Date = Date()
    
    private init() {
        setupObservers()
        loadFromUserDefaults()
        checkForDayChange()
    }
    
    private func setupObservers() {
        progress.objectWillChange.sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        logStore.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                await self?.progress.loadToday()
                
                self?.saveToUserDefaults()
                
                WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
                
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }
    
    private func checkForDayChange() {
        let calendar = Calendar.current
        if !calendar.isDate(lastUpdateDate, inSameDayAs: Date()) {
            // New day detected
            Task {
                await logStore.resetForNewDay()
                await refreshData()
            }
            lastUpdateDate = Date()
        }
    }
    
    func refreshIfNeeded() async {
        checkForDayChange()
        await refreshData()
    }
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(progress.total, forKey: "hydrationTotal")
        UserDefaults.standard.set(progress.goal, forKey: "hydrationGoal")
        
        sharedDefaults.set(progress.total, forKey: "hydrationTotal")
        sharedDefaults.set(progress.goal, forKey: "hydrationGoal")
        sharedDefaults.synchronize() // Ensure immediate sync for widgets
    }
    
    func loadFromUserDefaults() {
        var savedTotal = sharedDefaults.double(forKey: "hydrationTotal")
        var savedGoal = sharedDefaults.double(forKey: "hydrationGoal")
        
        if savedTotal == 0 {
            savedTotal = UserDefaults.standard.double(forKey: "hydrationTotal")
        }
        
        if savedGoal == 0 {
            savedGoal = UserDefaults.standard.double(forKey: "hydrationGoal")
        }
        
        if savedTotal > 0 {
            progress.total = savedTotal
        }
        
        if savedGoal > 0 {
            progress.goal = savedGoal
        }
    }
    
    func refreshData() async {
        await progress.loadToday()
        saveToUserDefaults()
        objectWillChange.send()
    }
    
    func notifyDataChanged() {
        objectWillChange.send()
    }
}
