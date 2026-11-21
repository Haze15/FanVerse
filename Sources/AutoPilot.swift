import UIKit
import WebKit

/// Ouvre une page officielle dans un navigateur invisible et clique tout seul sur
/// le bouton de téléchargement (itch.io, MediaFire, Google Drive, forums…).
/// L'utilisateur ne voit que la barre de progression.
final class AutoPilot {
    static let shared = AutoPilot()
    private var sessions: [UUID: AutoSession] = [:]

    func run(page: URL, id: UUID, folder: String) {
        let s = AutoSession(id: id, page: page)
        s.onEnd = { [weak self] in self?.sessions[id] = nil }
        sessions[id] = s
        s.start()
    }
}

final class AutoSession: NSObject, WKNavigationDelegate, WKUIDelegate {
    let id: UUID
    let page: URL
    let webView: WKWebView
    var onEnd: (() -> Void)?
    private var timer: Timer?
    private let started = Date()
    private var gotDownload = false

    init(id: UUID, page: URL) {
        self.id = id
        self.page = page
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), configuration: config)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    func start() {
        // Une vue web doit être dans une fenêtre pour bien exécuter les scripts : on la cache derrière tout.
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        if let w = window {
            webView.alpha = 0.01
            webView.isUserInteractionEnabled = false
            w.insertSubview(webView, at: 0)
        }
        webView.load(URLRequest(url: page))
        let t = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let dl = Downloader.shared
        guard let item = dl.items.first(where: { $0.id == id }) else { stop(); return }
        if !item.isRunning { stop(); return }      // terminé, annulé ou en erreur
        if gotDownload { return }                    // le fichier arrive : on attend la fin
        if Date().timeIntervalSince(started) > 50 {
            dl.failAuto(id, page: page.absoluteString)
            stop()
            return
        }
        webView.evaluateJavaScript(Self.clickJS, completionHandler: nil)
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        if !gotDownload { webView.stopLoading() }
        webView.removeFromSuperview()
        onEnd?()
        onEnd = nil
    }

    // MARK: - Navigation

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload { decisionHandler(.download); return }
        if let u = navigationAction.request.url, BrowserModel.fileExts.contains(u.pathExtension.lowercased()) {
            decisionHandler(.download); return
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
        if attachment || !navigationResponse.canShowMIMEType || BrowserModel.fileExts.contains(ext) {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        took(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        took(download)
    }

    private func took(_ d: WKDownload) {
        guard !gotDownload else { d.cancel { _ in }; return }
        gotDownload = true
        Downloader.shared.attach(d, toItem: id)
    }

    // MARK: - Le « clic » automatique

    static let clickJS = #"""
    (function () {
      window.__fv = window.__fv || { clicked: [] };
      var key = function (el) { return el.href || el.id || (el.className + el.textContent).slice(0, 80); };
      var seen = function (el) { return window.__fv.clicked.indexOf(key(el)) >= 0; };
      var press = function (el) { window.__fv.clicked.push(key(el)); el.click(); return 'click'; };
      var dlText = /download|descarg|t[ée]l[ée]charg|joiplay|android|mobile|link/i;

      // itch.io : liste des fichiers → version JoiPlay/Android de préférence (lisible par RPGPlayer), jamais .exe/.apk
      var ups = Array.prototype.slice.call(document.querySelectorAll('.upload'));
      if (ups.length) {
        var pick = ups.find(function (u) { return /joiplay|android|mobile/i.test(u.textContent) && !/\.apk/i.test(u.textContent); })
                || ups.find(function (u) { return !/\.exe|launcher|\.apk|setup/i.test(u.textContent); })
                || ups[0];
        var b = pick.querySelector('.download_btn');
        if (b && !seen(b)) return press(b);
      }
      var sels = ['#downloadButton', '#uc-download-link', 'form#download-form [type=submit]',
                  'a.direct_download_btn', 'a.button.download_btn', '.download_btn',
                  'a[href*="/releases/download/"]'];
      for (var i = 0; i < sels.length; i++) {
        var el = document.querySelector(sels[i]);
        if (el && !seen(el)) return press(el);
      }
      // Forums : premier lien vers un hébergeur de fichiers
      var bad = /discord|imgur|youtube|youtu\.be|twitter|x\.com|reddit|patreon|ko-fi|wiki/i;
      var links = Array.prototype.slice.call(document.querySelectorAll('a[href]'))
        .filter(function (a) { return !bad.test(a.href) && !seen(a); });
      var strong = ['mediafire.com', 'drive.google.com', 'drive.usercontent.google.com', 'dropbox.com',
                    'mega.nz', '1fichier.com', 'pixeldrain.com', 'gofile.io'];
      for (var h = 0; h < strong.length; h++) {
        var c = links.filter(function (a) { return a.href.indexOf(strong[h]) >= 0; });
        c.sort(function (a, b) { return (dlText.test(b.textContent) ? 1 : 0) - (dlText.test(a.textContent) ? 1 : 0); });
        if (c.length) { window.__fv.clicked.push(key(c[0])); window.location.href = c[0].href; return 'nav'; }
      }
      var itch = links.filter(function (a) { return a.href.indexOf('itch.io') >= 0 && dlText.test(a.textContent); });
      if (itch.length) { window.__fv.clicked.push(key(itch[0])); window.location.href = itch[0].href; return 'nav'; }
      // Site officiel : suivre une seule fois le lien interne vers la page « Download / Descargar »
      if (!sessionStorage.getItem('fvFollowed')) {
        var inner = links.find(function (a) {
          return a.host === location.host && a.href !== location.href &&
                 (/download|descarga|telechargement/i.test(a.pathname) || /^\s*(download|descargar|télécharger)/i.test(a.textContent));
        });
        if (inner) { sessionStorage.setItem('fvFollowed', '1'); window.location.href = inner.href; return 'nav'; }
      }
      return 'none';
    })();
    """#
}
