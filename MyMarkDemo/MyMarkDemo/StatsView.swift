struct StatsView: View {
    @State private var totalProcessed: Int = 0
    @State private var verifiedMatches: Int = 0
    @State private var commonSite: String = "None"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("MyMark Stats")
                    .font(.largeTitle)
                    .padding(.top)

                StatRow(label: "Images Processed", value: "\(totalProcessed)")
                StatRow(label: "Verified Matches", value: "\(verifiedMatches)")
                StatRow(label: "Most Common Site", value: commonSite)
                Spacer()
            }
            .padding()
            .navigationTitle("Stats")
            .onAppear {
                // Demo update
                totalProcessed = 42
                verifiedMatches = 7
                commonSite = "example.com"
            }
        }
    }
}