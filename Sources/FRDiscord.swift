import Foundation

// Fangames Pokémon traduits en français par le Discord « Traduction 🇫🇷 Fangames Pokémon ».
// Les traducteurs demandent de NE PAS diffuser leurs liens de téléchargement hors du Discord :
// on renvoie donc vers le Discord (salon #téléchargements), jamais vers le fichier.

let tffrServerURL = "https://discord.com/channels/1349409253622022266"
let tffrDownloadsURL = "https://discord.com/channels/1349409253622022266/1480870776855990385"
let rpgPlayerURL = "https://apps.apple.com/app/id6754986970"

private func tffr(_ name: String, _ desc: String, thread: String? = nil) -> Game {
    Game(name: name, category: "Pokémon", platform: "RPG Maker XP",
         desc: desc + " Traduction FR sur le Discord TFFR ; sur iPhone : RPGPlayer.",
         url: thread.map { "\(tffrDownloadsURL)/threads/\($0)" } ?? tffrDownloadsURL,
         fr: true, logoDomain: "discord.com")
}

let tffrGames: [Game] = [
    tffr("Pokémon Z", "Kalos 300 ans avant X/Y, guerre de cour et Team Azoth. Terminé, orienté histoire.",
         thread: "1528987321397940394"),
    tffr("Pokémon Añil", "Grand classique espagnol, sprites animés, Pokémon jusqu'à la 9G. Terminé."),
    tffr("Pokémon Nova", "Version 2.0.1, orienté histoire. Terminé."),
    tffr("Pokémon Solar Eclipse", "Orienté histoire, Pokémon jusqu'à la 9G. Terminé."),
    tffr("Pokémon Africanvs – Définitive Edition", "Orienté histoire. Terminé."),
    tffr("Pokémon Gadir Deluxe", "Formes régionales, Pokémon jusqu'à la 8G. Terminé."),
    tffr("Pokémon Reminiscencia", "Sprites animés, Pokémon jusqu'à la 9G. Terminé."),
    tffr("Pokémon Cuerpo de Cristal", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Plastic Pyrite", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Bizarre", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Hollow Woods", "Formes régionales, orienté histoire. Terminé."),
    tffr("Pokémon Eternal Emerald", "Sprites animés, orienté histoire. Terminé."),
    tffr("Pokémon Giovanni Origins", "L'histoire de Giovanni. Terminé."),
    tffr("Pokémon Eon Guardians", "Orienté histoire. Terminé."),
    tffr("Pokémon Keishou", "Orienté combat. Terminé."),
    tffr("Pokémon Unchosen", "Orienté combat, Pokémon jusqu'à la 9G. Terminé."),
    tffr("Pokémon Hidden Place", "Sprites animés, formes régionales, jusqu'à la 8G."),
    tffr("Pokémon Consonancia", "Sprites animés, orienté combat, jusqu'à la 9G."),
    tffr("Pokémon Floral Tempus EX", "Formes régionales, orienté histoire."),
    tffr("Pokémon Echoes – Awakening II", "Démo, orienté histoire."),
    tffr("Pokémon Revival – Chapitre 3", "Démo, sprites animés, jusqu'à la 9G."),
]

let allGames: [Game] = baseGames + tffrGames
