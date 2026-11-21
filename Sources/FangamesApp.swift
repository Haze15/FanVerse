import SwiftUI
import UIKit

@main
struct FangamesApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @ObservedObject private var router = Router.shared
    @ObservedObject private var dl = Downloader.shared
    @State private var gameCategory = "Tous"
    @AppStorage("pasteboardSeen") private var pasteboardSeen = -1
    @State private var copiedLink = false

    /// Regarde (sans lire son contenu ni déclencher d'alerte) si un lien vient d'être copié.
    func checkPasteboard() {
        let pb = UIPasteboard.general
        let count = pb.changeCount
        guard count != pasteboardSeen else { copiedLink = false; return }
        pb.detectPatterns(for: [.probableWebURL]) { result in
            let found: Bool
            if case .success(let set) = result { found = set.contains(.probableWebURL) } else { found = false }
            DispatchQueue.main.async { withAnimation(.spring()) { copiedLink = found } }
        }
    }

    var pasteBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "link.circle.fill").font(.title2).foregroundColor(.white)
            VStack(alignment: .leading, spacing: 1) {
                Text("Lien copié").font(.subheadline.weight(.bold)).foregroundColor(.white)
                Text("Touche Coller pour le télécharger").font(.caption).foregroundColor(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            PasteButton(payloadType: String.self) { strings in
                DispatchQueue.main.async {
                    pasteboardSeen = UIPasteboard.general.changeCount
                    copiedLink = false
                    if let s = strings.first {
                        router.tab = .downloads
                        router.downloadOrOpen(s)
                    }
                }
            }
            .labelStyle(.titleAndIcon)
            .buttonBorderShape(.capsule)
            .tint(.white)
            Button {
                pasteboardSeen = UIPasteboard.general.changeCount
                withAnimation { copiedLink = false }
            } label: {
                Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(fvGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        .padding(.horizontal, 12)
    }

    var body: some View {
        TabView(selection: $router.tab) {
            HomeView(tab: $router.tab, gameCategory: $gameCategory)
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(AppTab.home)
            GamesView(category: $gameCategory)
                .tabItem { Label("Fangames", systemImage: "star.fill") }
                .tag(AppTab.games)
            PortsView()
                .tabItem { Label("Recomps", systemImage: "cpu.fill") }
                .tag(AppTab.ports)
            SkinsView()
                .tabItem { Label("Skins", systemImage: "paintpalette.fill") }
                .tag(AppTab.skins)
            DownloadsView()
                .tabItem { Label("Téléchargements", systemImage: "arrow.down.circle.fill") }
                .badge(dl.activeCount)
                .tag(AppTab.downloads)
        }
        .tint(.fvPurple)
        // Barre de téléchargement flottante, visible sur tous les onglets
        .overlay(alignment: .bottom) {
            if let it = dl.current, router.tab != .downloads, router.page == nil {
                DownloadMiniBar(item: it, count: dl.activeCount) { router.tab = .downloads }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: dl.activeCount)
        // Bannière « Lien copié » : copie un lien dans Discord, reviens ici, un tap et ça télécharge
        .overlay(alignment: .top) {
            if copiedLink && router.page == nil {
                pasteBanner
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { checkPasteboard() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkPasteboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            checkPasteboard()
        }
        .sheet(item: $router.page) { BrowserView(page: $0) }
        .alert("Téléchargement", isPresented: Binding(get: { dl.error != nil }, set: { _ in dl.error = nil })) {
            Button("OK", role: .cancel) {}
        } message: { Text(dl.error ?? "") }
    }
}
