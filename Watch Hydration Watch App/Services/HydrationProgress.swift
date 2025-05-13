class HydrationProgress: ObservableObject {
	@Published var total: Double = 0
	@Published var entries: [WaterLogEntry] = []
	@AppStorage("hydrationGoal") var goal: Double = 2000

	private let healthKitStatus = HealthKitAuthStatus()
	private let logStore = WaterLogStore()

	func loadToday() {
		if healthKitStatus.isAuthorized {
			HealthKitManager.shared.getTodayWaterSamples { samples in
				DispatchQueue.main.async {
					self.entries = samples.map {
						WaterLogEntry(date: $0.startDate, amount: $0.quantity.doubleValue(for: .literUnit(with: .milli)))
					}.sorted(by: { $0.date > $1.date })

					self.total = self.entries.reduce(0) { $0 + $1.amount }
				}
			}
		} else {
			let localEntries = logStore.entries.filter {
				Calendar.current.isDateInToday($0.date)
			}

			self.entries = localEntries.sorted(by: { $0.date > $1.date })
			self.total = self.entries.reduce(0) { $0 + $1.amount }
		}
	}
}
