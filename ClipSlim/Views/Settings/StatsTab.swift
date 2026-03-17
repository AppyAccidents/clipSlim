import SwiftUI
import SwiftData
import Charts

struct StatsTab: View {
    @Environment(AppViewModel.self) private var viewModel
    @Query(sort: \PersistentOptimizationEvent.timestamp, order: .reverse)
    private var allEvents: [PersistentOptimizationEvent]

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Overview", icon: "chart.bar") {
                heroMetric
            }

            VibeSettingsCard(title: "All Time", icon: "clock") {
                HStack {
                    Text("Total optimized")
                    Spacer()
                    Text("\(allEvents.count)")
                        .font(VibeCheckTheme.Typography.monospacedBold)
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                }
                HStack {
                    Text("Total saved")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(totalSavedAllTime), countStyle: .file))
                        .font(VibeCheckTheme.Typography.monospacedBold)
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                }
                if !allEvents.isEmpty {
                    HStack {
                        Text("Average compression")
                        Spacer()
                        Text(String(format: "%.1f%%", averageCompressionAllTime))
                            .font(VibeCheckTheme.Typography.monospacedBold)
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    }
                }
            }

            if !topApps.isEmpty {
                VibeSettingsCard(title: "Per App", icon: "app.badge") {
                    ForEach(topApps.prefix(5), id: \.bundleID) { app in
                        HStack {
                            Text(app.bundleID.components(separatedBy: ".").last ?? app.bundleID)
                                .lineLimit(1)
                            Spacer()
                            Text("\(app.count) items")
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                            Text(ByteCountFormatter.string(fromByteCount: Int64(app.savedBytes), countStyle: .file))
                                .font(VibeCheckTheme.Typography.monospacedFont)
                                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                        }
                    }
                }
            }
        }
    }

    private var heroMetric: some View {
        VStack(spacing: VibeCheckTheme.Spacing.sm) {
            Text(ByteCountFormatter.string(fromByteCount: Int64(savedThisWeek), countStyle: .file))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
            Text("saved this week")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private var savedThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allEvents
            .filter { $0.timestamp >= weekAgo }
            .reduce(0) { $0 + $1.savingsBytes }
    }

    private var totalSavedAllTime: Int {
        allEvents.reduce(0) { $0 + $1.savingsBytes }
    }

    private var averageCompressionAllTime: Double {
        guard !allEvents.isEmpty else { return 0 }
        let totalOriginal = allEvents.reduce(0) { $0 + $1.originalSize }
        let totalOptimized = allEvents.reduce(0) { $0 + $1.optimizedSize }
        guard totalOriginal > 0 else { return 0 }
        return Double(totalOriginal - totalOptimized) / Double(totalOriginal) * 100
    }

    private var topApps: [(bundleID: String, savedBytes: Int, count: Int)] {
        var grouped: [String: (savedBytes: Int, count: Int)] = [:]
        for event in allEvents {
            let key = event.sourceBundleID ?? "Unknown"
            let existing = grouped[key] ?? (0, 0)
            grouped[key] = (existing.savedBytes + event.savingsBytes, existing.count + 1)
        }
        return grouped.map { ($0.key, $0.value.savedBytes, $0.value.count) }
            .sorted { $0.savedBytes > $1.savedBytes }
    }
}
