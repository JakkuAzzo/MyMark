struct MatchesCarouselView: View {
    @State private var items: [MatchItem] = [
        MatchItem(id: 1, imageName: "Sample1", site: "siteA.com"),
        MatchItem(id: 2, imageName: "Sample2", site: "siteB.com")
    ]
    @State private var history: [MatchItem] = []

    var body: some View {
        NavigationView {
            if items.isEmpty {
                VStack {
                    Text("No potential images 😃")
                        .font(.title)
                    Button("Review History") {
                        items = history
                    }
                    .padding()
                }
                .navigationTitle("Results")
            } else {
                TabView {
                    ForEach(items) { item in
                        MatchCardView(item: item,
                                      onLeft: { action(item, left: true) },
                                      onRight: { action(item, left: false) })
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .navigationTitle("Results")
            }
        }
    }

    private func action(_ item: MatchItem, left: Bool) {
        history.append(item)
        items.removeAll { $0.id == item.id }
    }
}

struct MatchCardView: View {
    let item: MatchItem
    let onLeft: () -> Void
    let onRight: () -> Void
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack(alignment: offset.width < 0 ? .leading : .trailing) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(16)
                .shadow(radius: 5)
                .padding()
                .offset(x: offset.width)
                .gesture(
                    DragGesture()
                        .onChanged { offset = $0.translation }
                        .onEnded { _ in
                            if offset.width < -100 { onLeft() }
                            else if offset.width > 100 { onRight() }
                            offset = .zero
                        }
                )

            // Buttons
            if offset.width < 0 {
                HStack {
                    Button("Report") { onLeft() }.padding().background(Color.red).cornerRadius(8)
                    Button("Takedown") { onLeft() }.padding().background(Color.orange).cornerRadius(8)
                }
                .padding(.leading)
            } else if offset.width > 0 {
                HStack {
                    Button("Posted Me") { onRight() }.padding().background(Color.green).cornerRadius(8)
                    Button("Approve") { onRight() }.padding().background(Color.blue).cornerRadius(8)
                }
                .padding(.trailing)
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
