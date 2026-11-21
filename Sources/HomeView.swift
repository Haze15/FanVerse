import SwiftUI

enum AppTab: Hashable { case home, games, ports, skins, downloads }

struct HomeView: View {
    @Binding var tab: AppTab
    @Binding var gameCategory: String
    @ObservedObject private var dl = Downloader.shared
    @State private var showEmulators = false

    var iphoneGames: [Game] { allGames.filter(\.onIPhone) }
    /// D'abord les jeux qui ont un site officiel (donc une image d'aperçu)
    var featuredGames: [Game] {
        Array((iphoneGames.filter { PreviewStore.canPreview($0.url) }
               + iphoneGames.filter { !PreviewStore.canPreview($0.url) }).prefix(12))
    }

    var hero: some View {
        ZStack(alignment: .bottomLeading) {
            fvGradient
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 130))
                .rotationEffect(.degrees(-18))
                .foregroundColor(.white.opacity(0.14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 18, y: -6)
            VStack(alignment: .leading, spacing: 6) {
                Text("FanVerse").font(.system(size: 38, weight: .heavy, design: .rounded))
                Text("Fangames, recomps, émulateurs et skins pour ton iPhone.")
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.white)
            .padding(20)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .fvPurple.opacity(0.35), radius: 14, y: 6)
    }

    func tile(_ title: String, _ value: String, _ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                IconTile(symbol: symbol, color: color, size: 36)
                Text(value).font(.title2.weight(.heavy)).foregroundColor(.primary)
                Text(title).font(.footnote.weight(.semibold)).foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .fvCard()
        }
        .buttonStyle(.plain)
    }

    var stats: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            tile("Fangames", "\(allGames.count)", "star.fill", .orange) {
                gameCategory = "Tous"; tab = .games
            }
            tile("Jouables sur iPhone", "\(iphoneGames.count)", "iphone", .green) {
                gameCategory = iphoneCat; tab = .games
            }
            tile("Recomps & ports", "\(allPorts.count)", "cpu.fill", .fvPurple) { tab = .ports }
            tile("Sites de skins", "\(allSkinSources.count)", "paintpalette.fill", .fvPink) { tab = .skins }
            tile("Émulateurs", "\(allEmulators.count)", "gamecontroller.fill", .fvBlue) { showEmulators = true }
            tile("Mes fichiers", "\(dl.files.count)", "arrow.down.circle.fill", .teal) { tab = .downloads }
        }
    }

    func featuredCard(_ g: Game) -> some View {
        let color = categoryColors[g.category] ?? .purple
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [color.opacity(0.55), color.opacity(0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                PreviewBanner(link: g.url, height: 84, gap: 0)
                LogoView(game: g, color: color)
                    .scaleEffect(0.75, anchor: .bottomLeading)
                    .padding(6)
            }
            Text(g.name).font(.subheadline.weight(.bold)).lineLimit(2)
                .multilineTextAlignment(.leading)
            FVTag(text: g.platform, color: color)
            Spacer(minLength: 0)
        }
        .frame(width: 170, height: 190, alignment: .topLeading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var featured: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "À jouer sur iPhone", subtitle: "ROM hacks (via Delta) et jeux navigateur")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featuredGames) { g in
                        Button { Router.shared.open(g.url, folder: g.name) } label: { featuredCard(g) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var fanFRGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Fangames Pokémon en français", subtitle: "\(tffrGames.count) jeux traduits par le Discord TFFR")
            VStack(alignment: .leading, spacing: 14) {
                StepRow(number: 1, text: "Ouvre le salon #téléchargements du Discord (bouton ci-dessous) et choisis ton jeu.")
                StepRow(number: 2, text: "Appui long sur le lien de téléchargement → Copier, puis reviens dans FanVerse : touche « Coller » sur la bannière et ça télécharge tout seul (MediaFire compris), avec la barre de progression.")
                StepRow(number: 3, text: "Touche le .zip dans l'app Fichiers (Sur mon iPhone → FanVerse) pour le décompresser.")
                StepRow(number: 4, text: "Dans RPGPlayer, importe le dossier du jeu. Si le post a un correctif « NaviaXP / RPGPlayer », remplace le fichier dans le dossier Data.")
                HStack(spacing: 10) {
                    Button { Router.shared.open(tffrDownloadsURL) } label: {
                        Label("Discord", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.subheadline.weight(.bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color(red: 0.35, green: 0.40, blue: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    if let u = URL(string: rpgPlayerURL) {
                        Link(destination: u) {
                            Label("RPGPlayer", systemImage: "play.rectangle.fill")
                                .font(.subheadline.weight(.bold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(fvGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .buttonStyle(.plain)
                Button { gameCategory = frCat; tab = .games } label: {
                    Label("Voir les jeux traduits", systemImage: "list.bullet")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }
            .fvCard()
        }
    }

    var installGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Installer un .ipa", subtitle: "Pour FanVerse lui-même et les recomps")
            VStack(alignment: .leading, spacing: 14) {
                StepRow(number: 1, text: "Télécharge le .ipa dans l'onglet Téléchargements (ou depuis la page Releases du projet).")
                StepRow(number: 2, text: "Touche « Ouvrir » sur le fichier puis choisis SideStore ou AltStore. Sinon installe-le avec SideStore ou AltStore (sur iPhone) ou Sideloadly (depuis un ordi). Ils signent l'app avec ton identifiant Apple.")
                StepRow(number: 3, text: "Avec un compte Apple gratuit, l'app doit être re-signée tous les 7 jours (SideStore/AltStore le font pour toi).")
                StepRow(number: 4, text: "Réglages → Général → VPN et gestion de l'appareil : fais confiance à ton profil développeur si iOS le demande.")
            }
            .fvCard()
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    stats
                    featured
                    fanFRGuide
                    installGuide
                    Text("FanVerse ne contient ni ne télécharge aucun jeu commercial : il faut toujours ta propre copie.")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showEmulators) { EmulatorsView() }
        }
    }
}
