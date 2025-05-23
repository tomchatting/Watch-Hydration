//
//  WaterInputView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

//
//  WaterInputView.swift
//  Watch Hydration
//
//  Refactored by Claude
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
    @EnvironmentObject private var viewModel: HydrationViewModel
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
                        
                        // Animate water decrease first (visual feedback)
                        await MainActor.run {
                            animateWaterDecrease()
                        }
                        
                        // Then log the water (after animation starts)
                        await viewModel.addWater(amount: valueToLog)
                        
                        isLogging = false
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

            // Confetti
            if viewModel.shouldShowConfetti && !reduceMotion {
                ConfettiView()
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    func animateWaterDecrease() {
        withAnimation(.linear(duration: 0.5)) {
            liquidAmount = 0
            fillPercent = 0
        }
    }
}

struct LiquidType: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let coefficient: Double
    
    static let defaultLiquid = LiquidType(name: "Water", color: .blue, coefficient: 1.0)
    static let all = [
        defaultLiquid,
        LiquidType(name: "Coffee",  color: .brown, coefficient: 0.8),
        LiquidType(name: "Juice", color: .orange, coefficient: 0.9),
        LiquidType(name: "Cola", color: .gray, coefficient: 0.9),
        LiquidType(name: "Green Tea", color: .green, coefficient: 0.95),
        LiquidType(name: "Black Tea", color: .brown, coefficient: 0.85),
        LiquidType(name: "Tea w/ milk", color: .gray, coefficient: 0.9)
    ]
}
