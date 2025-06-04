//
//  TimWidgetLiveActivity.swift
//  TimWidget
//
//  Created by Andrew De la Cruz on 6/2/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TimWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimWidgetAttributes {
    fileprivate static var preview: TimWidgetAttributes {
        TimWidgetAttributes(name: "World")
    }
}

extension TimWidgetAttributes.ContentState {
    fileprivate static var smiley: TimWidgetAttributes.ContentState {
        TimWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimWidgetAttributes.ContentState {
         TimWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TimWidgetAttributes.preview) {
   TimWidgetLiveActivity()
} contentStates: {
    TimWidgetAttributes.ContentState.smiley
    TimWidgetAttributes.ContentState.starEyes
}
