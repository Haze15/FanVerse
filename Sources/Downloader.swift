import Foundation
import WebKit

/// Gestionnaire de téléchargements unique pour toute l'app :
/// liens directs (URLSession) + fichiers téléchargés depuis le navigateur intégré (WKDownload).
/// Où trouver le fichier à télécharger automatiquement
enum AutoSource {
    /// Lien direct (ou page MediaFire, résolue toute seule)
    case direct(String)
    /// Dernière release GitHub : le nom du fichier doit contenir tous les mots de `must`
    /// et finir par une des extensions `exts`.
    case github(repo: String, tag: String?, must: [String], exts: [String])
}

final class Downloader: NSObject, ObservableObject {
    static let shared = Downloader()

    struct Item: Identifiable {
        enum State: Equatable { case running, done, failed(String), cancelled }

        let id = UUID()
        var name: String
        let source: URL?
        let folder: String
        var written: Int64 = 0
        var total: Int64 = 0
        var speed: Double = 0
        var state: State = .running
        var file: URL?

        var progress: Double? { total > 0 ? min(1, Double(written) / Double(total)) : nil }
        var isRunning: Bool { state == .running }
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var files: [URL] = []
    @Published var error: String?

    static let generalFolder = "Téléchargements"
    static var root: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    static func folderURL(_ name: String) -> URL {
        root.appendingPathComponent(name.replacingOccurrences(of: "/", with: "-"), isDirectory: true)
    }

    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    private var urlTasks: [Int: UUID] = [:]
    private var running: [UUID: URLSessionDownloadTask] = [:]
    private var webIDs: [ObjectIdentifier: UUID] = [:]
    private var webObjects: [UUID: WKDownload] = [:]
    private var observers: [UUID: NSKeyValueObservation] = [:]
    private var speedTick: [UUID: (date: Date, bytes: Int64)] = [:]
    private var lastPublish: [UUID: Date] = [:]

    override init() {
        super.init()
        reloadFiles()
    }

    var activeCount: Int { items.filter(\.isRunning).count }
    var current: Item? { items.first(where: \.isRunning) }

    func item(forFolder folder: String) -> Item? {
        items.first { $0.folder == folder && $0.isRunning }
    }

    func localFile(folder: String) -> URL? {
        let busy = Set(items.filter(\.isRunning).compactMap { $0.file?.standardizedFileURL.path })
        let content = try? FileManager.default.contentsOfDirectory(at: Self.folderURL(folder),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: [.skipsHiddenFiles])
        return content?.first { !busy.contains($0.standardizedFileURL.path) }
    }

    private func index(_ id: UUID) -> Int? { items.firstIndex { $0.id == id } }

    // MARK: - Lancer un téléchargement par lien

    @discardableResult
    func start(_ link: String, name: String? = nil, folder: String = Downloader.generalFolder) -> Bool {
        var clean = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty && !clean.contains("://") { clean = "https://" + clean }
        guard let url = URL(string: clean),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host != nil else {
            error = "Lien invalide. Colle une adresse qui commence par https://"
            return false
        }
        let fixed = Self.directLink(url)
        let item = Item(name: name ?? Self.guessName(fixed), source: fixed, folder: folder)
        items.insert(item, at: 0)
        launch(fixed, id: item.id)
        return true
    }

    /// Lance le transfert. Les pages MediaFire sont résolues toutes seules en lien direct.
    private func launch(_ url: URL, id: UUID) {
        let host = url.host?.lowercased() ?? ""
        if host.hasSuffix("mediafire.com") && !host.hasPrefix("download") {
            var req = URLRequest(url: url)
            req.setValue(Self.desktopUA, forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
                let html = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let direct = Self.mediafireLink(in: html)
                DispatchQueue.main.async {
                    guard let self = self, let i = self.index(id), self.items[i].isRunning else { return }
                    if let d = direct {
                        self.launch(d, id: id)
                    } else {
                        self.items[i].state = .failed("MediaFire n'a pas donné le fichier : la page s'ouvre, touche son bouton de téléchargement.")
                        Router.shared.open(url.absoluteString, folder: self.items[i].folder)
                    }
                }
            }.resume()
            return
        }
        let task = session.downloadTask(with: url)
        urlTasks[task.taskIdentifier] = id
        running[id] = task
        task.resume()
    }

    static let desktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    static func mediafireLink(in html: String) -> URL? {
        if let r = html.range(of: #"https?://download[0-9]*\.mediafire\.com/[^"'\s<>]+"#, options: .regularExpression) {
            return URL(string: String(html[r]))
        }
        if let r = html.range(of: #"data-scrambled-url="[^"]+""#, options: .regularExpression) {
            let attr = String(html[r]).dropFirst("data-scrambled-url=\"".count).dropLast()
            if let d = Data(base64Encoded: String(attr)), let s = String(data: d, encoding: .utf8) {
                return URL(string: s)
            }
        }
        return nil
    }

    // MARK: - Téléchargement automatique (sources officielles)

    /// Télécharge depuis une source officielle, en trouvant tout seul le bon fichier.
    func startAuto(_ src: AutoSource, name: String, folder: String, page: String) {
        switch src {
        case .direct(let link):
            start(link, name: name, folder: folder)
        case .github(let repo, let tag, let must, let exts):
            let item = Item(name: name, source: URL(string: page), folder: folder)
            let id = item.id
            items.insert(item, at: 0)
            let api = tag.map { "https://api.github.com/repos/\(repo)/releases/tags/\($0)" }
                ?? "https://api.github.com/repos/\(repo)/releases?per_page=15"
            guard let apiURL = URL(string: api) else { return }
            var req = URLRequest(url: apiURL)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
                var found: (String, URL)? = nil
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) {
                    let releases = (json as? [[String: Any]]) ?? ((json as? [String: Any]).map { [$0] } ?? [])
                    outer: for rel in releases {
                        for asset in (rel["assets"] as? [[String: Any]]) ?? [] {
                            guard let n = asset["name"] as? String,
                                  let s = asset["browser_download_url"] as? String,
                                  let u = URL(string: s) else { continue }
                            let low = n.lowercased()
                            if must.allSatisfy({ low.contains($0) })
                                && (exts.isEmpty || exts.contains(where: { low.hasSuffix($0) })) {
                                found = (n, u)
                                break outer
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    guard let self = self, let i = self.index(id), self.items[i].isRunning else { return }
                    if let f = found {
                        self.items[i].name = f.0
                        self.launch(f.1, id: id)
                    } else {
                        self.items[i].state = .failed("Pas de fichier pour iPhone dans la dernière version : la page du projet s'ouvre.")
                        Router.shared.open(page, folder: folder)
                    }
                }
            }.resume()
        }
    }

    /// Transforme les liens de partage courants en liens de téléchargement direct.
    static func directLink(_ url: URL) -> URL {
        let s = url.absoluteString
        let host = url.host?.lowercased() ?? ""
        // Dropbox : ?dl=0 → ?dl=1
        if host.contains("dropbox.com") {
            var c = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var q = (c?.queryItems ?? []).filter { $0.name != "dl" }
            q.append(URLQueryItem(name: "dl", value: "1"))
            c?.queryItems = q
            return c?.url ?? url
        }
        // GitHub : /blob/ → /raw/
        if host == "github.com" && s.contains("/blob/") {
            return URL(string: s.replacingOccurrences(of: "/blob/", with: "/raw/")) ?? url
        }
        // Google Drive : /file/d/<id>/view → lien de téléchargement
        if host.contains("drive.google.com"), let r = s.range(of: "/file/d/") {
            let id = s[r.upperBound...].split(separator: "/").first.map(String.init) ?? ""
            if !id.isEmpty, let u = URL(string: "https://drive.google.com/uc?export=download&id=\(id)") { return u }
        }
        return url
    }

    /// Le lien pointe-t-il directement vers un fichier ?
    static func looksDirect(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        if host.contains("cdn.discordapp.com") || host.contains("media.discordapp.net")
            || host.contains("dropbox.com") || host.contains("githubusercontent.com")
            || url.absoluteString.contains("/releases/download/") || url.absoluteString.contains("/raw/")
            || (host.contains("drive.google.com") && url.absoluteString.contains("/file/d/")) {
            return true
        }
        let pageHosts = ["mediafire.com", "mega.nz", "mega.io", "1fichier.com", "pixeldrain.com",
                         "gofile.io", "discord.com", "discord.gg", "duckduckgo.com"]
        if pageHosts.contains(where: { host.hasSuffix($0) }) { return false }
        let ext = url.pathExtension.lowercased()
        let pageExts: Set<String> = ["", "html", "htm", "php", "asp", "aspx", "jsp"]
        return !pageExts.contains(ext)
    }

    static func guessName(_ url: URL) -> String {
        let last = url.lastPathComponent
        return (last.isEmpty || last == "/") ? (url.host ?? "fichier") : last
    }

    // MARK: - Actions

    func cancel(_ id: UUID) {
        running[id]?.cancel()
        webObjects[id]?.cancel { _ in }
        if let i = index(id), items[i].isRunning, running[id] == nil {
            // Transfert web, ou recherche du fichier encore en cours
            items[i].state = .cancelled
            cleanupWeb(id)
        }
    }

    func retry(_ id: UUID) {
        guard let i = index(id), let src = items[i].source else { return }
        let it = items.remove(at: i)
        start(src.absoluteString, name: nil, folder: it.folder)
    }

    func remove(_ id: UUID) {
        if let i = index(id), items[i].isRunning { cancel(id) }
        items.removeAll { $0.id == id }
    }

    func clearFinished() {
        items.removeAll { !$0.isRunning }
    }

    // MARK: - Fichiers

    func reloadFiles() {
        let fm = FileManager.default
        let busy = Set(items.filter(\.isRunning).compactMap { $0.file?.standardizedFileURL.path })
        var out: [URL] = []
        if let en = fm.enumerator(at: Self.root, includingPropertiesForKeys: [.isRegularFileKey],
                                  options: [.skipsHiddenFiles]) {
            for case let u as URL in en {
                let isFile = (try? u.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
                if isFile && !busy.contains(u.standardizedFileURL.path) { out.append(u) }
            }
        }
        files = out.sorted { Self.modDate($0) > Self.modDate($1) }
    }

    func deleteFile(_ url: URL) {
        let fm = FileManager.default
        try? fm.removeItem(at: url)
        let parent = url.deletingLastPathComponent()
        if parent.standardizedFileURL.path != Self.root.standardizedFileURL.path,
           (try? fm.contentsOfDirectory(atPath: parent.path))?.isEmpty == true {
            try? fm.removeItem(at: parent)
        }
        reloadFiles()
    }

    func deleteFolder(_ folder: String) {
        try? FileManager.default.removeItem(at: Self.folderURL(folder))
        reloadFiles()
    }

    static func modDate(_ u: URL) -> Date {
        (try? u.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }

    static func size(_ u: URL) -> Int64 {
        Int64((try? u.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }

    private func uniqueDestination(folder: String, filename: String) -> URL {
        let fm = FileManager.default
        let dir = Self.folderURL(folder)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = filename.replacingOccurrences(of: "/", with: "-")
        var dest = dir.appendingPathComponent(safe)
        let base = (safe as NSString).deletingPathExtension
        let ext = (safe as NSString).pathExtension
        var n = 2
        while fm.fileExists(atPath: dest.path) {
            dest = dir.appendingPathComponent(ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)")
            n += 1
        }
        return dest
    }

    // MARK: - Progression

    private func update(_ id: UUID, written: Int64, total: Int64) {
        guard let i = index(id) else { return }
        let now = Date()
        if let last = speedTick[id] {
            let dt = now.timeIntervalSince(last.date)
            if dt >= 0.5 {
                items[i].speed = Double(written - last.bytes) / dt
                speedTick[id] = (now, written)
            }
        } else {
            speedTick[id] = (now, written)
        }
        // On limite les rafraîchissements de l'écran (~7 par seconde)
        let finished = total > 0 && written >= total
        if let lp = lastPublish[id], now.timeIntervalSince(lp) < 0.15, !finished { return }
        lastPublish[id] = now
        items[i].written = written
        if total > 0 { items[i].total = total }
    }
}

// MARK: - URLSession

extension Downloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let id = urlTasks[downloadTask.taskIdentifier] else { return }
        update(id, written: totalBytesWritten, total: totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let id = urlTasks[downloadTask.taskIdentifier], let i = index(id) else { return }
        let resp = downloadTask.response
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            items[i].state = .failed("Le serveur a répondu \(http.statusCode) : vérifie le lien.")
            return
        }
        if let mime = resp?.mimeType, mime.hasPrefix("text/html") {
            items[i].state = .failed("C'était une page web : elle s'ouvre dans le navigateur, touche le bouton de téléchargement du site.")
            if let src = items[i].source { Router.shared.open(src.absoluteString, folder: items[i].folder) }
            return
        }
        let filename = resp?.suggestedFilename ?? downloadTask.originalRequest?.url?.lastPathComponent ?? "fichier"
        let dest = uniqueDestination(folder: items[i].folder, filename: filename)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            items[i].file = dest
            items[i].name = dest.lastPathComponent
            let size = Self.size(dest)
            items[i].written = size
            items[i].total = size
            items[i].state = .done
            reloadFiles()
        } catch {
            items[i].state = .failed(error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError err: Error?) {
        guard let id = urlTasks.removeValue(forKey: task.taskIdentifier) else { return }
        running[id] = nil
        speedTick[id] = nil
        lastPublish[id] = nil
        guard let i = index(id), let err = err else { return }
        if (err as NSError).code == NSURLErrorCancelled {
            items[i].state = .cancelled
        } else {
            items[i].state = .failed(err.localizedDescription)
        }
    }
}

// MARK: - Navigateur intégré (WKDownload)

extension Downloader: WKDownloadDelegate {
    func attach(_ download: WKDownload, folder: String = Downloader.generalFolder) {
        let src = download.originalRequest?.url
        let item = Item(name: src.map { Downloader.guessName($0) } ?? "fichier", source: src, folder: folder)
        let id = item.id
        items.insert(item, at: 0)
        webIDs[ObjectIdentifier(download)] = id
        webObjects[id] = download
        download.delegate = self
        observers[id] = download.progress.observe(\.completedUnitCount, options: [.new]) { [weak self] p, _ in
            let done = p.completedUnitCount
            let total = p.totalUnitCount
            DispatchQueue.main.async { self?.update(id, written: done, total: total) }
        }
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        guard let id = webIDs[ObjectIdentifier(download)], let i = index(id) else {
            completionHandler(nil)
            return
        }
        let dest = uniqueDestination(folder: items[i].folder, filename: suggestedFilename)
        items[i].name = dest.lastPathComponent
        items[i].file = dest
        if response.expectedContentLength > 0 { items[i].total = response.expectedContentLength }
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        finishWeb(download, error: nil)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        finishWeb(download, error: error)
    }

    private func finishWeb(_ download: WKDownload, error: Error?) {
        guard let id = webIDs[ObjectIdentifier(download)] else { return }
        if let i = index(id) {
            if let error = error {
                if items[i].state == .running {
                    items[i].state = (error as NSError).code == NSURLErrorCancelled
                        ? .cancelled : .failed(error.localizedDescription)
                }
                if let f = items[i].file { try? FileManager.default.removeItem(at: f) }
            } else {
                items[i].state = .done
                if let f = items[i].file {
                    let size = Self.size(f)
                    items[i].written = size
                    items[i].total = size
                }
            }
        }
        cleanupWeb(id)
        webIDs[ObjectIdentifier(download)] = nil
        reloadFiles()
    }

    private func cleanupWeb(_ id: UUID) {
        observers[id]?.invalidate()
        observers[id] = nil
        webObjects[id] = nil
        speedTick[id] = nil
        lastPublish[id] = nil
    }
}

// MARK: - Formatage

enum Fmt {
    static func bytes(_ b: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
    }
    static func status(_ it: Downloader.Item) -> String {
        switch it.state {
        case .running:
            var parts: [String] = []
            if let p = it.progress {
                parts.append("\(Int(p * 100)) %")
                parts.append("\(bytes(it.written)) / \(bytes(it.total))")
            } else {
                parts.append(it.written > 0 ? bytes(it.written) : "Connexion…")
            }
            if it.speed > 0 { parts.append("\(bytes(Int64(it.speed)))/s") }
            return parts.joined(separator: " · ")
        case .done: return "Terminé · \(bytes(it.total))"
        case .failed(let msg): return msg
        case .cancelled: return "Annulé"
        }
    }
}
