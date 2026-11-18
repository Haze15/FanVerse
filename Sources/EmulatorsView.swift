import SwiftUI

struct EmulatorsView: View {
    func row(_ e: Emulator) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(symbol: e.symbol, color: e.color)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(e.name).font(.headline)
                    Spacer()
                    if e.appStore {
                        FVTag(text: "App Store", color: .fvBlue)
                    } else {
                        FVTag(text: "Sideload", color: .orange)
                    }
                }
                Text(e.systems.joined(separator: " · "))
                    .font(.caption.weight(.semibold)).foregroundColor(e.color)
                Text(e.desc).font(.subheadline).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    if e.jit { FVTag(text: "⚡️ JIT requis", color: .red) }
                    Spacer()
                    if let u = URL(string: e.url) {
                        Link(destination: u) { Label("Ouvrir", systemImage: "safari") }
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .fvCard()
    }

    var body: some View {
        ScrollView {
                LazyVStack(spacing: 12) {
                    Text("Pour jouer aux ROM hacks de la liste Fangames. Les émulateurs ne contiennent aucun jeu : utilise tes propres sauvegardes de cartouches.")
                        .font(.footnote).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(allEmulators) { row($0) }
                }
                .padding(.horizontal).padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Émulateurs")
    }
}
