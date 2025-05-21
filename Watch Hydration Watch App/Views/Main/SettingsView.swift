//
//  SettingsView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import ClockKit

struct SettingsView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    @State private var showingDebugMenu = false
    @EnvironmentObject private var hydrationStore: HydrationStore
    let minGoal: Double = 500
    let maxGoal: Double = 3000
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var appBuild: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack {
            VStack {
                Slider(value: $goal, in: minGoal...maxGoal, step: 100) {
                    Text("Goal: \(Int(goal)) mL")
                }
                .onChange(of: goal) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "hydrationGoal")
                    hydrationStore.progress.goal = newValue
                    hydrationStore.saveToUserDefaults()
                }

                Text("Goal: \(Int(goal)) mL")
                    .font(.caption)
                    .padding()
            }
            .padding()
            
            VStack {
                if hydrationStore.healthKitStatus.isAuthorized {
                    Label("HealthKit enabled", systemImage: "heart.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.top, 5)
                } else {
                    Label("HealthKit disabled", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .padding(.top, 5)
                }
            }
            
            VStack {
                Text("Version: \(appVersion) (\(appBuild))")
                    .font(.caption2)
                Text("© 2025 Thomas Chatting")
                    .font(.caption2)
            }
            
            VStack {
                #if DEBUG
                Button(action: {
                    showingDebugMenu = true
                }) {
                    Image(systemName: "hammer.circle")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .sheet(isPresented: $showingDebugMenu) {
                    SimpleDebugView(hydrationStore: hydrationStore)
                }
                #endif
            }
        }
        .onAppear {
            // Sync the @AppStorage value with the hydrationStore value on appear
            hydrationStore.progress.goal = goal
            Task {
                await hydrationStore.refreshData()
            }
        }
    }
}

struct SimpleDebugView: View {
    @ObservedObject var hydrationStore: HydrationStore
    @State private var actionInProgress = false
    @State private var complicationMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Debug Menu")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading) {
                    Text("Current Progress: \(Int(hydrationStore.progress.total))/\(Int(hydrationStore.progress.goal)) ml")
                        .font(.subheadline)
                    
                    Text("Goal percentage: \(Int((hydrationStore.progress.total / max(1, hydrationStore.progress.goal)) * 100))%")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
                Button("Delete Today's Progress") {
                    guard !actionInProgress else { return }
                    actionInProgress = true
                    
                    Task {
                        hydrationStore.logStore.clearTodayEntries()
                        
                        if hydrationStore.healthKitStatus.isAuthorized {
                            HealthKitManager.shared.deleteAllWaterEntriesForToday()
                        }
                        
                        await hydrationStore.progress.loadToday()
                        hydrationStore.saveToUserDefaults()
                        
                        actionInProgress = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(actionInProgress)
                
                Button("Set Progress Near Goal (95%)") {
                    guard !actionInProgress else { return }
                    actionInProgress = true
                    
                    Task {
                        // Clear first
                        hydrationStore.logStore.clearTodayEntries()
                        if hydrationStore.healthKitStatus.isAuthorized {
                            HealthKitManager.shared.deleteAllWaterEntriesForToday()
                        }
                        
                        // Then add near-goal amount
                        let nearGoalAmount = hydrationStore.progress.goal * 0.95
                        hydrationStore.logStore.log(amount: nearGoalAmount)
                        
                        if hydrationStore.healthKitStatus.isAuthorized {
                            HealthKitManager.shared.logWater(amountInML: nearGoalAmount)
                        }
                        
                        await hydrationStore.progress.loadToday()
                        hydrationStore.saveToUserDefaults()
                        
                        actionInProgress = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(actionInProgress)
                
                Button("Refresh Complications") {
                    let result = refreshComplications()
                    complicationMessage = result
                }
                .buttonStyle(.bordered)
                
                if !complicationMessage.isEmpty {
                    Text(complicationMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if actionInProgress {
                    ProgressView()
                        .padding(.top, 5)
                }
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding()
        }
    }
    
    func refreshComplications() -> String {
        let server = CLKComplicationServer.sharedInstance()

        guard let complications = server.activeComplications, !complications.isEmpty else {
            return "⚠️ No active complications found."
        }

        for complication in complications {
            server.reloadTimeline(for: complication)
            server.extendTimeline(for: complication)
        }
        
        return "🔄 Reloaded \(complications.count) complications"
    }
}
