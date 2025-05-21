import SwiftUI
import Combine

struct WaterInputView: View {
    @State private var liquidAmount: Double = 0
    @State private var fillPercent: Double = 0
    @StateObject private var logStore = WaterLogStore()
    @State private var crownValue: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var isLogging: Bool = false
    @State private var waveOffset = 0.0
    @FocusState private var isEditingAmount: Bool
    @State private var isChoosingLiquid = false
    @StateObject private var healthKitStatus = HealthKitAuthStatus()
    @StateObject var animationManager = BubbleConfettiManager()
    @StateObject private var progress = HydrationProgress()
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    struct LiquidData {
        static let all: [LiquidType] = [
            LiquidType(name: "Water", coefficient: 1.0, color: .blue),
            LiquidType(name: "Coffee", coefficient: 0.8, color: .brown),
            LiquidType(name: "Juice", coefficient: 0.9, color: .orange),
            LiquidType(name: "Cola", coefficient: 0.9, color: .gray),
            LiquidType(name: "Green Tea", coefficient: 0.95, color: .green),
            LiquidType(name: "Black Tea", coefficient: 0.85, color: .brown),
            LiquidType(name: "Tea w/ milk", coefficient: 0.9, color: .gray)
        ]
    }
    
    @State private var selectedLiquid: LiquidType = LiquidData.all[0]
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
                            waveOffset += 0.1
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
                                ForEach(LiquidData.all) { liquid in
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
                    
                    Button("+") {
                        liquidAmount = min(maxAmount, liquidAmount + 50)
                        fillPercent = liquidAmount / maxAmount
                    }
                    .disabled(liquidAmount == maxAmount || isLogging)
                }
                
                Button("Drink \(selectedLiquid.name)") {
                    Task {
                        isLogging = true
                        
                        let currentLiquid = selectedLiquid
                        let valueToLog = liquidAmount * currentLiquid.coefficient
                        
                        logStore.log(amount: valueToLog)
                        
                        await progress.loadToday()
                        
                        let totalWithCurrentDrink = progress.total + valueToLog
                        
                        let goalReached = totalWithCurrentDrink >= progress.goal
                        
                        // Debug for verification
                        print("Progress: \(progress.total) + \(valueToLog) = \(totalWithCurrentDrink)/\(progress.goal)")
                        print("Goal reached: \(goalReached), Reduce Motion: \(reduceMotion)")
                        
                        healthKitStatus.requestAuthorization {
                            if healthKitStatus.isAuthorized {
                                HealthKitManager.shared.logWater(amountInML: valueToLog)
                            }
                        }
                        
                        animateWaterDecrease()
                        
                        if goalReached && !reduceMotion {
                            print("🎉 Triggering confetti!")
                            animationManager.triggerConfetti()
                        } else if !reduceMotion {
                            print("💧 Triggering bubbles")
                            animationManager.triggerBubbles()
                        }
                    }
                }
                .disabled(liquidAmount == 0 || isLogging)
            }
            
            Slider(value: $liquidAmount, in: 0...maxAmount, step: 1)
                .onChange(of: liquidAmount) { _, newValue in
                    liquidAmount = newValue
                }
                .frame(width: 0, height: 0)
                .clipped()
                .opacity(0)
            
            // Bubbles
            ForEach(animationManager.bubbles, id: \.self) { id in
                BubbleView(id: id)
            }

            // Confetti
            if animationManager.showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            Task {
                await progress.loadToday()
            }
        }
        .environmentObject(progress)
    }
    
    func animateWaterDecrease() {
        let decrementValue = 1.0

        Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            if liquidAmount > 0 {
                withAnimation(.linear(duration: 0.001)) {
                    liquidAmount = max(0, liquidAmount - decrementValue)
                }
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                    isLogging = false
                }
            }
        }
    }
}
