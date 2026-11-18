import SwiftUI

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
        .sheet(item: $router.page) { BrowserView(page: $0) }
        .alert("Téléchargement", isPresented: Binding(get: { dl.error != nil }, set: { _ in dl.error = nil })) {
            Button("OK", role: .cancel) {}
        } message: { Text(dl.error ?? "") }
    }
}
