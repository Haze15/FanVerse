import SwiftUI

@main
struct FangamesApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @State private var gameCategory = "Tous"

    var body: some View {
        TabView(selection: $tab) {
            HomeView(tab: $tab, gameCategory: $gameCategory)
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(AppTab.home)
            GamesView(category: $gameCategory)
                .tabItem { Label("Fangames", systemImage: "star.fill") }
                .tag(AppTab.games)
            PortsView()
                .tabItem { Label("Recomps", systemImage: "cpu.fill") }
                .tag(AppTab.ports)
            EmulatorsView()
                .tabItem { Label("Émulateurs", systemImage: "gamecontroller.fill") }
                .tag(AppTab.emulators)
            SkinsView()
                .tabItem { Label("Skins", systemImage: "paintpalette.fill") }
                .tag(AppTab.skins)
        }
        .tint(.fvPurple)
    }
}
