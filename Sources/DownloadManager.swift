import Foundation

final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: [String: Double] = [:]
    @Published var sizeText: [String: String] = [:]
    @Published var error: String?
    @Published var refresh = 0

    private var tasks: [Int: String] = [:]
    private var running: [String: URLSessionDownloadTask] = [:]
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    static var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static func folder(for game: Game) -> URL {
        root.appendingPathComponent(game.name.replacingOccurrences(of: "/", with: "-"), isDirectory: true)
    }
    func localFile(for game: Game) -> URL? {
        let items = try? FileManager.default.contentsOfDirectory(at: Self.folder(for: game), includingPropertiesForKeys: nil)
        return items?.first
    }

    func start(_ game: Game, from link: String) {
        let clean = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard progress[game.name] == nil, let url = URL(string: clean), url.scheme?.hasPrefix("http") == true else {
            error = "Lien de téléchargement invalide"
            return
        }
        let task = session.downloadTask(with: url)
        tasks[task.taskIdentifier] = game.name
        running[game.name] = task
        progress[game.name] = 0
        sizeText[game.name] = ""
        task.resume()
    }

    func cancel(_ game: Game) {
        running[game.name]?.cancel()
    }

    func delete(_ game: Game) {
        try? FileManager.default.removeItem(at: Self.folder(for: game))
        refresh += 1
    }

    private func fmt(_ b: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten w: Int64, totalBytesExpectedToWrite t: Int64) {
        guard let name = tasks[downloadTask.taskIdentifier] else { return }
        if t > 0 {
            progress[name] = Double(w) / Double(t)
            sizeText[name] = "\(fmt(w)) / \(fmt(t))"
        } else {
            sizeText[name] = fmt(w)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let name = tasks[downloadTask.taskIdentifier],
              let game = allGames.first(where: { $0.name == name }) else { return }
        if let http = downloadTask.response as? HTTPURLResponse, http.statusCode >= 400 {
            error = "Le serveur a répondu \(http.statusCode) : vérifie le lien."
            return
        }
        let fm = FileManager.default
        let dir = Self.folder(for: game)
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = downloadTask.response?.suggestedFilename ?? downloadTask.originalRequest?.url?.lastPathComponent ?? "fichier"
        do { try fm.moveItem(at: location, to: dir.appendingPathComponent(fileName)) }
        catch { self.error = error.localizedDescription }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError err: Error?) {
        if let name = tasks[task.taskIdentifier] {
            progress[name] = nil
            sizeText[name] = nil
            running[name] = nil
            tasks[task.taskIdentifier] = nil
        }
        if let err = err, (err as NSError).code != NSURLErrorCancelled { error = err.localizedDescription }
        refresh += 1
    }
}
