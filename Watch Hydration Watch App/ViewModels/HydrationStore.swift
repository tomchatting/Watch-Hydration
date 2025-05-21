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
    
    static let shared: HydrationStore = {
        let instance = HydrationStore()
        return instance
    }()
    
    private var cancellables = Set<AnyCancellable>()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    
    private init() {
        setupObservers()
        
        loadFromUserDefaults()
    }
    
    private func setupObservers() {
        progress.objectWillChange.sink { [weak self] _ in
            self?.saveToUserDefaults()
            self?.updateComplications()
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        logStore.objectWillChange.sink { [weak self] _ in
            Task {
                await self?.progress.loadToday()
                self?.saveToUserDefaults()
                self?.updateComplications()

                await MainActor.run {
                    self?.objectWillChange.send()
                }
            }
        }.store(in: &cancellables)
    }
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(progress.total, forKey: "hydrationTotal")
        UserDefaults.standard.set(progress.goal, forKey: "hydrationGoal")
        
        sharedDefaults.set(progress.total, forKey: "hydrationTotal")
        sharedDefaults.set(progress.goal, forKey: "hydrationGoal")
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
    
    private func updateComplications() {
        #if os(watchOS)
        let complicationServer = CLKComplicationServer.sharedInstance()
        
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
        objectWillChange.send()
    }
    
    func notifyDataChanged() {
        objectWillChange.send()
    }
}
