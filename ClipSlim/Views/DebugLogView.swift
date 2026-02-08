import SwiftUI

struct DebugLogView: View {
    
    @Environment(AppViewModel.self) private var viewModel
    @State private var filterSource: OptimizationEvent.Source?
    @State private var searchText = ""
    
    private var filteredEvents: [OptimizationEvent] {
        var events = viewModel.events
        
        if let source = filterSource {
            events = events.filter { $0.source == source }
        }
        
        if !searchText.isEmpty {
            events = events.filter { event in
                event.summary.localizedCaseInsensitiveContains(searchText) ||
                (event.fileName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return events
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider()
            
            // Event List
            if filteredEvents.isEmpty {
                emptyState
            } else {
                eventList
            }
            
            Divider()
            
            // Footer
            footer
        }
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: VibeCheckTheme.Spacing.md) {
            Image(systemName: "terminal")
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
            
            Text("Debug Log")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
            
            Spacer()
            
            // Source Filter
            Picker("Source", selection: $filterSource) {
                Text("All").tag(OptimizationEvent.Source?.none)
                Text("Clipboard").tag(OptimizationEvent.Source?.some(.clipboard))
                Text("Folder").tag(OptimizationEvent.Source?.some(.folder))
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                TextField("Filter…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(VibeCheckTheme.Typography.caption)
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.sm)
            .padding(.vertical, VibeCheckTheme.Spacing.xs)
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .frame(width: 140)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
        .background(VibeCheckTheme.Colors.surface)
    }
    
    // MARK: - Event List
    
    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredEvents) { event in
                    eventRow(event)
                }
            }
            .padding(.vertical, VibeCheckTheme.Spacing.xs)
        }
    }
    
    private func eventRow(_ event: OptimizationEvent) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.md) {
            // Timestamp
            Text(event.formattedTimestamp)
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .frame(width: 60, alignment: .leading)
            
            // Source badge
            Text(event.source.rawValue)
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(event.source == .clipboard ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.neonOrange)
                .padding(.horizontal, VibeCheckTheme.Spacing.xs)
                .padding(.vertical, 2)
                .background(
                    (event.source == .clipboard ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.neonOrange)
                        .opacity(0.15)
                )
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                .frame(width: 70)
            
            // File name or "Clipboard"
            Text(event.fileName ?? "Clipboard Image")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Size change
            Text(event.result.formattedOriginalSize)
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            
            Text(event.result.formattedOptimizedSize)
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.success)
            
            // Savings %
            Text("-\(String(format: "%.0f", event.result.savingsPercentage))%")
                .font(VibeCheckTheme.Typography.tiny)
                .fontWeight(.bold)
                .foregroundColor(VibeCheckTheme.Colors.success)
                .frame(width: 45, alignment: .trailing)
            
            // Duration
            Text("\(String(format: "%.0f", event.result.duration * 1000))ms")
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .frame(width: 45, alignment: .trailing)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.background)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: VibeCheckTheme.Spacing.md) {
            Spacer()
            
            Image(systemName: "text.justify.left")
                .font(.system(size: 32))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            
            Text("No optimization events yet")
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            
            Text("Copy an image to the clipboard to get started")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Text("\(filteredEvents.count) events")
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            
            Spacer()
            
            Button {
                viewModel.clearHistory()
            } label: {
                HStack(spacing: VibeCheckTheme.Spacing.xs) {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.surface)
    }
}
