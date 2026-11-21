import Foundation

struct Game: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let platform: String      // ex: "PC", "ROM hack GBA", "Navigateur"
    let desc: String
    let url: String
    var dl: String? = nil     // lien DIRECT de téléchargement, optionnel
    var fr: Bool = false      // true = traduit / disponible en français
    var logoDomain: String? = nil  // domaine pour récupérer le logo (sinon déduit de url)
    var auto: AutoSource? = nil    // téléchargement automatique depuis la source officielle

    var logoURL: URL? {
        let host = logoDomain ?? URL(string: url)?.host
        guard let h = host, !h.contains("duckduckgo") else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(h)&sz=128")
    }

    /// Jouable directement sur iPhone : ROM hack (via Delta & co), navigateur ou version iOS.
    var onIPhone: Bool {
        platform.contains("ROM hack") || platform.contains("Navigateur") || platform.contains("iOS")
            || platform.contains("RPG Maker")
    }
}

// Une ligne = un jeu. Ajoute  dl: "https://lien-direct/jeu.zip"  pour activer Télécharger.
let baseGames: [Game] = [
    // Pokémon
    Game(name: "Pokémon Insurgence", category: "Pokémon", platform: "PC",
         desc: "Région Torren, formes Delta, Méga-évolutions et scénario original.",
         url: "https://www.pokemoninsurgence.com"),
    Game(name: "Pokémon Reborn", category: "Pokémon", platform: "PC",
         desc: "Reborn City, ambiance sombre et combats de dresseurs très difficiles.",
         url: "https://rebornevo.com"),
    Game(name: "Pokémon Rejuvenation", category: "Pokémon", platform: "PC",
         desc: "Très long, difficulté élevée, nouvelle région et scénario dense.",
         url: search("Pokémon Rejuvenation fangame")),
    Game(name: "Pokémon Infinite Fusion", category: "Pokémon", platform: "PC",
         desc: "Fusionne deux Pokémon en un seul, avec des milliers de sprites combinés.",
         url: search("Pokémon Infinite Fusion")),
    Game(name: "Pokémon Radical Red", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack de FireRed très difficile, avec des Pokémon de générations récentes. Demande ta propre ROM.",
         url: search("Pokémon Radical Red rom hack")),
    Game(name: "Pokémon Unbound", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack de FireRed avec la région Borrius et un gros scénario. Demande ta propre ROM.",
         url: search("Pokémon Unbound rom hack")),
    Game(name: "Pokémon Clover", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack GBA avec beaucoup de Pokémon inédits (fakemon). Demande ta propre ROM.",
         url: search("Pokémon Clover rom hack")),

    // Pokémon en français
    Game(name: "Pokémon Éclat Pourpre", category: "Pokémon", platform: "ROM hack",
         desc: "Hack entièrement en français : moto à la place du vélo, CS supprimables dès le 3e badge. Demande ta propre ROM.",
         url: "https://www.pokemontrash.com/rom-pokemon/pokemon-eclat-pourpre", fr: true),
    Game(name: "Pokémon Reborn (version FR)", category: "Pokémon", platform: "PC",
         desc: "Traduction française communautaire de Reborn : contenu en français jusqu'à la Ligue (bêta).",
         url: "https://rebornevo.com/forums/topic/71461-pok%C3%A9mon-reborn-en-fran%C3%A7ais-french-reborn-translation-version-beta-du-20-avril-2024",
         fr: true),
    Game(name: "Pokémon Donjon Mystère : Délusion", category: "Pokémon", platform: "ROM hack DS",
         desc: "Hack de Donjon Mystère en 4 langues dont le français, créé en trois semaines par une équipe de quatre personnes. Demande ta propre ROM.",
         url: "https://www.pokemontrash.com/club/vos-fangames-et-projets/(nds)(fr)(en)(de)(es)-pokemon-donjon-mystere-delusion-(publie)",
         fr: true),
    Game(name: "150 ROM hacks Pokémon en français", category: "Pokémon", platform: "Liste",
         desc: "Liste GBrewFR de ROM hacks Pokémon avec patchs de traduction française.",
         url: "https://www.gbrew.fr/news/news-150-rom-hacks-pokemon-en-francais-patchs-fr/", fr: true),

    // Sonic
    Game(name: "Sonic Robo Blast 2", category: "Sonic", platform: "PC",
         desc: "Sonic en 3D basé sur le moteur de Doom, avec énormément d'addons et de niveaux de la communauté.",
         url: "https://www.srb2.org"),
    Game(name: "Sonic Before the Sequel", category: "Sonic", platform: "PC",
         desc: "Jeu 2D dans le style Mega Drive, fait par des fans.",
         url: search("Sonic Before the Sequel fangame")),

    // Mario
    Game(name: "Super Mario Bros. X", category: "Mario", platform: "PC",
         desc: "Éditeur de niveaux Mario avec des milliers de niveaux créés par la communauté.",
         url: search("Super Mario Bros. X SMBX")),
    Game(name: "Mario Forever", category: "Mario", platform: "PC",
         desc: "Plateforme Mario dans le style de Super Mario Bros.",
         url: "https://www.buziol.com"),

    // Zelda
    Game(name: "Zelda Classic", category: "Zelda", platform: "PC",
         desc: "Moteur Zelda 2D avec des centaines de quêtes faites par les fans.",
         url: "https://zeldaclassic.com"),
    Game(name: "Solarus", category: "Zelda", platform: "PC / iOS",
         desc: "Moteur open source de jeux type Zelda, avec plusieurs jeux complets.",
         url: "https://www.solarus-games.org"),
    Game(name: "Zelda: Oracle of Secrets", category: "Zelda", platform: "ROM hack SNES",
         desc: "Hack de A Link to the Past avec nouvelle histoire et nouveaux donjons. Demande ta propre ROM.",
         url: search("Zelda Oracle of Secrets rom hack")),

    // Pokémon (suite)
    Game(name: "PokeMMO", category: "Pokémon", platform: "PC / Mobile",
         desc: "MMO Pokémon communautaire : échanges, combats en ligne et plusieurs régions. Demande ta propre ROM.",
         url: "https://pokemmo.com"),
    Game(name: "Pokémon Showdown", category: "Pokémon", platform: "Navigateur",
         desc: "Simulateur de combats Pokémon en ligne : crée tes équipes et affronte d'autres joueurs, sans rien installer.",
         url: "https://play.pokemonshowdown.com"),
    Game(name: "Pokémon Tectonic", category: "Pokémon", platform: "PC",
         desc: "Jeu fan basé sur Pokémon Essentials, très axé stratégie et difficulté.",
         url: search("Pokémon Tectonic fangame")),
    Game(name: "Pokémon Uranium", category: "Pokémon", platform: "PC",
         desc: "Région Tandor, 100+ Pokémon inédits. Projet arrêté : la disponibilité peut varier.",
         url: search("Pokémon Uranium fangame")),
    Game(name: "Pokémon Xenoverse", category: "Pokémon", platform: "PC",
         desc: "Fangame avec la région Xenoverse et un scénario original.",
         url: search("Pokémon Xenoverse fangame")),
    Game(name: "Pokémon Ash Gray", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack de FireRed qui suit l'histoire d'Ash dans l'anime. Demande ta propre ROM.",
         url: search("Pokémon Ash Gray rom hack")),
    Game(name: "Pokémon Light Platinum", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack de FireRed avec la région Newlink et un nouveau scénario. Demande ta propre ROM.",
         url: search("Pokémon Light Platinum rom hack")),
    Game(name: "Pokémon Blaze Black 2 / Volt White 2", category: "Pokémon", platform: "ROM hack DS",
         desc: "Hack de Noir 2 / Blanc 2 avec difficulté revue. Patch de traduction FR communautaire quasi complet (histoire, objets, attaques, noms). Demande ta propre ROM.",
         url: "https://www.pokecommunity.com/threads/%F0%9F%8E%89-rom-hack-nds-traduction-fr-de-pok%C3%A9mon-blaze-black-2-volt-white-2-redux-%F0%9F%8E%89.537852/",
         fr: true),

    // Zelda (suite)
    Game(name: "Zelda: Mystery of Solarus DX", category: "Zelda", platform: "PC / iOS",
         desc: "Aventure Zelda complète créée avec le moteur Solarus.",
         url: "https://www.solarus-games.org"),
    Game(name: "Zelda: A Link to the Past Randomizer", category: "Zelda", platform: "Navigateur",
         desc: "Version aléatoire de A Link to the Past : objets mélangés, chaque partie est différente. Demande ta propre ROM.",
         url: "https://alttpr.com"),
    Game(name: "Zelda: Ocarina of Time Randomizer", category: "Zelda", platform: "PC",
         desc: "Randomizer d'Ocarina of Time avec de nombreuses options. Demande ta propre ROM.",
         url: "https://ootrandomizer.com"),
    Game(name: "Zelda: Parallel Worlds", category: "Zelda", platform: "ROM hack SNES",
         desc: "Hack de A Link to the Past avec nouveaux donjons et monde alternatif. Demande ta propre ROM.",
         url: search("Zelda Parallel Worlds rom hack")),

    // Mario (suite)
    Game(name: "Mari0", category: "Mario", platform: "PC",
         desc: "Super Mario Bros. mélangé avec le moteur à portails de Portal.",
         url: "https://stabyourself.net/mari0/"),
    Game(name: "Super Mario 63", category: "Mario", platform: "Navigateur",
         desc: "Plateformer 2D inspiré de Super Mario 64, créé par un fan.",
         url: search("Super Mario 63 fangame")),
    Game(name: "Super Mario Bros. Crossover", category: "Mario", platform: "Navigateur",
         desc: "Joue les niveaux de Super Mario Bros. avec des personnages d'autres jeux.",
         url: search("Super Mario Bros. Crossover")),
    Game(name: "Super Mario War", category: "Mario", platform: "PC",
         desc: "Jeu de combat multijoueur 2D style Mario, avec cartes et mods communautaires.",
         url: search("Super Mario War smw")),

    // Smash / autres Nintendo
    Game(name: "Super Smash Flash 2", category: "Smash", platform: "PC / Navigateur",
         desc: "Jeu de combat façon Smash Bros. avec des personnages de nombreuses licences.",
         url: "https://www.supersmashflash.com"),
    Game(name: "Metroid: Another Metroid 2 Remake", category: "Metroid", platform: "PC",
         desc: "Remake fan de Metroid II. Retiré par Nintendo : la disponibilité est incertaine.",
         url: search("AM2R Another Metroid 2 Remake")),
    Game(name: "Kirby fangames", category: "Kirby", platform: "PC",
         desc: "Sélection de jeux Kirby faits par des fans.",
         url: search("Kirby fangame")),

    // Autres
    Game(name: "Undertale Yellow", category: "Undertale", platform: "PC",
         desc: "Préquelle fan d'Undertale avec un nouveau personnage principal et ses propres combats.",
         url: "https://undertaleyellow.com"),

    // ───────────── Nouveaux ajouts ─────────────

    // Pokémon
    Game(name: "PokéRogue", category: "Pokémon", platform: "Navigateur",
         desc: "Roguelite Pokémon gratuit : runs aléatoires, objets cumulables, biomes. Marche dans Safari (ajoute-le à l'écran d'accueil).",
         url: "https://pokerogue.net"),
    Game(name: "Pokémon Emerald Rogue", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Émeraude transformé en roguelite : chaque run est différente. Demande ta propre ROM.",
         url: search("Pokémon Emerald Rogue rom hack")),
    Game(name: "Pokémon Emerald Seaglass", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Émeraude modernisé avec beaucoup d'options de confort et les Pokémon récents. Demande ta propre ROM.",
         url: search("Pokémon Emerald Seaglass")),
    Game(name: "Pokémon Inclement Emerald", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Émeraude beaucoup plus difficile, avec mécaniques modernes. Demande ta propre ROM.",
         url: search("Pokémon Inclement Emerald")),
    Game(name: "Pokémon Elite Redux", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Émeraude orienté combat compétitif, avec talents multiples. Demande ta propre ROM.",
         url: search("Pokémon Elite Redux")),
    Game(name: "Pokémon Glazed", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack d'Émeraude avec la région Tunod et plusieurs régions à visiter. Demande ta propre ROM.",
         url: search("Pokémon Glazed rom hack")),
    Game(name: "Pokémon Gaia", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Hack de FireRed avec la région Orbtus et un scénario original. Demande ta propre ROM.",
         url: search("Pokémon Gaia rom hack")),
    Game(name: "Pokémon Vega", category: "Pokémon", platform: "ROM hack GBA",
         desc: "Région Tohoak, Pokémon d'origine et difficulté relevée. Demande ta propre ROM.",
         url: search("Pokémon Vega rom hack")),
    Game(name: "Pokémon Crystal Clear", category: "Pokémon", platform: "ROM hack GBC",
         desc: "Cristal en monde ouvert : choisis ton starter et l'ordre des badges. Demande ta propre ROM.",
         url: search("Pokémon Crystal Clear")),
    Game(name: "Pokémon Polished Crystal", category: "Pokémon", platform: "ROM hack GBC",
         desc: "Cristal amélioré : nouvelles zones, graphismes revus, Pokémon de toutes générations. Demande ta propre ROM.",
         url: "https://github.com/Rangi42/polishedcrystal",
         auto: .github(repo: "Rangi42/polishedcrystal", tag: nil, must: [], exts: [".bps", ".ips"])),
    Game(name: "Pokémon Prism", category: "Pokémon", platform: "ROM hack GBC",
         desc: "Grosse aventure sur base Cristal, région Naljo. Demande ta propre ROM.",
         url: search("Pokémon Prism rom hack")),
    Game(name: "Pokémon Renegade Platinum", category: "Pokémon", platform: "ROM hack DS",
         desc: "Platine équilibré par Drayano : plus d'espèces, difficulté revue. Demande ta propre ROM.",
         url: search("Pokémon Renegade Platinum Drayano")),
    Game(name: "Pokémon Sacred Gold / Storm Silver", category: "Pokémon", platform: "ROM hack DS",
         desc: "HeartGold/SoulSilver revus par Drayano, avec les 493 Pokémon obtenables. Demande ta propre ROM.",
         url: search("Pokémon Sacred Gold Storm Silver")),

    // Sonic
    Game(name: "Sonic 3 A.I.R.", category: "Sonic", platform: "PC / iOS (web)",
         desc: "Sonic 3 & Knuckles remasterisé en widescreen. Version iPhone en web app (bêta). Demande ton fichier de jeu.",
         url: "https://sonic3air.org"),
    Game(name: "Sonic Triple Trouble 16-Bit", category: "Sonic", platform: "PC",
         desc: "Remake 16-bit fan du jeu Game Gear, très soigné.",
         url: search("Sonic Triple Trouble 16-Bit")),
    Game(name: "Sonic Chrono Adventure", category: "Sonic", platform: "PC",
         desc: "Sonic façon Metroidvania avec voyage dans le temps.",
         url: search("Sonic Chrono Adventure")),
    Game(name: "Sonic Galactic", category: "Sonic", platform: "PC",
         desc: "Jeu 2D style Saturn imaginaire, nouveaux niveaux et personnages jouables.",
         url: search("Sonic Galactic fangame")),
    Game(name: "Sonic Utopia", category: "Sonic", platform: "PC",
         desc: "Démo 3D en monde ouvert axée sur la vitesse et la physique.",
         url: search("Sonic Utopia fangame")),
    Game(name: "Dr. Robotnik's Ring Racers", category: "Sonic", platform: "PC",
         desc: "Jeu de kart Sonic par l'équipe de SRB2Kart, très technique.",
         url: search("Dr. Robotnik's Ring Racers")),

    // Mario
    Game(name: "Super Mario 64 Coop Deluxe", category: "Mario", platform: "PC",
         desc: "Mario 64 en multijoueur en ligne avec mods. Demande ta propre ROM.",
         url: "https://github.com/coop-deluxe/sm64coopdx"),
    Game(name: "Super Mario Star Road", category: "Mario", platform: "ROM hack N64",
         desc: "Hack culte de Mario 64 avec 130 étoiles inédites. Jouable dans Delta (N64). Demande ta propre ROM.",
         url: search("Super Mario Star Road rom hack")),
    Game(name: "Super Mario 74", category: "Mario", platform: "ROM hack N64",
         desc: "Deux aventures complètes de Mario 64 (normale + Extreme Edition). Demande ta propre ROM.",
         url: search("Super Mario 74 rom hack")),
    Game(name: "SMW Central", category: "Mario", platform: "ROM hack SNES",
         desc: "La référence des hacks de Super Mario World, triés et notés. Demande ta propre ROM.",
         url: "https://www.smwcentral.net"),
    Game(name: "Mario Multiverse", category: "Mario", platform: "PC",
         desc: "Créateur de niveaux Mario multi-styles avec partage en ligne.",
         url: search("Mario Multiverse fangame")),
    Game(name: "Super Mario Bros. Remastered", category: "Mario", platform: "PC",
         desc: "Recréation de Super Mario Bros. avec éditeur de niveaux. Demande ta propre ROM NES.",
         url: search("Super Mario Bros. Remastered JHDev2006")),

    // Zelda
    Game(name: "Zelda: Return of the Hylian SE", category: "Zelda", platform: "PC",
         desc: "Le Zelda fan d'origine, refait avec le moteur Solarus.",
         url: "https://www.solarus-games.org"),
    Game(name: "Zelda: Time to Triumph", category: "Zelda", platform: "PC",
         desc: "Jeu complet style A Link to the Past, plusieurs donjons inédits.",
         url: search("Zelda Time to Triumph fangame")),

    // Metroid
    Game(name: "Super Metroid Redesign", category: "Metroid", platform: "ROM hack SNES",
         desc: "Super Metroid redessiné et bien plus dur. Demande ta propre ROM.",
         url: search("Super Metroid Redesign rom hack")),
    Game(name: "Hyper Metroid", category: "Metroid", platform: "ROM hack SNES",
         desc: "Hack de Super Metroid avec carte entièrement nouvelle. Demande ta propre ROM.",
         url: search("Hyper Metroid rom hack")),
    Game(name: "Metroid: Rogue Dawn", category: "Metroid", platform: "ROM hack NES",
         desc: "Préquelle sur base NES, graphismes très poussés. Demande ta propre ROM.",
         url: search("Metroid Rogue Dawn")),

    // Mega Man
    Game(name: "Mega Man Maker", category: "Mega Man", platform: "PC",
         desc: "Crée et joue des niveaux Mega Man en ligne.",
         url: "https://megamanmaker.com"),
    Game(name: "Mega Man Unlimited", category: "Mega Man", platform: "PC",
         desc: "Un « Mega Man 10 » fan dans le style NES, avec 8 nouveaux boss.",
         url: search("Mega Man Unlimited fangame")),
    Game(name: "Mega Man 2.5D", category: "Mega Man", platform: "PC",
         desc: "Mega Man en 2.5D avec multijoueur en ligne.",
         url: search("Mega Man 2.5D fangame")),

    // Smash
    Game(name: "Project+", category: "Smash", platform: "Mod Wii",
         desc: "Mod de Smash Bros. Brawl au gameplay plus rapide, façon Melee.",
         url: search("Project+ Smash Brawl mod")),

    // Undertale
    Game(name: "Deltatraveler", category: "Undertale", platform: "PC",
         desc: "Fangame qui croise Undertale et Deltarune.",
         url: search("Deltatraveler fangame")),

    // Autres
    Game(name: "Streets of Rage Remake", category: "Autres", platform: "PC",
         desc: "Remake fan des trois Streets of Rage en un seul jeu.",
         url: search("Streets of Rage Remake Bomber Games")),
]
