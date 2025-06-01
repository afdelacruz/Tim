import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct TimWidgetEntry: TimelineEntry {
    let date: Date
    let inflow: Double
    let outflow: Double
    let isPlaceholder: Bool
    let lastUpdated: Date?
    
    init(date: Date, inflow: Double = 0, outflow: Double = 0, isPlaceholder: Bool = false, lastUpdated: Date? = nil) {
        self.date = date
        self.inflow = inflow
        self.outflow = outflow
        self.isPlaceholder = isPlaceholder
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Widget View
struct TimWidgetView: View {
    let entry: TimWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.isPlaceholder ? "+--" : "+$\(Int(entry.inflow))")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            
            HStack {
                Text(entry.isPlaceholder ? "-+--" : "-$\(Int(entry.outflow))")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
            
            if let lastUpdated = entry.lastUpdated, !entry.isPlaceholder {
                HStack {
                    Spacer()
                    Text(timeAgoString(from: lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 24 hours
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else { // 24+ hours
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Widget Configuration
struct TimWidget: Widget {
    let kind: String = "TimWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimTimelineProvider()) { entry in
            TimWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tim Balance")
        .description("View your monthly inflows and outflows at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TimWidget()
} timeline: {
    TimWidgetEntry(date: .now, inflow: 1240, outflow: 890, lastUpdated: Date().addingTimeInterval(-3600))
    TimWidgetEntry(date: .now, inflow: 0, outflow: 0, isPlaceholder: true)
} 