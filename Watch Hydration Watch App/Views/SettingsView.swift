//
//  SettingsView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    @StateObject private var healthKitStatus = HealthKitAuthStatus()
    @State private var showingDebugMenu = false
    @StateObject private var progress = HydrationProgress()
    @StateObject private var logStore = WaterLogStore()
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
                }

                Text("Goal: \(Int(goal)) mL")
                    .font(.caption)
                    .padding()
            }
            .padding()
            
            VStack {
                if healthKitStatus.isAuthorized {
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
                    VStack(spacing: 20) {
                        Text("Debug Menu")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("Current Progress: \(Int(progress.total))/\(Int(progress.goal)) ml")
                                .font(.subheadline)
                            
                            Text("Goal percentage: \(Int((progress.total / max(1, progress.goal)) * 100))%")
                                .font(.subheadline)
                        }
                        
                        Button("Delete Today's Progress") {
                            Task {
                                logStore.clearTodayEntries()
                                HealthKitManager.shared.deleteAllWaterEntriesForToday()
                                await progress.loadToday()
                                showingDebugMenu = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button("Set Progress Near Goal (95%)") {
                            Task {
                                logStore.clearTodayEntries()
                                HealthKitManager.shared.deleteAllWaterEntriesForToday()
                                
                                let nearGoalAmount = progress.goal * 0.95
                                
                                logStore.log(amount: nearGoalAmount)
                                
                                if healthKitStatus.isAuthorized {
                                    HealthKitManager.shared.logWater(amountInML: nearGoalAmount)
                                }

                                await progress.loadToday()
                                
                                print("Debug: Progress set to \(progress.total)/\(progress.goal) (\(Int((progress.total/progress.goal)*100))%)")
                                showingDebugMenu = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                #endif
            }
        }
        .onAppear {
            Task {
                await progress.loadToday()
            }
        }
        .environmentObject(progress)
    }
    
    // Debug functions
    func deleteAllTodaysProgress() async {
        logStore.clearTodayEntries()
        
        if healthKitStatus.isAuthorized {
            HealthKitManager.shared.deleteAllWaterEntriesForToday()
        }
        
        await progress.loadToday()
        
        print("Debug: All today's progress deleted. Current total: \(progress.total)")
    }
    
    func setProgressNearGoal() async {
        await deleteAllTodaysProgress()
        
        let nearGoalAmount = progress.goal * 0.95
        
        logStore.log(amount: nearGoalAmount)
        
        if healthKitStatus.isAuthorized {
            HealthKitManager.shared.logWater(amountInML: nearGoalAmount)
        }
        
        await progress.loadToday()
        
        print("Debug: Progress set to \(progress.total)/\(progress.goal) (\(Int((progress.total/progress.goal)*100))%)")
    }
}
