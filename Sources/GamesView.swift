import SwiftUI

let installCat = "📥 Installés"
let frCat = "🇫🇷 FR"
let iphoneCat = "📱 iPhone"
let favCat = "⭐️ Favoris"

let categoryColors: [String: Color] = [
    "Pokémon": .red, "Sonic": .blue, "Mario": .orange,
    "Zelda": .green, "Undertale": .yellow,
    "Smash": .pink, "Metroid": .teal, "Kirby": .mint,
    "Mega Man": .cyan, "Autres": .gray,
]
let categorySymbols: [String: String] = [
    "Pokémon": "circle.lefthalf.filled", "Sonic": "hare.fill", "Mario": "star.circle.fill",
    "Zelda": "shield.fill", "Undertale": "heart.fill", "Smash": "bolt.fill",
    "Metroid": "scope", "Kirby": "cloud.fill", "Mega Man": "bolt.circle.fill",
    "Autres": "gamecontroller.fill",
]

struct LogoView: View {
    let game: Game
    let color: Color

    var fallback: some View {
        IconTile(symbol: categorySymbols[game.category] ?? "gamecontroller.fill", color: color)
    }

    var body: some View {
        Group {
            if let u = game.logoURL {
                AsyncImage(url: u) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFit().padding(7)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                    } else { fallback }
                }
            } else { fallback }
        }
        .frame(width: 48, height: 48)
    }
}

struct LinkSheet: View {
    let game: Game
    let onSave: (String) -> Void
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(game: Game, initial: String, onSave: @escaping (String) -> Void) {
        self.game = game
        self.onSave = onSave
        _text = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(game.name),
                        footer: Text("Colle un lien direct vers le fichier (.zip, .ips, .bps…) fourni par le créateur du jeu. Laisse vide pour retirer le lien.")) {
                    TextField("https://…", text: $text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Lien de téléchargement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Enregistrer") { onSave(text); dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

struct GamesView: View {
    @Binding var category: String
    @State private var search = ""
    @State private var linkGame: Game?
    @AppStorage("favs") private var favsRaw = ""
    @AppStorage("customDL") private var customRaw = "{}"
    @ObservedObject private var dl = Downloader.shared

    var favs: Set<String> { Set(favsRaw.split(separator: "|").map(String.init)) }
    var custom: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: Data(customRaw.utf8))) ?? [:]
    }
    var categories: [String] {
        ["Tous", iphoneCat, favCat, frCat, installCat] + Array(Set(allGames.map(\.category))).sorted()
    }

    func dlURL(_ g: Game) -> String? { custom[g.name] ?? g.dl }

    func setCustom(_ name: String, _ url: String) {
        var d = custom
        d[name] = url.isEmpty ? nil : url
        if let data = try? JSONEncoder().encode(d), let s = String(data: data, encoding: .utf8) { customRaw = s }
    }

    var filtered: [Game] {
        allGames.filter { g in
            let okCat: Bool
            switch category {
            case "Tous": okCat = true
            case iphoneCat: okCat = g.onIPhone
            case favCat: okCat = favs.contains(g.name)
            case installCat: okCat = dlURL(g) != nil || dl.localFile(folder: g.name) != nil
            case frCat: okCat = g.fr
            default: okCat = g.category == category
            }
            let okSearch = search.isEmpty
                || g.name.localizedCaseInsensitiveContains(search)
                || g.desc.localizedCaseInsensitiveContains(search)
            return okCat && okSearch
        }
    }

    func toggle(_ g: Game) {
        var s = favs
        if s.contains(g.name) { s.remove(g.name) } else { s.insert(g.name) }
        favsRaw = s.joined(separator: "|")
    }

    @ViewBuilder func actions(_ g: Game) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                Button { Router.shared.open(g.url, folder: g.name) } label: {
                    Label("Site", systemImage: "safari")
                }
                if let it = dl.item(forFolder: g.name) {
                    Button(role: .destructive) { dl.cancel(it.id) } label: { Label("Annuler", systemImage: "xmark.circle") }
                } else if let file = dl.localFile(folder: g.name) {
                    ShareLink(item: file) { Label("Ouvrir", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { dl.deleteFolder(g.name) } label: { Image(systemName: "trash") }
                } else if let s = dlURL(g) {
                    Button { dl.start(s, name: g.name, folder: g.name) } label: {
                        Label("Télécharger", systemImage: "arrow.down.circle.fill")
                    }
                } else {
                    Button { linkGame = g } label: { Label("Lien", systemImage: "link.badge.plus") }
                }
            }
            if let it = dl.item(forFolder: g.name) {
                VStack(alignment: .leading, spacing: 4) {
                    DLBar(progress: it.progress, height: 6)
                    Text(Fmt.status(it)).font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.borderless)
    }

    func card(_ g: Game) -> some View {
        let color = categoryColors[g.category] ?? .purple
        return HStack(alignment: .top, spacing: 12) {
            LogoView(game: g, color: color)
            VStack(alignment: .leading, spacing: 6) {
                Text(g.name).font(.headline)
                HStack(spacing: 6) {
                    FVTag(text: g.platform, color: color)
                    if g.onIPhone { FVTag(text: "📱 iPhone", color: .green) }
                    if g.fr { FVTag(text: "🇫🇷 FR", color: .blue) }
                }
                Text(g.desc).font(.subheadline).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                actions(g).padding(.top, 2)
            }
            Spacer(minLength: 0)
            Button { toggle(g) } label: {
                Image(systemName: favs.contains(g.name) ? "star.fill" : "star").foregroundColor(.yellow)
            }.buttonStyle(.borderless)
        }
        .fvCard()
        .contextMenu {
            Button { linkGame = g } label: { Label("Ajouter un lien direct", systemImage: "link") }
        }
    }

    var emptyText: String {
        switch category {
        case installCat:
            return "Rien de téléchargé pour l'instant.\nTouche « Site » sur un jeu : ce que tu télécharges sur sa page arrive ici."
        case favCat:
            return "Pas encore de favoris.\nTouche l'étoile d'un jeu pour l'ajouter ici."
        default:
            return "Aucun jeu"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterChips(items: categories, selection: $category)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        HStack {
                            Text("\(filtered.count) jeu\(filtered.count > 1 ? "x" : "")")
                                .font(.footnote.weight(.semibold)).foregroundColor(.secondary)
                            Spacer()
                        }
                        ForEach(filtered) { card($0) }
                        if filtered.isEmpty {
                            Text(emptyText)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.top, 40).padding(.horizontal, 30)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fangames")
            .searchable(text: $search, prompt: "Rechercher un jeu")
            .sheet(item: $linkGame) { g in
                LinkSheet(game: g, initial: custom[g.name] ?? g.dl ?? "") {
                    setCustom(g.name, $0.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }
}
