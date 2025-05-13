//
//  StatsView.swift
//  MyMarkDemo
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import SwiftUI

struct StatsView: View {
    @AppStorage("loggedInUsername") var loggedInUsername: String = ""
    @State private var totalLibrary = 120
    @State private var totalDemoSites = 30
    @State private var verifiedMatches = 0
    @State private var commonSite = ""
    @State private var demoSites: [String] = []
    @State private var loaded = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("MyMark Stats")
                    .font(.largeTitle)
                    .padding(.top)

                StatRow(label: "Images from Photo Library", value: "\(totalLibrary)")
                StatRow(label: "Images from Demo Sites", value: "\(totalDemoSites)")
                StatRow(label: "Verified Matches", value: "\(verifiedMatches)")
                StatRow(label: "Most Common Site", value: commonSite)

                Spacer()
            }
            .padding()
            .navigationTitle("Stats")
            .onAppear {
                if (!loaded) {
                    // Simulate: verified matches = number of Jane_XX or John_XX images in assets
                    let prefix = loggedInUsername.isEmpty ? "Jane" : loggedInUsername
                    var count = 0
                    var sites: [String] = []
                    let demoSitesList = [
                        "instagram.com", "instagram.com", "facebook.com", "facebook.com",
                        "twitter.com", "twitter.com", "tiktok.com", "tiktok.com",
                        "snapchat.com", "snapchat.com", "youtube.com", "youtube.com",
                        "reddit.com", "reddit.com", "onlyfans.com", "onlyfans.com",
                        "linkedin.com", "pinterest.com", "tumblr.com", "flickr.com",
                        "meetup.com", "quora.com", "vimeo.com", "disneyplus.com",
                        "periscope.tv", "ok.ru", "linkedin.com", "reddit.com",
                        "medium.com", "behance.net", "dribbble.com", "nationalgeographic.com",
                        "soundcloud.com", "spotify.com", "twitch.tv", "foursquare.com"
                    ]
                    for i in 1...30 {
                        let imgName = "\(prefix)_\(String(format: "%02d", i))"
                        if UIImage(named: imgName) != nil {
                            count += 1
                            sites.append(demoSitesList[i % demoSitesList.count])
                        }
                    }
                    verifiedMatches = count
                    commonSite = sites.isEmpty ? "-" : sites.reduce(into: [:]) { $0[$1, default: 0] += 1 }
                        .max(by: { $0.value < $1.value })?.key ?? "-"
                    
                    // After computing stats, update widget data:
                    let defaults = UserDefaults(suiteName: "group.nathanbrownbennett.MyMarkDemo")
                    defaults?.set(true, forKey: "isLoggedIn")
                    defaults?.set(totalLibrary, forKey: "totalLibrary")
                    defaults?.set(totalDemoSites, forKey: "totalDemoSites")
                    defaults?.set(verifiedMatches, forKey: "verifiedMatches")
                    defaults?.set(commonSite, forKey: "commonSite")
                    defaults?.set(false, forKey: "hasNew") // set to true when new matches found
                    
                    loaded = true
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String, value: String

    var body: some View {
        HStack {
            Text(label).bold()
            Spacer()
            Text(value)
        }
        .padding(.horizontal)
    }
}
