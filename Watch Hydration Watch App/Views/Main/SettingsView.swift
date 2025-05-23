//
//  SettingsView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
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
                Slider(value: $hydrationStore.progress.goal, in: minGoal...maxGoal, step: 100) {
                    Text("Goal: \(Int(hydrationStore.progress.goal)) mL")
                }
                .onChange(of: hydrationStore.progress.goal) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "hydrationGoal")
                    WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
                }
                .onDisappear {
                    let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared")
                    sharedDefaults?.set(hydrationStore.progress.goal, forKey: "hydrationGoal")
                }

                Text("Goal: \(Int(hydrationStore.progress.goal)) mL")
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
                    ScrollView {
                        Text("Debug Menu")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("Current Progress: \(Int(hydrationStore.progress.total))/\(Int(hydrationStore.progress.goal)) ml")
                                .font(.subheadline)
                            
                            Text("Goal percentage: \(Int((hydrationStore.progress.total / max(1, hydrationStore.progress.goal)) * 100))%")
                                .font(.subheadline)
                        }
                        
                        Button("Delete Today's Progress") {
                            Task {
                                await hydrationStore.logStore.clearTodayEntries()
                                HealthKitManager.shared.deleteAllWaterEntriesForToday()
                                await hydrationStore.progress.loadToday()
                                showingDebugMenu = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button("Set Progress Near Goal (95%)") {
                            Task {
                                await hydrationStore.logStore.clearTodayEntries()
                                HealthKitManager.shared.deleteAllWaterEntriesForToday()
                                
                                let nearGoalAmount = hydrationStore.progress.goal * 0.95
                                
                                await hydrationStore.logStore.log(amount: nearGoalAmount)
                                
                                if hydrationStore.healthKitStatus.isAuthorized {
                                    HealthKitManager.shared.logWater(amountInML: nearGoalAmount)
                                }

                                await hydrationStore.progress.loadToday()
                                
                                print("Debug: Progress set to \(hydrationStore.progress.total)/\(hydrationStore.progress.goal) (\(Int((hydrationStore.progress.total/hydrationStore.progress.goal)*100))%)")
                                showingDebugMenu = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Force refresh complications") {
                            Task {
                                WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
                            }
                        }
                    }
                }
                #endif
            }
        }
        .onAppear {
            Task {
                await hydrationStore.refreshData()
            }
        }
    }
    
    // Debug functions
    func deleteAllTodaysProgress() async {
        await hydrationStore.logStore.clearTodayEntries()
        
        if hydrationStore.healthKitStatus.isAuthorized {
            HealthKitManager.shared.deleteAllWaterEntriesForToday()
        }
        
        await hydrationStore.progress.loadToday()
        
        print("Debug: All today's progress deleted. Current total: \(hydrationStore.progress.total)")
    }
    
    func setProgressNearGoal() async {
        await deleteAllTodaysProgress()
        
        let nearGoalAmount = hydrationStore.progress.goal * 0.95
        
        await hydrationStore.logStore.log(amount: nearGoalAmount)
        
        if hydrationStore.healthKitStatus.isAuthorized {
            HealthKitManager.shared.logWater(amountInML: nearGoalAmount)
        }
        
        await hydrationStore.progress.loadToday()
        
        print("Debug: Progress set to \(hydrationStore.progress.total)/\(hydrationStore.progress.goal) (\(Int((hydrationStore.progress.total/hydrationStore.progress.goal)*100))%)")
    }
}
