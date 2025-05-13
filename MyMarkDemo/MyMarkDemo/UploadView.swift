struct UploadView: View {
    @State private var scanHourly: Bool = false
    @State private var useLibrary: Bool = false
    @State private var useCloud: Bool = false
    @State private var scanInterval: Double = 1

    var body: some View {
        NavigationView {
            Form {
                Section("Sources") {
                    Toggle("Scan Every Hour", isOn: $scanHourly)
                    Toggle("Use Photo Library", isOn: $useLibrary)
                    Toggle("Use Cloud Drives", isOn: $useCloud)
                }
                Section("Scan Settings") {
                    Slider(value: $scanInterval, in: 1...24, step: 1) {
                        Text("Interval (hrs)")
                    }
                    Text("Every \(Int(scanInterval)) hours")
                }
                Section {
                    Button("Scan Now") {
                        // trigger demo scan
                    }
                    Button("Clear Face Data") {
                        // clear demo data
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Upload")
        }
    }
}