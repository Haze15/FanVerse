import SwiftUI

/// Skin trouvé sur delta-skins.github.io
struct SkinEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let file: URL
    let image: URL?
}

/// Lit les pages de delta-skins.github.io et en extrait les fichiers .deltaskin,
/// pour les télécharger en un seul tap.
final class SkinGallery: ObservableObject {
    static let shared = SkinGallery()
    static let site = "https://delta-skins.github.io"
    static let consoles: [(String, String)] = [
        ("GBA", "gba"), ("GBC", "gbc"), ("SNES", "snes"), ("N64", "n64"), ("NES", "nes"), ("DS", "nds"),
    ]

    @Published private(set) var entries: [String: [SkinEntry]] = [:]
    @Published private(set) var loading: Set<String> = []
    @Published private(set) var failed: Set<String> = []

    func pageURL(_ slug: String) -> URL? { URL(string: "\(Self.site)/\(slug).html") }

    func load(_ slug: String, force: Bool = false) {
        guard force || (entries[slug] == nil && !loading.contains(slug)), let url = pageURL(slug) else { return }
        loading.insert(slug)
        failed.remove(slug)
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let html = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let list = Self.parse(html, base: url)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.remove(slug)
                if list.isEmpty { self.failed.insert(slug) } else { self.entries[slug] = list }
            }
        }.resume()
    }

    private static func resolve(_ raw: String, base: URL) -> URL? {
        let v = raw.replacingOccurrences(of: "&amp;", with: "&")
        let enc = v.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed.union(CharacterSet(charactersIn: "%#"))) ?? v
        return URL(string: v, relativeTo: base)?.absoluteURL ?? URL(string: enc, relativeTo: base)?.absoluteURL
    }

    /// Parcourt les attributs src/href dans l'ordre : chaque lien de skin est associé
    /// à la dernière image vue juste avant (l'aperçu du skin).
    static func parse(_ html: String, base: URL) -> [SkinEntry] {
        guard let re = try? NSRegularExpression(pattern: #"(src|href)\s*=\s*["']([^"']+)["']"#,
                                                options: [.caseInsensitive]) else { return [] }
        let ns = html as NSString
        var lastImage: URL? = nil
        var seen = Set<String>()
        var out: [SkinEntry] = []
        let imageExts = ["png", "jpg", "jpeg", "webp", "gif"]
        for m in re.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let attr = ns.substring(with: m.range(at: 1)).lowercased()
            let value = ns.substring(with: m.range(at: 2))
            guard let u = resolve(value, base: base) else { continue }
            let low = value.lowercased()
            let ext = u.pathExtension.lowercased()
            if attr == "src" && imageExts.contains(ext) {
                lastImage = u
                continue
            }
            let host = u.host?.lowercased() ?? ""
            let isSkin = low.contains(".deltaskin")
                || (attr == "href" && (host.contains("dropbox.com") || host.contains("drive.google.com")
                                       || host.contains("mediafire.com")))
            guard attr == "href", isSkin, !seen.contains(u.absoluteString) else { continue }
            seen.insert(u.absoluteString)
            var name = (u.lastPathComponent as NSString).deletingPathExtension
            name = name.removingPercentEncoding ?? name
            if name.isEmpty || !low.contains(".deltaskin"), let img = lastImage {
                name = ((img.lastPathComponent as NSString).deletingPathExtension).removingPercentEncoding ?? name
            }
            out.append(SkinEntry(name: name, file: u, image: lastImage))
            lastImage = nil
        }
        return out
    }
}

struct SkinGalleryView: View {
    @ObservedObject private var gallery = SkinGallery.shared
    @ObservedObject private var dl = Downloader.shared
    @State private var console = "GBA"

    var slug: String { SkinGallery.consoles.first { $0.0 == console }?.1 ?? "gba" }

    func runningItem(_ s: SkinEntry) -> Downloader.Item? {
        dl.items.first { $0.source == s.file && $0.isRunning }
    }
    func done(_ s: SkinEntry) -> Downloader.Item? {
        dl.items.first { $0.source == s.file && $0.state == .done }
    }

    func cell(_ s: SkinEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Color(.tertiarySystemFill)
                if let img = s.image {
                    AsyncImage(url: img) { phase in
                        if let i = phase.image {
                            i.resizable().scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                } else {
                    Image(systemName: "paintpalette.fill").font(.largeTitle).foregroundColor(.fvPink)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(s.name).font(.footnote.weight(.semibold)).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let it = runningItem(s) {
                DLBar(progress: it.progress, height: 6)
                Text(it.progress.map { "\(Int($0 * 100)) %" } ?? "…")
                    .font(.caption2).foregroundColor(.secondary)
            } else if let it = done(s), let f = it.file {
                ShareLink(item: f) {
                    Label("Ouvrir dans Delta", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.bold)).foregroundColor(.green)
                }
            } else {
                Button {
                    dl.start(s.file.absoluteString, name: s.name, folder: "Skins")
                } label: {
                    Label("Télécharger", systemImage: "arrow.down.circle.fill")
                        .font(.caption.weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(fvGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Télécharger en un tap", subtitle: "Skins de delta-skins.github.io, prêts pour Delta")
            Picker("Console", selection: $console) {
                ForEach(SkinGallery.consoles, id: \.0) { Text($0.0).tag($0.0) }
            }
            .pickerStyle(.segmented)

            if let list = gallery.entries[slug] {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(list) { cell($0) }
                }
            } else if gallery.failed.contains(slug) {
                VStack(spacing: 10) {
                    Text("Impossible de lire la liste automatiquement.")
                        .font(.footnote).foregroundColor(.secondary)
                    HStack {
                        Button("Réessayer") { gallery.load(slug, force: true) }
                        Spacer()
                        Button("Ouvrir le site") {
                            Router.shared.open(gallery.pageURL(slug)?.absoluteString ?? SkinGallery.site, folder: "Skins")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .fvCard()
            } else {
                HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 30)
            }
        }
        .onAppear { gallery.load(slug) }
        .task(id: slug) { gallery.load(slug) }
    }
}
