import SwiftUI
import UIKit
import LinkPresentation
import CryptoKit

/// Récupère l'image d'aperçu officielle d'une page (la même que dans Messages : balise og:image)
/// et la garde en cache sur l'iPhone.
final class PreviewStore: ObservableObject {
    static let shared = PreviewStore()

    @Published private(set) var images: [String: UIImage] = [:]
    private var failed: Set<String> = []
    private var loading: Set<String> = []
    private var providers: [String: LPMetadataProvider] = [:]

    private let dir: URL = {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("previews", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private func cacheFile(_ link: String) -> URL {
        let hash = Insecure.MD5.hash(data: Data(link.utf8)).map { String(format: "%02x", $0) }.joined()
        return dir.appendingPathComponent(hash + ".jpg")
    }

    private func noneFile(_ link: String) -> URL {
        cacheFile(link).deletingPathExtension().appendingPathExtension("none")
    }

    static func canPreview(_ link: String) -> Bool {
        guard let host = URL(string: link)?.host?.lowercased() else { return false }
        return !host.contains("duckduckgo")
    }

    func load(_ link: String) {
        guard images[link] == nil, !failed.contains(link), !loading.contains(link),
              Self.canPreview(link), let url = URL(string: link) else { return }

        // Cache disque
        if let data = try? Data(contentsOf: cacheFile(link)), let img = UIImage(data: data) {
            images[link] = img
            return
        }
        // Page déjà testée sans image (on retente au bout de 3 jours)
        if let attrs = try? FileManager.default.attributesOfItem(atPath: noneFile(link).path),
           let date = attrs[.modificationDate] as? Date, Date().timeIntervalSince(date) < 3 * 86400 {
            failed.insert(link)
            return
        }

        loading.insert(link)
        let provider = LPMetadataProvider()
        provider.timeout = 15
        providers[link] = provider
        provider.startFetchingMetadata(for: url) { [weak self] meta, _ in
            guard let ip = meta?.imageProvider, ip.canLoadObject(ofClass: UIImage.self) else {
                DispatchQueue.main.async { self?.finish(link, nil) }
                return
            }
            ip.loadObject(ofClass: UIImage.self) { obj, _ in
                let img = (obj as? UIImage).flatMap(Self.prepare)
                DispatchQueue.main.async { self?.finish(link, img) }
            }
        }
    }

    /// Redimensionne et écarte les images trop petites (icônes).
    private static func prepare(_ img: UIImage) -> UIImage? {
        let w = img.size.width * img.scale
        guard w >= 200, img.size.height > 0 else { return nil }
        let maxW: CGFloat = 900
        if w <= maxW { return img }
        let ratio = maxW / w
        let size = CGSize(width: maxW, height: img.size.height * img.scale * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            img.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func finish(_ link: String, _ img: UIImage?) {
        loading.remove(link)
        providers[link] = nil
        if let img = img {
            images[link] = img
            if let data = img.jpegData(compressionQuality: 0.8) { try? data.write(to: cacheFile(link)) }
        } else {
            failed.insert(link)
            try? Data().write(to: noneFile(link))
        }
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        images = [:]
        failed = []
    }
}

/// Bannière d'aperçu : n'apparaît que si la page a une vraie image.
struct PreviewBanner: View {
    let link: String
    var height: CGFloat = 150
    var corner: CGFloat = 12
    var gap: CGFloat = 10
    @ObservedObject private var store = PreviewStore.shared

    var body: some View {
        Group {
            if let img = store.images[link] {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay(Image(uiImage: img).resizable().scaledToFill())
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .padding(.bottom, gap)
                    .transition(.opacity)
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .animation(.easeOut(duration: 0.3), value: store.images[link] != nil)
        .onAppear { store.load(link) }
    }
}
