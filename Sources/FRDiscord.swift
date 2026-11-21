import Foundation

// Fangames Pokémon traduits en français par le Discord « Traduction 🇫🇷 Fangames Pokémon ».
// Les traducteurs demandent de NE PAS diffuser leurs liens de téléchargement hors du Discord :
// on renvoie donc vers le Discord (salon #téléchargements), jamais vers le fichier.

let tffrServerURL = "https://discord.com/channels/1349409253622022266"
let tffrDownloadsURL = "https://discord.com/channels/1349409253622022266/1480870776855990385"
let rpgPlayerURL = "https://apps.apple.com/app/id6754986970"

private func tffr(_ name: String, _ desc: String, thread: String? = nil, official: String? = nil) -> Game {
    Game(name: name, category: "Pokémon", platform: "RPG Maker XP",
         desc: desc + (official != nil
            ? " « Télécharger » prend la version originale sur la page officielle ; la traduction FR est sur le Discord TFFR."
            : " Traduction FR sur le Discord TFFR ; sur iPhone : RPGPlayer."),
         url: thread.map { "\(tffrDownloadsURL)/threads/\($0)" } ?? tffrDownloadsURL,
         fr: true, logoDomain: "discord.com",
         auto: official.map { AutoSource.page($0) })
}

/// Fangames RPG Maker avec page officielle : téléchargement automatique en un tap.
let officialFangames: [Game] = [
    Game(name: "Pokémon Plasma", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Fangame en français, anglais et espagnol (Pokémon Essentials 21.1). Jouable avec RPGPlayer.",
         url: "https://www.pokecommunity.com/threads/pok%C3%A9mon-plasma-ver-0-1a-en-fr.531805",
         fr: true, auto: .page("https://www.pokecommunity.com/threads/pok%C3%A9mon-plasma-ver-0-1a-en-fr.531805")),
    Game(name: "Pokémon Underground", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Région polluée, nouveau type Plastique et Pokémon génétiquement modifiés. En anglais.",
         url: "https://www.pokecommunity.com/threads/pok%C3%A9mon-underground.457896/",
         auto: .direct("https://www.mediafire.com/file/dykag0b0sernafb/Pok%C3%A9mon_Underground.zip/file")),
    Game(name: "Pokémon Blooming Beast", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Enquête mystère en chapitres, avec Fakémon. En anglais.",
         url: "https://krlw890.itch.io/blooming-beast",
         auto: .page("https://krlw890.itch.io/blooming-beast")),
    Game(name: "Pokémon Zero", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Remake amélioré de Rouge Feu/Vert Feuille, Pokémon jusqu'à la 9G et Méga-Évolutions. En anglais.",
         url: "https://www.pokecommunity.com/goto/post?id=9876955",
         auto: .page("https://www.pokecommunity.com/goto/post?id=9876955")),
    Game(name: "Pokémon Reborn", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Le classique sombre et très difficile, avec effets de terrain et 807 Pokémon. En anglais.",
         url: "https://www.rebornevo.com/pr/", auto: .page("https://www.rebornevo.com/pr/")),
    Game(name: "Pokémon Rejuvenation", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Suite spirituelle de Reborn : 15 badges sur 18, Pokémon Obscurs. En anglais.",
         url: "https://www.rebornevo.com/rejuvdown/", auto: .page("https://www.rebornevo.com/rejuvdown/")),
    Game(name: "Pokémon Infinite Fusion", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Fusionne n'importe quels deux Pokémon (175 000+ combinaisons). Fichier très lourd. En anglais.",
         url: "https://pokecommunity.com/goto/post?id=8808638", auto: .page("https://pokecommunity.com/goto/post?id=8808638")),
    Game(name: "Pokémon Kanto Reloaded", category: "Pokémon", platform: "RPG Maker XP",
         desc: "Kanto refait avec Pokémon suiveurs, rencontres aléatoires et modes de jeu. En anglais.",
         url: "https://eeveeexpo.com/threads/6100",
         auto: .page("https://eeveeexpo.com/threads/6100")),
]

let tffrGames: [Game] = [
    tffr("Pokémon Z", "Kalos 300 ans avant X/Y, guerre de cour et Team Azoth. Terminé, orienté histoire.",
         thread: "1528987321397940394", official: "https://lostiefangames.blogspot.com/p/pokemon-z.html"),
    tffr("Pokémon Añil", "Grand classique espagnol, sprites animés, Pokémon jusqu'à la 9G. Terminé."),
    tffr("Pokémon Nova", "Monde ouvert dans l'Ultra-Mégalopole, par Phion Games. Terminé.",
         official: "https://phiongames.blogspot.com/2026/06/v1.html"),
    tffr("Pokémon Solar Eclipse", "Orienté histoire, Pokémon jusqu'à la 9G. Terminé.",
         official: "https://www.eeveeexpo.com/goto/post?id=90778"),
    tffr("Pokémon Africanvs – Définitive Edition", "Orienté histoire. Terminé."),
    tffr("Pokémon Gadir Deluxe", "Formes régionales, Pokémon jusqu'à la 8G. Terminé."),
    tffr("Pokémon Reminiscencia", "Roguelite sur plusieurs îles, 1025 Pokémon, sprites animés. Terminé.",
         official: "https://phiongames.blogspot.com/2023/10/descargar-pokemon-reminiscencia.html"),
    tffr("Pokémon Cuerpo de Cristal", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Plastic Pyrite", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Bizarre", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Hollow Woods", "Formes régionales, orienté histoire.",
         official: "https://eeveeexpo.com/goto/post?id=71788"),
    tffr("Pokémon Eternal Emerald", "Sprites animés, orienté histoire. Terminé."),
    tffr("Pokémon Giovanni Origins", "L'histoire de Giovanni, 20 ans avant Rouge et Bleu. Terminé.",
         official: "https://www.pokecommunity.com/threads/pok%C3%A9mon-giovanni-origins-full-release-play-johto-now.496592/"),
    tffr("Pokémon Eon Guardians", "Orienté histoire. Terminé."),
    tffr("Pokémon Keishou", "Île de Kyujitsu, 840+ Pokémon, orienté combat. Terminé.",
         official: "https://www.eeveeexpo.com/goto/post?id=69001"),
    tffr("Pokémon Unchosen", "RPG tactique façon Dofus, créé par un dev français (RPG Maker MV).",
         official: "https://aldrine.itch.io/pokemon-unchosen"),
    tffr("Pokémon Hidden Place", "Sprites animés, formes régionales, jusqu'à la 8G."),
    tffr("Pokémon Consonancia", "Sprites animés, orienté combat, jusqu'à la 9G."),
    tffr("Pokémon Floral Tempus EX", "12 badges + Conseil 4, formes régionales.",
         official: "https://www.pokecommunity.com/threads/pok%C3%A9mon-floral-tempus-ex-1-9-4-released-12-gym-badges-elite-4-champion.409175/"),
    tffr("Pokémon Echoes – Awakening II", "Démo, orienté histoire."),
    tffr("Pokémon Revival – Chapitre 3", "Démo, sprites animés, jusqu'à la 9G."),
]

let allGames: [Game] = baseGames + officialFangames + tffrGames
