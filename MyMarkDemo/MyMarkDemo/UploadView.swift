//
//  UploadView.swift
//  MyMarkDemo
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var scanHourly = false
    @State private var useLibrary = false
    @State private var useCloud = false
    @State private var interval: Double = 1
    @State private var showingPicker = false
    @State private var loading = false
    @State private var error: String?
    @State private var success: String?
    @State private var ignoredSites: [String] = []
    @State private var newIgnoredSite: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Sources") {
                    Toggle("Use Photo Library", isOn: $useLibrary)
                    Toggle("Use Cloud Drives", isOn: $useCloud)
                }
                Section("Scan Settings") {
                    Slider(value: $interval, in: 1...24, step: 1) {
                        Text("Interval (hrs)")
                    }
                    Text("Every \(Int(interval)) hours")
                }
                Section(header: Text("Ignored Sites")) {
                    ForEach(ignoredSites, id: \.self) { site in
                        HStack {
                            Text(site)
                            Spacer()
                            Button(action: {
                                ignoredSites.removeAll { $0 == site }
                            }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(.red)
                            }
                        }
                    }
                    HStack {
                        TextField("Add site (e.g. instagram.com)", text: $newIgnoredSite)
                        Button("Add") {
                            if !newIgnoredSite.isEmpty && !ignoredSites.contains(newIgnoredSite) {
                                ignoredSites.append(newIgnoredSite)
                                newIgnoredSite = ""
                            }
                        }
                        .disabled(newIgnoredSite.isEmpty)
                    }
                }
                Section {
                    Button("Scan Now") {
                        scanNow()
                    }
                    Button("Clear Face Data") {
                        clearData()
                    }
                    .foregroundColor(.red)
                }
                Section {
                    Button("Select File…") {
                        showingPicker.toggle()
                    }
                    .fileImporter(
                        isPresented: $showingPicker,
                        allowedContentTypes: [.image, .movie]
                    ) { _ in }
                }
                if loading {
                    ProgressView()
                }
                if let error = error {
                    Text("Error: \(error)").foregroundColor(.red)
                }
                if let success = success {
                    Text(success).foregroundColor(.green)
                }
            }
            .navigationTitle("Upload")
        }
    }

    private func scanNow() {
        loading = true; error = nil; success = nil
        guard let url = URL(string: "http://localhost:5000/api/scan") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req) { _, _, err in
            DispatchQueue.main.async {
                loading = false
                if let err = err { error = err.localizedDescription }
                else { success = "Scan started!" }
            }
        }.resume()
    }

    private func clearData() {
        loading = true; error = nil; success = nil
        guard let url = URL(string: "http://localhost:5000/api/clear") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req) { _, _, err in
            DispatchQueue.main.async {
                loading = false
                if let err = err { error = err.localizedDescription }
                else { success = "Data cleared!" }
            }
        }.resume()
    }
}
