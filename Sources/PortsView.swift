import SwiftUI

struct PortsView: View {
    @ObservedObject private var dl = Downloader.shared
    @State private var filter = "Tous"
    @State private var search = ""
    @State private var showGuide = false

    var filters: [String] { ["Tous"] + PortMethod.allCases.map(\.rawValue) }

    var filtered: [Port] {
        allPorts.filter { p in
            (filter == "Tous" || p.method.rawValue == filter)
            && (search.isEmpty
                || p.name.localizedCaseInsensitiveContains(search)
                || p.game.localizedCaseInsensitiveContains(search)
                || p.console.localizedCaseInsensitiveContains(search))
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IconTile(symbol: "cpu.fill", color: .fvPurple, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recomps & ports natifs").font(.headline)
                    Text("Pas des émulateurs : le jeu tourne en app iOS native.")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            Text("Aucun jeu n'est inclus : il faut toujours ta propre copie (ROM ou fichiers du jeu). La plupart s'installent ensuite avec SideStore, AltStore ou Sideloadly.")
                .font(.footnote).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button { showGuide = true } label: {
                Label("Compiler un port avec GitHub (PadMint)", systemImage: "hammer.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(fvGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .fvCard()
    }

    func row(_ p: Port) -> some View {
        VStack(alignment: .leading, spacing: 0) {
          if p.url != padmintURL { PreviewBanner(link: p.url, height: 130) }
          HStack(alignment: .top, spacing: 12) {
            IconTile(symbol: p.consoleSymbol, color: p.consoleColor)
            VStack(alignment: .leading, spacing: 6) {
                Text(p.name).font(.headline)
                Text(p.game).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    FVTag(text: p.console, color: p.consoleColor)
                    FVTag(text: p.method.rawValue, color: p.method.color)
                }
                Text(p.desc).font(.subheadline).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label(p.needs, systemImage: "doc.badge.plus")
                    .font(.caption).foregroundColor(.secondary)
                HStack(spacing: 16) {
                    if let auto = p.auto {
                        if let it = dl.item(forFolder: p.name) {
                            Button(role: .destructive) { dl.cancel(it.id) } label: {
                                Label("Annuler", systemImage: "xmark.circle")
                            }
                        } else if let f = dl.localFile(folder: p.name) {
                            ShareLink(item: f) { Label("Installer", systemImage: "square.and.arrow.up") }
                        } else {
                            Button { dl.startAuto(auto, name: p.name, folder: p.name, page: p.url) } label: {
                                Label("Télécharger", systemImage: "arrow.down.circle.fill")
                            }
                        }
                    }
                    Button { Router.shared.open(p.url, folder: p.name) } label: {
                        Label(p.method == .padmint ? "Voir le projet" : "Page", systemImage: p.method.symbol)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
                .padding(.top, 2)
                if let it = dl.item(forFolder: p.name) {
                    DLBar(progress: it.progress, height: 6)
                    Text(Fmt.status(it)).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
          }
        }
        .fvCard()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterChips(items: filters, selection: $filter)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filter == "Tous" && search.isEmpty { header }
                        ForEach(filtered) { row($0) }
                        if filtered.isEmpty {
                            Text("Aucun port").foregroundColor(.secondary).padding(.top, 40)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recomps")
            .searchable(text: $search, prompt: "Jeu, console…")
            .sheet(isPresented: $showGuide) { PadMintGuide() }
        }
    }
}

/// Tuto : compiler un port « Pad » sur le Mac gratuit de GitHub, sans Mac.
struct PadMintGuide: View {
    @Environment(\.dismiss) private var dismiss

    let steps = [
        "Connecte-toi à GitHub et ouvre le dépôt PadMint (bouton ci-dessous).",
        "Appuie sur « Fork » pour en faire une copie sur ton compte.",
        "Dans ta copie, ouvre l'onglet « Actions » et active les workflows si GitHub le demande.",
        "Lance « Build a game for iPhone and iPad » et choisis ton jeu.",
        "Quand c'est vert, télécharge le ZIP dans « Artifacts » (gardé 1 jour) et dézippe-le : tu as le .ipa.",
        "Installe le .ipa avec Sideloadly, SideStore ou AltStore.",
        "Ouvre le jeu une fois, puis mets ta ROM dans Fichiers → Sur mon iPhone → (nom du jeu) et appuie sur « Rescan ».",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("PadMint compile les ports (HarkinianPad, MaskPad, SpaghettiPad…) depuis leur code source. Il ne contient aucun jeu : ta ROM reste chez toi et tu l'ajoutes après l'installation.")
                        .font(.subheadline).foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                            StepRow(number: i + 1, text: s)
                        }
                    }
                    .fvCard()
                    Text("Certains ports ne se compilent que sur certaines machines : regarde le tableau de compatibilité dans le README de PadMint.")
                        .font(.footnote).foregroundColor(.secondary)
                    GradientLinkButton(title: "Ouvrir PadMint sur GitHub", symbol: "arrow.up.right.square.fill", url: padmintURL)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compiler avec GitHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
    }
}
