//
//  WaterInputView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI
import Combine
import WidgetKit

struct WaterInputView: View {
    @State private var liquidAmount: Double = 0
    @State private var fillPercent: Double = 0
    @State private var crownValue: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var isLogging: Bool = false
    @State private var waveOffset = 0.0
    @State private var isAnimating = false
    @State private var selectedLiquid: LiquidType = LiquidType.defaultLiquid
    @FocusState private var isEditingAmount: Bool
    @State private var isChoosingLiquid = false
    @EnvironmentObject private var hydrationStore: HydrationStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let maxAmount: Double = 1000

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ZStack(alignment: .bottom) {
                        CupShape()
                            .stroke(lineWidth: 1.5)
                            .frame(width: 50, height: 70)
                        
                        ZStack {
                            WaveShape(offset: waveOffset, amplitude: 3)
                                .fill(selectedLiquid.color.opacity(0.6))
                            
                            WaveShape(offset: waveOffset + .pi, amplitude: 3)
                                .fill(selectedLiquid.color.opacity(0.6))
                        }
                        .frame(width: 48, height: 68)
                        .offset(y: CGFloat(1 - fillPercent) * 68)
                        .clipShape(CupShape())
                        .onReceive(timer) { _ in
                            if isAnimating {
                                waveOffset += 0.1
                            }
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            isAnimating = (newPhase == .active)
                        }
                        .onAppear {
                            isAnimating = true
                        }
                        .onDisappear {
                            isAnimating = false
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isChoosingLiquid = true
                            }
                            .accessibilityIdentifier("CupTapArea")
                    )
                    .sheet(isPresented: $isChoosingLiquid) {
                        ScrollView(.vertical) {
                            VStack(spacing: 10) {
                                ForEach(LiquidType.all) { liquid in
                                    Button(action: {
                                        selectedLiquid = liquid
                                        isChoosingLiquid = false
                                    }) {
                                        HStack {
                                            Circle().fill(liquid.color).frame(width: 20, height: 20)
                                            Text(liquid.name)
                                            Text("(\(String(format: "%.2f",liquid.coefficient)))")
                                                .font(.caption2)
                                        }
                                        .padding()
                                        .cornerRadius(8)
                                    }
                                    .accessibilityIdentifier("Liquid_\(liquid.name)")
                                    .buttonStyle(.borderedProminent)
                                    .tint(selectedLiquid == liquid ? Color.primary : Color.secondary)
                                }
                            }
                        }
                    }
                    
                    TextField("Amount", value: $liquidAmount, format: .number)
                        .focused($isEditingAmount)
                        .font(.title3.bold())
                        .frame(width: 75, alignment: .trailing)
                        .onChange(of: liquidAmount) { _, newValue in
                            fillPercent = newValue / maxAmount
                        }
                        .accessibilityIdentifier("AmountField")
                        .disabled(true)
                    Text("mL")
                        .font(.subheadline.bold())
                        .frame(width: 25, alignment: .trailing)
                }
                
                HStack {
                    Button("-") {
                        liquidAmount = max(0, liquidAmount - 50)
                        fillPercent = liquidAmount / maxAmount
                    }
                    .disabled(liquidAmount == 0 || isLogging)
                    .accessibilityIdentifier("DecrementButton")
                    
                    Button("+") {
                        liquidAmount = min(maxAmount, liquidAmount + 50)
                        fillPercent = liquidAmount / maxAmount
                    }
                    .disabled(liquidAmount == maxAmount || isLogging)
                    .accessibilityIdentifier("IncrementButton")
                }
                
                Button("Drink \(selectedLiquid.name)") {
                    Task {
                        isLogging = true
                        
                        let currentLiquid = selectedLiquid
                        let valueToLog = liquidAmount * currentLiquid.coefficient
                        
                        hydrationStore.logStore.log(amount: valueToLog)
                        
                        await hydrationStore.progress.loadToday()
                        
                        let totalWithCurrentDrink = hydrationStore.progress.total + valueToLog
                        
                        let goalReached = totalWithCurrentDrink >= hydrationStore.progress.goal
                        
                        print("Progress: \(hydrationStore.progress.total) + \(valueToLog) = \(totalWithCurrentDrink)/\(hydrationStore.progress.goal)")
                        print("Goal reached: \(goalReached), Reduce Motion: \(reduceMotion)")
                        
                        hydrationStore.healthKitStatus.requestAuthorization {
                            if hydrationStore.healthKitStatus.isAuthorized {
                                HealthKitManager.shared.logWater(amountInML: valueToLog)
                            }
                        }
                        
                        animateWaterDecrease()
                        
                        if goalReached && !reduceMotion {
                            print("🎉 Triggering confetti!")
                            hydrationStore.animationManager.triggerConfetti()
                        } else if !reduceMotion {
                            print("💧 Triggering bubbles")
                            hydrationStore.animationManager.triggerBubbles()
                        }
    
                    }
                }
                .disabled(liquidAmount == 0 || isLogging)
                .accessibilityIdentifier("DrinkButton")
            }
            
            Slider(value: $liquidAmount, in: 0...maxAmount, step: 1)
                .onChange(of: liquidAmount) { _, newValue in
                    liquidAmount = newValue
                }
                .frame(width: 0, height: 0)
                .clipped()
                .opacity(0)
            
            // Bubbles
            ForEach(hydrationStore.animationManager.bubbles, id: \.self) { id in
                BubbleView(id: id, color: selectedLiquid.color)
            }

            // Confetti
            if hydrationStore.animationManager.showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            Task {
                await hydrationStore.refreshData()
            }
        }
    }
    
    func animateWaterDecrease() {
        isLogging = true
        
        withAnimation(.linear(duration: 0.5)) {
            liquidAmount = 0
            fillPercent = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLogging = false
        }
    }
}
