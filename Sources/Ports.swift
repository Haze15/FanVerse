import SwiftUI

/// Comment obtenir le port sur iPhone
enum PortMethod: String, CaseIterable {
    case padmint = "PadMint"
    case ipa = "IPA prête"
    case web = "Web app"
    case xcode = "À compiler"

    var symbol: String {
        switch self {
        case .padmint: return "hammer.fill"
        case .ipa: return "arrow.down.app.fill"
        case .web: return "safari.fill"
        case .xcode: return "chevron.left.forwardslash.chevron.right"
        }
    }
    var color: Color {
        switch self {
        case .padmint: return .fvPurple
        case .ipa: return .green
        case .web: return .fvBlue
        case .xcode: return .orange
        }
    }
}

/// Recomp / décompilation / port natif qui tourne sur iPhone
struct Port: Identifiable {
    let id = UUID()
    let name: String       // nom du port (ex : HarkinianPad)
    let game: String       // jeu d'origine
    let console: String    // N64, GameCube…
    let desc: String
    let url: String
    let method: PortMethod
    var needs: String = "Ta propre copie du jeu"

    var consoleColor: Color {
        switch console {
        case "N64": return .red
        case "GameCube": return .indigo
        case "Wii": return .cyan
        case "PS1", "PS2": return .blue
        case "Mega Drive": return .fvBlue
        case "Mobile": return .teal
        default: return .gray
        }
    }
    var consoleSymbol: String {
        switch console {
        case "N64", "GameCube", "Wii": return "gamecontroller.fill"
        case "PS1", "PS2": return "opticaldisc.fill"
        case "PC": return "desktopcomputer"
        default: return "cpu.fill"
        }
    }
}

let padmintURL = "https://github.com/chrissotraidis/padmint"

// Ports construits par PadMint (Chris « Kahris » Sotraidis).
// Les dépôts ne publient pas d'app : PadMint la compile (sur ton Mac ou sur le Mac gratuit de GitHub).
private func pad(_ name: String, _ game: String, _ console: String, _ desc: String, repo: String? = nil) -> Port {
    Port(name: name, game: game, console: console, desc: desc,
         url: repo.map { "https://github.com/chrissotraidis/\($0)" } ?? padmintURL,
         method: .padmint)
}

let allPorts: [Port] = [
    // ── Nintendo 64
    pad("HarkinianPad", "Zelda: Ocarina of Time", "N64",
        "Ship of Harkinian en app iOS native : Metal, 60 fps, widescreen, contrôles tactiles et manettes. iOS 15+.",
        repo: "harkinianpad"),
    pad("MaskPad", "Zelda: Majora's Mask", "N64",
        "2 Ship 2 Harkinian en app iOS native, contrôles tactiles personnalisables. iOS 15+.",
        repo: "maskpad"),
    pad("SpaghettiPad", "Mario Kart 64", "N64",
        "SpaghettiKart en app iOS : rendu Metal, manettes Bluetooth. Exige la ROM US 1.0 (.z64). iOS 15+.",
        repo: "spaghettipad"),
    pad("StarshipPad", "Star Fox 64", "N64", "Port natif de Star Fox 64."),
    pad("PaperPad", "Paper Mario", "N64", "Port natif de Paper Mario."),
    pad("BananaPad", "Donkey Kong 64", "N64", "Port natif de Donkey Kong 64."),
    pad("BarrelPad", "Diddy Kong Racing", "N64", "Port natif de Diddy Kong Racing."),
    pad("BearBirdPad", "Banjo-Kazooie", "N64", "Port natif de Banjo-Kazooie."),
    pad("BrawlerPad", "Super Smash Bros.", "N64", "Port natif du premier Smash Bros."),
    pad("SnapPad", "Pokémon Snap", "N64", "Port natif de Pokémon Snap."),
    pad("AnnePad", "Pokémon Stadium", "N64", "Port natif de Pokémon Stadium."),
    pad("F0X", "F-Zero X", "N64", "Port natif de F-Zero X."),
    pad("DarkPad", "Perfect Dark", "N64", "Port natif de Perfect Dark."),
    pad("GoldenPad", "GoldenEye 007", "N64", "Port natif de GoldenEye 007."),
    pad("SquirrelPad", "Conker's Bad Fur Day", "N64", "Port natif de Conker."),
    pad("DinoPad", "Dinosaur Planet (proto)", "N64", "Le prototype annulé de Rare, jouable en natif."),

    // ── GameCube / Wii
    pad("SunPad", "Super Mario Sunshine", "GameCube", "Port natif de Super Mario Sunshine."),
    pad("BlueWake", "Zelda: The Wind Waker", "GameCube", "Port natif de The Wind Waker."),
    pad("MeleePad", "Super Smash Bros. Melee", "GameCube", "Port natif de Melee."),
    pad("BellPad", "Animal Crossing", "GameCube", "Port natif d'Animal Crossing GameCube."),
    pad("BallPad", "Super Mario Strikers", "GameCube", "Port natif de Mario Strikers."),
    pad("GalaxyPad", "Super Mario Galaxy", "Wii", "Port natif de Super Mario Galaxy."),
    pad("KartPad", "Mario Kart Wii", "Wii", "Port natif de Mario Kart Wii."),

    // ── PlayStation
    pad("CTRPad", "Crash Team Racing", "PS1", "Port natif de Crash Team Racing."),
    pad("Ottsel", "Jak and Daxter", "PS2", "Port natif de Jak and Daxter: The Precursor Legacy."),

    // ── PC
    pad("HaloPad", "Halo: Combat Evolved", "PC", "Halo CE (ou Custom Edition) sur iPhone."),
    pad("NightPad", "007: Nightfire", "PC", "Port natif de 007: Nightfire."),
    pad("UTP", "Unreal Tournament", "PC", "Unreal Tournament sur iPhone."),
    pad("OpenRCT2 Touch", "RollerCoaster Tycoon 2", "PC", "OpenRCT2 avec contrôles tactiles."),
    pad("AgePad", "Age of Empires II: DE", "PC", "Age of Empires II sur iPad/iPhone."),
    pad("TribesPad", "Tribes", "PC", "Tribes 2, Starsiege: Tribes et Tribes: Vengeance."),

    // ── Autres ports iOS
    Port(name: "Silent Hill (décomp)", game: "Silent Hill", console: "PS1",
         desc: "Décompilation avec IPA non signée publiée à chaque mise à jour, et source AltStore/SideStore pour les mises à jour auto.",
         url: "https://github.com/SlickAmogus/silent-hill-decomp/releases/tag/realtime",
         method: .ipa),
    Port(name: "Sonic 3 A.I.R. iOS", game: "Sonic 3 & Knuckles", console: "Mega Drive",
         desc: "Version web (bêta) : ouvre dans Safari, Partager → Sur l'écran d'accueil. iOS 13+.",
         url: "https://projects.sappharad.com/s3air_ios/20260228_beta/",
         method: .web, needs: "Fichier Sonic_Knuckles_wSonic3.bin"),
    Port(name: "sm64ex-ios", game: "Super Mario 64", console: "N64",
         desc: "Port iOS/tvOS de la décompilation de Mario 64, contrôles tactiles. À compiler avec Xcode.",
         url: "https://github.com/ckosmic/sm64ex-ios",
         method: .xcode, needs: "Ta propre ROM"),
    Port(name: "Sonic 1 & 2 (2013) décomp", game: "Sonic 1 & Sonic 2", console: "Mobile",
         desc: "Décompilation du Retro Engine v4. Build iOS via Xcode.",
         url: "https://github.com/Rubberduckycooly/Sonic-1-2-2013-Decompilation",
         method: .xcode, needs: "Data.rsdk de ta version officielle"),
    Port(name: "Sonic CD (2011) décomp", game: "Sonic CD", console: "Mobile",
         desc: "Décompilation du Retro Engine v3. Build iOS via Xcode.",
         url: "https://github.com/Rubberduckycooly/Sonic-CD-11-Decompilation",
         method: .xcode, needs: "Data.rsdk de ta version officielle"),
]
