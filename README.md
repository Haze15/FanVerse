# FanVerse
1. Crée un repo GitHub et envoie-y tout ce dossier.
2. Onglet Actions > Build IPA > Run workflow (ou un simple push).
3. Quand c'est vert, télécharge l'artefact "Fangames-ipa" (zip contenant Fangames.ipa).
4. Installe-le avec AltStore, SideStore ou Sideloadly (l'IPA n'est pas signé).
Pour ajouter des jeux : modifie Sources/Games.swift.

## Téléchargement
Ajoute `dl: "https://lien-direct/jeu.zip"` à un jeu dans Games.swift : le bouton Télécharger apparaît.
Les fichiers sont dans l'app Fichiers > Sur mon iPhone > Fangames, et partageables via "Ouvrir / Partager".
