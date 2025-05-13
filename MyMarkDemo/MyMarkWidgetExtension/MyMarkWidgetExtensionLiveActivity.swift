//
//  MyMarkWidgetExtensionLiveActivity.swift
//  MyMarkWidgetExtension
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MyMarkWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyMarkWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyMarkWidgetExtensionAttributes.self) { context in
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

extension MyMarkWidgetExtensionAttributes {
    fileprivate static var preview: MyMarkWidgetExtensionAttributes {
        MyMarkWidgetExtensionAttributes(name: "World")
    }
}

extension MyMarkWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: MyMarkWidgetExtensionAttributes.ContentState {
        MyMarkWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MyMarkWidgetExtensionAttributes.ContentState {
         MyMarkWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MyMarkWidgetExtensionAttributes.preview) {
   MyMarkWidgetExtensionLiveActivity()
} contentStates: {
    MyMarkWidgetExtensionAttributes.ContentState.smiley
    MyMarkWidgetExtensionAttributes.ContentState.starEyes
}
