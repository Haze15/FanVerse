import SwiftUI

let categoryColors: [String: Color] = [
    "Pokémon": .red, "Sonic": .blue, "Mario": .orange,
    "Zelda": .green, "Undertale": .yellow,
    "Smash": .pink, "Metroid": .teal, "Kirby": .mint,
]

struct ContentView: View {
    @State private var search = ""
    @State private var category = "Tous"
    @AppStorage("favs") private var favsRaw = ""
    @StateObject private var dm = DownloadManager()

    var favs: Set<String> { Set(favsRaw.split(separator: "|").map(String.init)) }
    var categories: [String] { ["Tous", "⭐️"] + Array(Set(allGames.map(\.category))).sorted() }

    var filtered: [Game] {
        allGames.filter { g in
            let okCat = category == "Tous" || (category == "⭐️" ? favs.contains(g.name) : g.category == category)
            let okSearch = search.isEmpty || g.name.localizedCaseInsensitiveContains(search)
            return okCat && okSearch
        }
    }

    func toggle(_ g: Game) {
        var s = favs
        if s.contains(g.name) { s.remove(g.name) } else { s.insert(g.name) }
        favsRaw = s.joined(separator: "|")
    }

    @ViewBuilder func actions(_ g: Game) -> some View {
        HStack(spacing: 18) {
            if let u = URL(string: g.url) {
                Link(destination: u) { Label("Site", systemImage: "safari") }
            }
            if g.dl != nil {
                if let p = dm.progress[g.name] {
                    ProgressView(value: p).frame(width: 80)
                } else if let file = dm.localFile(for: g) {
                    ShareLink(item: file) { Label("Ouvrir", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { dm.delete(g) } label: { Image(systemName: "trash") }
                } else {
                    Button { dm.start(g) } label: { Label("Télécharger", systemImage: "arrow.down.circle.fill") }
                }
            }
        }.font(.subheadline.weight(.semibold)).buttonStyle(.borderless)
    }

    func card(_ g: Game) -> some View {
        let color = categoryColors[g.category] ?? .purple
        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 5)
            VStack(alignment: .leading, spacing: 6) {
                Text(g.name).font(.headline)
                Text(g.platform).font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.18)).clipShape(Capsule())
                Text(g.desc).font(.subheadline).foregroundColor(.secondary)
                actions(g).padding(.top, 2)
            }
            Spacer(minLength: 0)
            Button { toggle(g) } label: {
                Image(systemName: favs.contains(g.name) ? "star.fill" : "star").foregroundColor(.yellow)
            }.buttonStyle(.borderless)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { c in
                            Button(c) { category = c }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(category == c ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(category == c ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }.padding(.horizontal)
                }.padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { card($0) }
                        if filtered.isEmpty {
                            Text("Aucun jeu").foregroundColor(.secondary).padding(.top, 40)
                        }
                    }.padding(.horizontal).padding(.bottom, 20)
                }.id(dm.refresh)
            }
            .navigationTitle("FanVerse")
            .searchable(text: $search, prompt: "Rechercher un jeu")
            .alert("Erreur", isPresented: Binding(get: { dm.error != nil }, set: { _ in dm.error = nil })) {
                Button("OK", role: .cancel) {}
            } message: { Text(dm.error ?? "") }
        }
    }
}
