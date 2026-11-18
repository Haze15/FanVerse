import SwiftUI

enum AppTab: Hashable { case home, games, ports, emulators, skins }

struct HomeView: View {
    @Binding var tab: AppTab
    @Binding var gameCategory: String

    var iphoneGames: [Game] { allGames.filter(\.onIPhone) }

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
        }
    }

    func featuredCard(_ g: Game) -> some View {
        let color = categoryColors[g.category] ?? .purple
        return VStack(alignment: .leading, spacing: 8) {
            LogoView(game: g, color: color)
            Text(g.name).font(.subheadline.weight(.bold)).lineLimit(2)
                .multilineTextAlignment(.leading)
            FVTag(text: g.platform, color: color)
            Spacer(minLength: 0)
        }
        .frame(width: 150, height: 150, alignment: .topLeading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var featured: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "À jouer sur iPhone", subtitle: "ROM hacks (via Delta) et jeux navigateur")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(iphoneGames.prefix(12)) { g in
                        if let u = URL(string: g.url) {
                            Link(destination: u) { featuredCard(g) }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    var installGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Installer un .ipa", subtitle: "Pour FanVerse lui-même et les recomps")
            VStack(alignment: .leading, spacing: 14) {
                StepRow(number: 1, text: "Récupère le fichier .ipa (page Releases du projet).")
                StepRow(number: 2, text: "Installe-le avec SideStore ou AltStore (sur iPhone) ou Sideloadly (depuis un ordi). Ils signent l'app avec ton identifiant Apple.")
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
                    installGuide
                    Text("FanVerse ne contient ni ne télécharge aucun jeu commercial : il faut toujours ta propre copie.")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}
