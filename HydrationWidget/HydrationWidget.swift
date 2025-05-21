// HydrationWidget.swift
import WidgetKit
import SwiftUI

// Main widget configuration
@main
struct HydrationWidget: Widget {
    let kind: String = "HydrationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationProvider()) { entry in
            HydrationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration Status")
        .description("Track your daily hydration progress.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// Widget entry view that adapts to different widget families
struct HydrationWidgetEntryView: View {
    var entry: HydrationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCorner:
            CornerHydrationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        case .accessoryCircular:
            CircularHydrationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            RectangularHydrationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            InlineHydrationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        @unknown default:
            CircularHydrationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
    }
}

// Circular widget view (used for Smart Stack)
struct CircularHydrationView: View {
    var entry: HydrationProvider.Entry
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 5)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(entry.progress))
                .stroke(
                    entry.goalMet ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Center text
            VStack(spacing: 1) {
                Text("\(Int(entry.progressPercentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
        }
        .widgetURL(URL(string: "watchhydration://open"))
    }
}

// Corner widget view
struct CornerHydrationView: View {
    var entry: HydrationProvider.Entry
    
    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .widgetAccentable()
            
            Gauge(value: entry.progress) {
                Text("")
            }
            .gaugeStyle(.accessoryCircular)
        }
        .widgetURL(URL(string: "watchhydration://open"))
    }
}

// Rectangular widget view
struct RectangularHydrationView: View {
    var entry: HydrationProvider.Entry
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat(entry.progress))
                    .stroke(
                        entry.goalMet ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Hydration")
                    .font(.system(size: 12, weight: .bold))
                
                Text("\(Int(entry.currentAmount)) / \(Int(entry.goalAmount)) mL")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(URL(string: "watchhydration://open"))
    }
}

// Inline widget view
struct InlineHydrationView: View {
    var entry: HydrationProvider.Entry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "drop.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)
            
            Text("\(Int(entry.progressPercentage * 100))% hydrated")
                .font(.system(size: 12))
                .fontWeight(.medium)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "watchhydration://open"))
    }
}

// Preview provider
struct HydrationWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HydrationWidgetEntryView(entry: .sampleData)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")
            
            HydrationWidgetEntryView(entry: .sampleData)
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")
            
            HydrationWidgetEntryView(entry: .sampleData)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            
            HydrationWidgetEntryView(entry: .sampleData)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            
            // Preview with goal met
            HydrationWidgetEntryView(entry: .goalMetSample)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Goal Met")
        }
    }
}
