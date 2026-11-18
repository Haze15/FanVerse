import Foundation

final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: [String: Double] = [:]
    @Published var error: String?
    @Published var refresh = 0

    private var tasks: [Int: String] = [:]
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

    func start(_ game: Game) {
        guard let s = game.dl, let url = URL(string: s) else { return }
        let task = session.downloadTask(with: url)
        tasks[task.taskIdentifier] = game.name
        progress[game.name] = 0
        task.resume()
    }

    func delete(_ game: Game) {
        try? FileManager.default.removeItem(at: Self.folder(for: game))
        refresh += 1
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten w: Int64, totalBytesExpectedToWrite t: Int64) {
        guard let name = tasks[downloadTask.taskIdentifier], t > 0 else { return }
        progress[name] = Double(w) / Double(t)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let name = tasks[downloadTask.taskIdentifier],
              let game = allGames.first(where: { $0.name == name }) else { return }
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
            tasks[task.taskIdentifier] = nil
        }
        if let err = err { error = err.localizedDescription }
        refresh += 1
    }
}
