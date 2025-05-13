//
//  MyMarkWidgetExtension.swift
//  MyMarkWidgetExtension
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import WidgetKit
import SwiftUI

struct MyMarkEntry: TimelineEntry {
    let date: Date
    let isLoggedIn: Bool
    let stats: Stats?
    let hasNew: Bool
}

struct Stats {
    let totalLibrary: Int
    let totalDemoSites: Int
    let verifiedMatches: Int
    let commonSite: String
}

struct MyMarkProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyMarkEntry {
        MyMarkEntry(date: Date(), isLoggedIn: false, stats: nil, hasNew: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (MyMarkEntry) -> ()) {
        completion(MyMarkEntry(date: Date(), isLoggedIn: false, stats: nil, hasNew: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MyMarkEntry>) -> ()) {
        let defaults = UserDefaults(suiteName: "group.nathanbrownbennett.MyMarkDemo")
        let isLoggedIn = defaults?.bool(forKey: "isLoggedIn") ?? false
        let hasNew = defaults?.bool(forKey: "hasNew") ?? false
        var stats: Stats? = nil
        if isLoggedIn {
            stats = Stats(
                totalLibrary: defaults?.integer(forKey: "totalLibrary") ?? 0,
                totalDemoSites: defaults?.integer(forKey: "totalDemoSites") ?? 0,
                verifiedMatches: defaults?.integer(forKey: "verifiedMatches") ?? 0,
                commonSite: defaults?.string(forKey: "commonSite") ?? "-"
            )
        }
        let entry = MyMarkEntry(date: Date(), isLoggedIn: isLoggedIn, stats: stats, hasNew: hasNew)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60*15))))
    }
}

struct MyMarkWidgetEntryView : View {
    var entry: MyMarkEntry

    var body: some View {
        ZStack {
            Color(.systemGray6)
            VStack(spacing: 8) {
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .opacity(0.15)
                if !entry.isLoggedIn {
                    Text("Sign in to be updated")
                        .font(.headline)
                        .foregroundColor(.primary)
                } else if let stats = entry.stats {
                    if entry.hasNew {
                        Text("⚠️ New matches found!")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    Text("Library: \(stats.totalLibrary)")
                    Text("Sites: \(stats.totalDemoSites)")
                    Text("Verified: \(stats.verifiedMatches)")
                    Text("Common: \(stats.commonSite)")
                }
            }
            .padding()
        }
    }
}

@main
struct MyMarkWidget: Widget {
    let kind: String = "MyMarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyMarkProvider()) { entry in
            MyMarkWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MyMark Status")
        .description("See your MyMark stats and alerts.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
