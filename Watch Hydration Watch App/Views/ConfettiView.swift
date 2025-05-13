struct ConfettiView: View {
	let count = 15

	var body: some View {
		ZStack {
			ForEach(0..<count, id: \.self) { i in
				ConfettiPiece(angle: .degrees(Double.random(in: 0...360)), delay: Double(i) * 0.02)
			}
		}
	}
}

struct ConfettiPiece: View {
	let angle: Angle
	let delay: Double
	@State private var yOffset: CGFloat = 0

	var body: some View {
		Rectangle()
			.fill(Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 1.0))
			.frame(width: 4, height: 8)
			.rotationEffect(angle)
			.offset(x: .random(in: -40...40), y: yOffset)
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
					withAnimation(.easeOut(duration: 1.0)) {
						yOffset = 100
					}
				}
			}
	}
}
