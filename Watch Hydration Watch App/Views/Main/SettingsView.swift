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
    @EnvironmentObject private var viewModel: HydrationViewModel
    @State private var tempGoal: Double = 2000
    
    let minGoal: Double = 500
    let maxGoal: Double = 3000
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var appBuild: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack {
                Slider(value: $tempGoal, in: minGoal...maxGoal, step: 100) {
                    Text("Goal: \(Int(tempGoal)) mL")
                }
                .onChange(of: tempGoal) { _, newValue in
                    viewModel.updateGoal(to: newValue)
                }
                .onAppear {
                    tempGoal = viewModel.waterIntakeService.goal
                }

                Text("Goal: \(Int(tempGoal)) mL")
                    .font(.caption)
                    .padding()
            }
            .padding()
            
            VStack {
                if viewModel.waterIntakeService.isHealthKitAuthorized {
                    Label("HealthKit enabled", systemImage: "heart.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.top, 5)
                } else {
                    VStack(spacing: 8) {
                        Label("HealthKit disabled", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Button("Enable HealthKit") {
                            Task {
                                await viewModel.requestHealthKitPermissions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        
                        // Show error message if permission request failed
                        if let errorMessage = viewModel.waterIntakeService.errorMessage {
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
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
                    debugMenuSheet
                }
                #endif
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
                tempGoal = viewModel.waterIntakeService.goal
            }
        }
    }
    
    #if DEBUG
    private var debugMenuSheet: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Debug Menu")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Progress: \(viewModel.totalFormatted)/\(viewModel.goalFormatted)")
                        .font(.subheadline)
                    
                    Text("Goal percentage: \(viewModel.progressPercentage)")
                        .font(.subheadline)
                    
                    Text("Entries count: \(viewModel.waterIntakeService.todaysEntries.count)")
                        .font(.subheadline)
                    
                    Text("HealthKit authorized: \(viewModel.waterIntakeService.isHealthKitAuthorized ? "Yes" : "No")")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Button("Delete Today's Progress") {
                    Task {
                        await viewModel.clearToday()
                        showingDebugMenu = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button("Set Progress Near Goal (95%)") {
                    Task {
                        await viewModel.clearToday()
                        
                        let nearGoalAmount = viewModel.waterIntakeService.goal * 0.95
                        await viewModel.addWater(amount: nearGoalAmount)
                        
                        print("Debug: Progress set to \(viewModel.waterIntakeService.total)/\(viewModel.waterIntakeService.goal) (\(viewModel.progressPercentage))")
                        showingDebugMenu = false
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Force refresh complications") {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
                    showingDebugMenu = false
                }
                .buttonStyle(.borderedProminent)
                
                Button("Close") {
                    showingDebugMenu = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    #endif
}
