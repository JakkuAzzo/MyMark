//
//  MatchesCarouselView.swift
//  MyMarkDemo
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import SwiftUI
import SafariServices
import UserNotifications

struct MatchesCarouselView: View {
    let username: String
    @State private var items: [MatchItem] = []
    @State private var history: [MatchItem] = []
    @State private var lastAction: [Int: String] = [:]
    @State private var showHistory = false
    @State private var showOverlay = false
    @State private var overlayType: OverlayType?
    @State private var overlayItem: MatchItem?
    @State private var showSafari: Bool = false
    @State private var safariURL: URL?

    enum OverlayType {
        case report, takedown
    }

    var body: some View {
        NavigationView {
            ZStack {
                if items.isEmpty {
                    VStack {
                        Text("No potential images 🙂")
                            .font(.title)
                        Button("Review Actions") {
                            showHistory = true
                        }
                        .padding(.top)
                    }
                    .sheet(isPresented: $showHistory) {
                        ReviewHistoryView(history: history, lastAction: lastAction)
                    }
                    .navigationTitle("Matches")
                } else {
                    TabView {
                        ForEach(items) { item in
                            ZStack {
                                MatchCardView(
                                    item: item,
                                    onLeft: { action in
                                        if action == "Report" {
                                            overlayType = .report
                                            overlayItem = item
                                            withAnimation(.easeInOut) { showOverlay = true }
                                        } else if action == "Takedown" {
                                            overlayType = .takedown
                                            overlayItem = item
                                            withAnimation(.easeInOut) { showOverlay = true }
                                        }
                                    },
                                    onRight: { action in
                                        handle(item, action: action)
                                    },
                                    onTapImage: {
                                        if let url = URL(string: item.site) {
                                            safariURL = url
                                            showSafari = true
                                        }
                                    },
                                    blurred: showOverlay && overlayItem?.id == item.id
                                )
                                .blur(radius: (showOverlay && overlayItem?.id == item.id) ? 8 : 0)
                                .animation(.easeInOut, value: showOverlay)

                                if showOverlay && overlayItem?.id == item.id {
                                    CubistOverlay(
                                        type: overlayType ?? .report,
                                        onSubmit: { reason in
                                            if let overlayItem = overlayItem {
                                                handle(overlayItem, action: "\(overlayType == .report ? "Report" : "Takedown"): \(reason)")
                                            }
                                            withAnimation(.easeInOut) {
                                                showOverlay = false
                                                overlayItem = nil
                                            }
                                        },
                                        onCancel: {
                                            withAnimation(.easeInOut) {
                                                showOverlay = false
                                                overlayItem = nil
                                            }
                                        }
                                    )
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .navigationTitle("Matches (\(items.count))")
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
        }
        .onAppear(perform: loadDemoMatches)
    }

    private func loadDemoMatches() {
        let demoSites = [
            "https://www.instagram.com/p/BAT2MEWuDPN/",
            "https://sub.instagram.com/p/NEWINSTAGRAM1/",
            "https://www.facebook.com/photo.php?fbid=123456789",
            "https://m.facebook.com/story.php?story_fbid=987654321",
            "https://twitter.com/example/status/987654321",
            "https://mobile.twitter.com/example/status/123456789",
            "https://www.tiktok.com/@user/video/1234567890",
            "https://vm.tiktok.com/ZSeMbC/",
            "https://www.snapchat.com/add/exampleuser",
            "https://story.snapchat.com/view/exampleuser",
            "https://www.youtube.com/watch?v=abc123def",
            "https://m.youtube.com/watch?v=def456ghi",
            "https://www.reddit.com/r/example/comments/xyz789/",
            "https://old.reddit.com/r/example/comments/abc123/",
            "https://onlyfans.com/exampleuser",
            "https://pro.onlyfans.com/examplecreator",
            "https://www.linkedin.com/feed/update/urn:li:activity:1234567890",
            "https://www.pinterest.com/pin/123456789012345678/",
            "https://www.tumblr.com/dashboard",
            "https://www.flickr.com/photos/exampleuser/123456789",
            "https://www.meetup.com/sample-group/events/123456789/",
            "https://www.quora.com/What-is-sample-question",
            "https://www.vimeo.com/123456789",
            "https://www.disneyplus.com/video/123456789",
            "https://www.periscope.tv/stream/123456789",
            "https://www.ok.ru/video/123456789",
            "https://www.linkedin.com/in/exampleuser/",
            "https://www.reddit.com/user/exampleuser",
            "https://www.medium.com/@exampleuser",
            "https://www.behance.net/gallery/123456789",
            "https://www.dribbble.com/shots/123456789",
            "https://www.nationalgeographic.com/photo-of-the-day/123456789",
            "https://www.soundcloud.com/exampleuser/sets/123456789",
            "https://www.spotify.com/track/123456789",
            "https://www.twitch.tv/exampleuser",
            "https://www.foursquare.com/s/exampleuser"
        ]
        var loaded: [MatchItem] = []
        for i in 1...30 {
            let imgName = "\(username)_\(String(format: "%02d", i))"
            if UIImage(named: imgName) != nil {
                loaded.append(MatchItem(id: i, imageName: imgName, site: demoSites[i % demoSites.count]))
            }
        }
        items = loaded
    }

    private func handle(_ item: MatchItem, action: String) {
        history.append(item)
        lastAction[item.id] = action
        items.removeAll { $0.id == item.id }
        sendDidYouPostNotification(for: item)
    }

    private func sendDidYouPostNotification(for item: MatchItem) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Did you post this?"
        content.body = "A new potential match was found: \(item.site)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        center.add(request)
    }
}

// MARK: - Cubist Overlay

struct CubistOverlay: View {
    let type: MatchesCarouselView.OverlayType
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    @State private var selectedReason: String = ""
    private let reasonsReport = ["Impersonation", "Inappropriate Content", "Privacy Violation", "Other"]
    private let reasonsTakedown = ["Copyright", "Personal Privacy", "Legal", "Other"]

    var body: some View {
        VStack(spacing: 24) {
            Text(type == .report ? "Report Image" : "Issue Takedown")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.top, 20)
            VStack(alignment: .leading, spacing: 16) {
                Text("Select a reason:")
                    .font(.headline)
                ForEach(type == .report ? reasonsReport : reasonsTakedown, id: \.self) { reason in
                    HStack {
                        Image(systemName: selectedReason == reason ? "checkmark.square.fill" : "square")
                            .foregroundColor(.blue)
                        Text(reason)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onTapGesture { withAnimation { selectedReason = reason } }
                }
            }
            .padding(.horizontal, 16)
            Spacer()
            Button("Submit") {
                if !selectedReason.isEmpty {
                    onSubmit(selectedReason)
                }
            }
            .buttonStyle(CubicButtonStyle())
            .disabled(selectedReason.isEmpty)
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.gray)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 340, maxHeight: 400)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut, value: selectedReason)
    }
}

// MARK: - MatchCardView

struct MatchCardView: View {
    let item: MatchItem
    let onLeft: (String)->Void
    let onRight: (String)->Void
    let onTapImage: ()->Void
    let blurred: Bool
    @State private var drag = CGSize.zero

    var body: some View {
        ZStack(alignment: drag.width < 0 ? .leading : .trailing) {
            Button(action: onTapImage) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding()
                    .blur(radius: blurred ? 8 : 0)
                    .animation(.easeInOut, value: blurred)
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: drag.width)
            .gesture(
                DragGesture()
                    .onChanged { drag = $0.translation }
                    .onEnded { _ in
                        if drag.width < -100 { onLeft("Report") }
                        else if drag.width > 100 { onRight("Approve") }
                        drag = .zero
                    }
            )

            if drag.width < 0 && !blurred {
                HStack {
                    Button("Report") { onLeft("Report") }
                        .padding().background(Color.red).cornerRadius(8)
                    Button("Issue Takedown") { onLeft("Takedown") }
                        .padding().background(Color.orange).cornerRadius(8)
                }
                .padding(.leading)
                .transition(.move(edge: .leading))
            } else if drag.width > 0 && !blurred {
                HStack {
                    Button("I posted that") { onRight("Posted") }
                        .padding().background(Color.green).cornerRadius(8)
                    Button("I'm fine with this") { onRight("Approve") }
                        .padding().background(Color.blue).cornerRadius(8)
                }
                .padding(.trailing)
                .transition(.move(edge: .trailing))
            }

            VStack {
                Spacer()
                Text(item.site)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.bottom)
            }
        }
    }
}

// MARK: - SafariView

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ReviewHistoryView: View {
    let history: [MatchItem]
    let lastAction: [Int: String]

    var body: some View {
        NavigationView {
            List(history, id: \.id) { item in
                HStack {
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    VStack(alignment: .leading) {
                        Text(item.site)
                        if let action = lastAction[item.id] {
                            Text("Action: \(action)").font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Reviewed Matches")
        }
    }
}
