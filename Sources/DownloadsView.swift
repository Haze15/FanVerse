import SwiftUI
import UIKit

/// Barre de progression en dégradé (déterminée ou animée si la taille est inconnue)
struct DLBar: View {
    let progress: Double?
    var height: CGFloat = 8
    @State private var phase: CGFloat = -0.35

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemFill))
                if let p = progress {
                    Capsule().fill(fvGradient)
                        .frame(width: max(height, geo.size.width * CGFloat(p)))
                        .animation(.easeOut(duration: 0.25), value: p)
                } else {
                    Capsule().fill(fvGradient)
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: geo.size.width * phase)
                        .onAppear {
                            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { phase = 1 }
                        }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
    }
}

/// Icône selon le type de fichier
func fileSymbol(_ name: String) -> (String, Color) {
    switch (name as NSString).pathExtension.lowercased() {
    case "deltaskin", "manicskin": return ("paintpalette.fill", .fvPink)
    case "ipa": return ("app.badge.fill", .fvBlue)
    case "zip", "7z", "rar": return ("doc.zipper", .orange)
    case "ips", "bps", "ups", "xdelta", "ppf": return ("bandage.fill", .green)
    case "gba", "gbc", "gb", "nds", "sfc", "smc", "z64", "n64", "v64", "nes", "3ds", "cia":
        return ("gamecontroller.fill", .fvPurple)
    default: return ("doc.fill", .gray)
    }
}

/// Petite barre flottante qui montre le téléchargement en cours
struct DownloadMiniBar: View {
    let item: Downloader.Item
    let count: Int
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: CGFloat(item.progress ?? 0.05))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "arrow.down").font(.caption.weight(.heavy))
                }
                .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(count > 1 ? "\(item.name)  +\(count - 1)" : item.name)
                        .font(.subheadline.weight(.bold)).lineLimit(1)
                    Text(Fmt.status(item)).font(.caption2.weight(.medium)).opacity(0.9).lineLimit(1)
                }
                Spacer(minLength: 0)
                if onTap != nil { Image(systemName: "chevron.up").font(.caption.weight(.bold)) }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(fvGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

struct DownloadRow: View {
    let item: Downloader.Item
    @ObservedObject private var dl = Downloader.shared

    var failed: Bool {
        if case .failed = item.state { return true }
        return false
    }

    var body: some View {
        let (sym, color) = fileSymbol(item.name)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconTile(symbol: sym, color: color, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(Fmt.status(item))
                        .font(.caption)
                        .foregroundColor(failed ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                switch item.state {
                case .running:
                    Button { dl.cancel(item.id) } label: {
                        Image(systemName: "xmark.circle.fill").font(.title3).foregroundColor(.secondary)
                    }
                case .done:
                    if let f = item.file {
                        ShareLink(item: f) { Image(systemName: "square.and.arrow.up").font(.title3) }
                    }
                case .failed, .cancelled:
                    if item.source != nil {
                        Button { dl.retry(item.id) } label: {
                            Image(systemName: "arrow.clockwise.circle.fill").font(.title3)
                        }
                    }
                }
            }
            if item.isRunning { DLBar(progress: item.progress) }
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}

struct FileRow: View {
    let url: URL

    var body: some View {
        let (sym, color) = fileSymbol(url.lastPathComponent)
        HStack(spacing: 12) {
            IconTile(symbol: sym, color: color, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent).font(.subheadline.weight(.semibold)).lineLimit(2)
                Text("\(Fmt.bytes(Downloader.size(url))) · \(url.deletingLastPathComponent().lastPathComponent)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            ShareLink(item: url) {
                Text("Ouvrir").font(.subheadline.weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.fvPurple.opacity(0.15)))
            }
            .buttonStyle(.borderless)
        }
    }
}

struct DownloadsView: View {
    @ObservedObject private var dl = Downloader.shared
    @State private var link = ""
    @FocusState private var focused: Bool

    let quickSites: [(String, String)] = [
        ("Delta Styles", "https://deltastyles.com"),
        ("Delta Skins", "https://delta-skins.github.io"),
        ("Skins4Delta", "https://skins4delta.com/pages/gba"),
        ("Silent Hill iOS", "https://github.com/SlickAmogus/silent-hill-decomp/releases/tag/realtime"),
    ]

    func download() {
        if dl.start(link) {
            link = ""
            focused = false
        }
    }

    var urlBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link").foregroundColor(.secondary)
                TextField("Colle un lien direct…", text: $link)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .focused($focused)
                    .onSubmit(download)
                Button {
                    if let s = UIPasteboard.general.string { link = s }
                } label: {
                    Image(systemName: "doc.on.clipboard").foregroundColor(.fvPurple)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                Button(action: download) {
                    Label("Télécharger", systemImage: "arrow.down.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(fvGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.borderless)
                .disabled(link.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(link.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                Button {
                    let t = link.trimmingCharacters(in: .whitespacesAndNewlines)
                    if t.isEmpty {
                        Router.shared.open("https://duckduckgo.com")
                    } else {
                        Router.shared.open(t.contains("://") ? t : (t.contains(".") ? "https://" + t : search(t)))
                    }
                } label: {
                    Label("Navigateur", systemImage: "safari.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.fvPurple.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    urlBar
                } footer: {
                    Text("Lien direct vers un fichier (.deltaskin, .zip, .ips, .bps, .ipa…). Les liens Dropbox, Google Drive et GitHub sont convertis tout seuls. Pour un site avec un bouton de téléchargement, utilise le navigateur.")
                }

                Section("Sites rapides") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickSites, id: \.0) { site in
                                Button { Router.shared.open(site.1, folder: site.0.contains("Skin") || site.0.contains("Delta") ? "Skins" : Downloader.generalFolder) } label: {
                                    Text(site.0).font(.footnote.weight(.semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                if !dl.items.isEmpty {
                    Section {
                        ForEach(dl.items) { item in
                            DownloadRow(item: item)
                                .swipeActions {
                                    Button(role: .destructive) { dl.remove(item.id) } label: {
                                        Label(item.isRunning ? "Annuler" : "Retirer", systemImage: "xmark")
                                    }
                                }
                        }
                    } header: {
                        HStack {
                            Text("Téléchargements")
                            Spacer()
                            if dl.items.contains(where: { !$0.isRunning }) {
                                Button("Effacer") { withAnimation { dl.clearFinished() } }
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }

                Section {
                    if dl.files.isEmpty {
                        Text("Aucun fichier pour l'instant.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(dl.files, id: \.self) { url in
                        FileRow(url: url)
                            .swipeActions {
                                Button(role: .destructive) { dl.deleteFile(url) } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                ShareLink(item: url) { Label("Ouvrir avec…", systemImage: "square.and.arrow.up") }
                                Button(role: .destructive) { dl.deleteFile(url) } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("Mes fichiers (\(dl.files.count))")
                } footer: {
                    Text("« Ouvrir » → choisis Delta pour un skin ou une ROM, SideStore/AltStore pour un .ipa. Tout est aussi dans l'app Fichiers → Sur mon iPhone → FanVerse.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Téléchargements")
            .refreshable { dl.reloadFiles() }
            .onAppear { dl.reloadFiles() }
        }
    }
}
