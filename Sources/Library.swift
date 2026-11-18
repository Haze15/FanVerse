import SwiftUI

// MARK: - Émulateurs

struct Emulator: Identifiable {
    let id = UUID()
    let name: String
    let systems: [String]
    let desc: String
    let url: String
    let symbol: String
    let color: Color
    var appStore: Bool = true
    var jit: Bool = false
}

let allEmulators: [Emulator] = [
    Emulator(name: "Delta", systems: ["NES", "SNES", "N64", "GB/GBC", "GBA", "DS", "Mega Drive"],
             desc: "L'émulateur tout-en-un le plus simple. Skins personnalisables (.deltaskin), parfait pour les ROM hacks Pokémon.",
             url: "https://faq.deltaemulator.com", symbol: "triangle.fill", color: .fvPurple),
    Emulator(name: "Manic EMU", systems: ["Multi", "3DS", "PSP", "PS1", "DOS"],
             desc: "Tout-en-un avec une belle interface. Ses skins sont compatibles avec le format Delta.",
             url: "https://manicemu.site", symbol: "sparkles", color: .pink),
    Emulator(name: "PPSSPP", systems: ["PSP"],
             desc: "L'émulateur PSP de référence.",
             url: "https://www.ppsspp.org", symbol: "gamecontroller.fill", color: .fvBlue),
    Emulator(name: "RetroArch", systems: ["Multi"],
             desc: "Énormément de consoles via des « cores ». Plus technique à régler.",
             url: "https://www.retroarch.com", symbol: "square.stack.3d.up.fill", color: .gray),
    Emulator(name: "Provenance", systems: ["Multi", "PS1", "Sega", "Atari"],
             desc: "Multi-consoles, avec un catalogue de skins communautaires.",
             url: "https://provenance-emu.com", symbol: "circle.hexagongrid.fill", color: .orange),
    Emulator(name: "Gamma", systems: ["PS1"],
             desc: "Émulateur PlayStation 1 simple, avec skins.",
             url: search("Gamma PS1 emulator iOS App Store"), symbol: "opticaldisc.fill", color: .teal),
    Emulator(name: "Folium", systems: ["3DS", "GBA", "PS1"],
             desc: "Émulateur payant centré sur la 3DS.",
             url: search("Folium emulator iOS App Store"), symbol: "leaf.fill", color: .green),
    Emulator(name: "DolphiniOS", systems: ["GameCube", "Wii"],
             desc: "Dolphin pour iPhone/iPad. A besoin du JIT (via SideStore + StikDebug).",
             url: search("DolphiniOS"), symbol: "water.waves", color: .cyan, appStore: false, jit: true),
    Emulator(name: "MeloNX", systems: ["Switch"],
             desc: "Émulateur Switch sur iOS. Demande le JIT et un appareil récent.",
             url: search("MeloNX iOS"), symbol: "rectangle.split.2x1.fill", color: .red, appStore: false, jit: true),
]

// MARK: - Skins

struct SkinSource: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let url: String
    let group: String
    var symbol: String = "paintpalette.fill"
}

let skinGroups = ["Delta", "Manic EMU", "Provenance", "Créer ses skins"]

let allSkinSources: [SkinSource] = [
    // Delta — sites recommandés par la FAQ officielle de Delta
    SkinSource(name: "Delta Styles", desc: "Grand catalogue de skins, filtrables par console.",
               url: "https://deltastyles.com", group: "Delta"),
    SkinSource(name: "Delta Skins", desc: "Collection communautaire de skins open source.",
               url: "https://delta-skins.github.io", group: "Delta"),
    SkinSource(name: "Litritt Designs", desc: "Skins épurés et très propres, GBA/DS/GBC…",
               url: "https://litritt.gitbook.io/designs/", group: "Delta"),
    SkinSource(name: "Skins4Delta", desc: "Gros choix de skins Game Boy Advance.",
               url: "https://skins4delta.com/pages/gba", group: "Delta"),
    SkinSource(name: "r/Delta_Emulator", desc: "Les créateurs y partagent leurs nouveautés.",
               url: "https://www.reddit.com/r/Delta_Emulator/", group: "Delta", symbol: "bubble.left.and.bubble.right.fill"),
    SkinSource(name: "Skins sur Gumroad", desc: "Packs de créateurs (gratuits ou payants), ex. skins façon vraie Game Boy.",
               url: search("delta skin gumroad"), group: "Delta", symbol: "bag.fill"),

    // Manic EMU
    SkinSource(name: "Skins Delta dans Manic", desc: "Manic EMU lit le format .deltaskin : tous les sites Delta marchent aussi.",
               url: "https://manicemu.pages.dev/Homemade-Skin-Guide-EN/", group: "Manic EMU"),

    // Provenance
    SkinSource(name: "Catalogue Provenance", desc: "Skins communautaires officiels de Provenance.",
               url: "https://github.com/Provenance-Emu/skins", group: "Provenance"),

    // Création
    SkinSource(name: "Modèles officiels Delta", desc: "Télécharge les skins par défaut pour créer les tiens.",
               url: "https://noah978.gitbook.io/delta-docs/skins", group: "Créer ses skins", symbol: "pencil.and.ruler.fill"),
    SkinSource(name: "Guide skins Manic EMU", desc: "Animations d'appui, mise à l'échelle libre…",
               url: "https://manicemu.pages.dev/Homemade-Skin-Guide-EN/", group: "Créer ses skins", symbol: "pencil.and.ruler.fill"),
]
