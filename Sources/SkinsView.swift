import SwiftUI

struct SkinsView: View {
    @State private var group = "Delta"

    var importSteps: [String] {
        [
            "Ouvre un des sites ci-dessous dans Safari et télécharge un skin (fichier .deltaskin).",
            "Il arrive dans l'app Fichiers → Téléchargements.",
            "Dans Delta : touche « + » dans la bibliothèque → Fichiers, puis choisis le .deltaskin.",
            "Réglages Delta → Skins de manette → choisis la console et l'orientation, puis ton skin.",
        ]
    }

    var hero: some View {
        ZStack(alignment: .bottomLeading) {
            fvGradient
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 110))
                .foregroundColor(.white.opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
            VStack(alignment: .leading, spacing: 4) {
                Text("Skins").font(.largeTitle.weight(.heavy))
                Text("Delta, Manic EMU, Provenance… tous les bons sites au même endroit.")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(18)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func row(_ s: SkinSource) -> some View {
        Group {
            if let u = URL(string: s.url) {
                Link(destination: u) {
                    HStack(spacing: 12) {
                        IconTile(symbol: s.symbol, color: .fvPink, size: 42)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.name).font(.headline).foregroundColor(.primary)
                            Text(s.desc).font(.footnote).foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.footnote.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    .fvCard()
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    Picker("Appli", selection: $group) {
                        ForEach(skinGroups, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 10) {
                        ForEach(allSkinSources.filter { $0.group == group }) { row($0) }
                    }

                    SectionTitle(title: "Installer un skin dans Delta")
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(importSteps.enumerated()), id: \.offset) { i, s in
                            StepRow(number: i + 1, text: s)
                        }
                    }
                    .fvCard()

                    Text("Astuce : Manic EMU accepte aussi les fichiers .deltaskin.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding(.horizontal).padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Skins")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
