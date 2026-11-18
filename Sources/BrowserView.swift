import SwiftUI
import WebKit

/// Page à ouvrir dans le navigateur intégré
struct WebPage: Identifiable {
    let id = UUID()
    let url: URL
    let folder: String
}

/// Navigation globale : onglet courant + navigateur intégré
final class Router: ObservableObject {
    static let shared = Router()
    @Published var tab: AppTab = .home
    @Published var page: WebPage?

    func open(_ link: String, folder: String = Downloader.generalFolder) {
        guard let u = URL(string: link) else { return }
        page = WebPage(url: u, folder: folder)
    }
}

final class BrowserModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    let folder: String
    @Published var progress: Double = 0
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var urlText = ""
    @Published var pageTitle = ""
    @Published var toast: String?
    private var obs: [NSKeyValueObservation] = []

    /// Extensions qu'on télécharge au lieu de les afficher
    static let fileExts: Set<String> = [
        "deltaskin", "manicskin", "zip", "7z", "rar", "ips", "bps", "ups", "xdelta", "ppf",
        "ipa", "gba", "gbc", "gb", "nds", "sfc", "smc", "z64", "n64", "v64", "nes", "3ds", "cia",
    ]

    init(url: URL, folder: String) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        self.folder = folder
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        obs = [
            webView.observe(\.estimatedProgress) { [weak self] w, _ in
                DispatchQueue.main.async { self?.progress = w.estimatedProgress }
            },
            webView.observe(\.canGoBack) { [weak self] w, _ in
                DispatchQueue.main.async { self?.canGoBack = w.canGoBack }
            },
            webView.observe(\.canGoForward) { [weak self] w, _ in
                DispatchQueue.main.async { self?.canGoForward = w.canGoForward }
            },
            webView.observe(\.url) { [weak self] w, _ in
                DispatchQueue.main.async { self?.urlText = w.url?.absoluteString ?? "" }
            },
            webView.observe(\.title) { [weak self] w, _ in
                DispatchQueue.main.async { self?.pageTitle = w.title ?? "" }
            },
        ]
        webView.load(URLRequest(url: url))
    }

    func go(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let looksLikeURL = t.contains(".") && !t.contains(" ")
        let link = looksLikeURL ? (t.contains("://") ? t : "https://" + t) : search(t)
        if let u = URL(string: link) { webView.load(URLRequest(url: u)) }
    }

    private func showToast(_ s: String) {
        toast = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toast == s { self?.toast = nil }
        }
    }

    // Liens target=_blank : on les ouvre dans la même vue
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }
        if let u = navigationAction.request.url, Self.fileExts.contains(u.pathExtension.lowercased()) {
            decisionHandler(.download)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var attachment = false
        if let http = navigationResponse.response as? HTTPURLResponse,
           let cd = http.value(forHTTPHeaderField: "Content-Disposition") {
            attachment = cd.lowercased().contains("attachment")
        }
        let ext = navigationResponse.response.url?.pathExtension.lowercased() ?? ""
        if attachment || !navigationResponse.canShowMIMEType || Self.fileExts.contains(ext) {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        started(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        started(download)
    }

    private func started(_ d: WKDownload) {
        Downloader.shared.attach(d, folder: folder)
        showToast("Téléchargement lancé")
    }
}

struct WebViewRep: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct BrowserView: View {
    @StateObject private var model: BrowserModel
    @ObservedObject private var dl = Downloader.shared
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @FocusState private var editing: Bool

    init(page: WebPage) {
        _model = StateObject(wrappedValue: BrowserModel(url: page.url, folder: page.folder))
    }

    var addressBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Adresse ou recherche", text: $address)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .focused($editing)
                .onSubmit { model.go(address) }
            if editing && !address.isEmpty {
                Button { address = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var bottomBar: some View {
        HStack {
            Button { model.webView.goBack() } label: { Image(systemName: "chevron.backward") }
                .disabled(!model.canGoBack)
            Spacer()
            Button { model.webView.goForward() } label: { Image(systemName: "chevron.forward") }
                .disabled(!model.canGoForward)
            Spacer()
            Button { model.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
            Spacer()
            if let u = model.webView.url {
                Link(destination: u) { Image(systemName: "safari") }
            } else {
                Image(systemName: "safari").foregroundColor(.secondary)
            }
        }
        .font(.title3)
        .padding(.horizontal, 28).padding(.vertical, 10)
        .background(.bar)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    addressBar
                    GeometryReader { geo in
                        Capsule().fill(fvGradient)
                            .frame(width: geo.size.width * CGFloat(model.progress))
                            .opacity(model.progress < 1 ? 1 : 0)
                            .animation(.easeOut(duration: 0.2), value: model.progress)
                    }
                    .frame(height: 3)
                }
                .padding(.horizontal).padding(.top, 6)
                .background(.bar)

                ZStack(alignment: .top) {
                    WebViewRep(webView: model.webView)
                    if let t = model.toast {
                        Label(t, systemImage: "arrow.down.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Capsule().fill(fvGradient))
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: model.toast)

                if let it = dl.current {
                    DownloadMiniBar(item: it, count: dl.activeCount)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                }
                bottomBar
            }
            .navigationTitle(model.pageTitle.isEmpty ? "Navigateur" : model.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                        Router.shared.tab = .downloads
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                }
            }
            .onReceive(model.$urlText) { if !editing { address = $0 } }
        }
    }
}
