//
//  HydrationViewModel.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HydrationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var waterIntakeService: WaterIntakeService
    @Published var showingGoalSheet = false
    @Published var showingHistorySheet = false
    @Published var selectedAmount: Double = 250
    @Published var customAmount: String = ""
    @Published var showingCustomAmountAlert = false
    @Published var confettiManager = ConfettiManager()
    
    // MARK: - Computed Properties
    var progressPercentage: String {
        let percentage = waterIntakeService.progress * 100
        return String(format: "%.0f%%", percentage)
    }
    
    var totalFormatted: String {
        return formatAmount(waterIntakeService.total)
    }
    
    var goalFormatted: String {
        return formatAmount(waterIntakeService.goal)
    }
    
    var remainingFormatted: String {
        return formatAmount(waterIntakeService.remaining)
    }
    
    // MARK: - Quick Add Amounts
    let quickAddAmounts: [Double] = [100, 250, 500, 750, 1000]
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(useHealthKit: Bool = false) {
        self.waterIntakeService = WaterIntakeService(useHealthKit: useHealthKit)
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    func addWater(amount: Double) async {
        let wasGoalReached = waterIntakeService.isGoalReached
        await waterIntakeService.addWaterEntry(amount: amount)
        
        // Trigger confetti if goal was just reached
        if !wasGoalReached && waterIntakeService.isGoalReached {
            confettiManager.triggerConfetti()
        }
    }
    
    func addCustomAmount() async {
        guard let amount = Double(customAmount), amount > 0 else {
            return
        }
        
        await addWater(amount: amount)
        customAmount = ""
        showingCustomAmountAlert = false
    }
    
    func clearToday() async {
        await waterIntakeService.clearTodaysEntries()
    }
    
    func updateGoal(to newGoal: Double) {
        waterIntakeService.updateGoal(newGoal)
    }
    
    func requestHealthKitPermissions() async {
        await waterIntakeService.requestHealthKitPermissions()
    }
    
    func refreshData() async {
        await waterIntakeService.refreshData()
    }
    
    // MARK: - Formatting Helpers
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fL", amount / 1000)
        } else {
            return String(format: "%.0fmL", amount)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Watch for changes in the water intake service
        waterIntakeService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UI Helper Extensions
extension HydrationViewModel {
    
    var progressColor: Color {
        switch waterIntakeService.progress {
        case 0..<0.3:
            return .secondary
        case 0.3..<0.7:
            return .accentColor
        case 0.7..<1.0:
            return .blue
        default:
            return .green
        }
    }
    
    var motivationalMessage: String {
        switch waterIntakeService.progress {
        case 0..<0.25:
            return "Let's get started! 💧"
        case 0.25..<0.5:
            return "Great start! Keep going! 🌊"
        case 0.5..<0.75:
            return "You're halfway there! 💪"
        case 0.75..<1.0:
            return "Almost at your goal! 🎯"
        default:
            return "Goal achieved! Amazing! 🎉"
        }
    }
    
    var shouldShowCelebration: Bool {
        return waterIntakeService.isGoalReached
    }
    
    var shouldShowConfetti: Bool {
        return confettiManager.showConfetti
    }
}
