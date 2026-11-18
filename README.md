# FanVerse

App iPhone qui regroupe fangames, recomps / ports natifs, émulateurs et sites de skins (Delta, Manic EMU, Provenance).
Aucun jeu commercial n'est inclus : il faut toujours ta propre copie.

## Récupérer l'IPA
Chaque push lance **Actions → Build IPA** sur le Mac gratuit de GitHub.

- **Lien direct (branche main)** : https://github.com/Haze15/FanVerse/releases/download/latest/FanVerse.ipa
- **Source SideStore / AltStore** (mises à jour auto) : https://github.com/Haze15/FanVerse/releases/download/latest/altstore-source.json
- Les autres branches publient une pré-release `beta-<branche>`.
- L'IPA est aussi dans les « Artifacts » du run.

Installe-le avec SideStore, AltStore ou Sideloadly (l'IPA n'est pas signé).

## Modifier le contenu
| Fichier | Contenu |
| --- | --- |
| `Sources/Games.swift` | Fangames et ROM hacks |
| `Sources/Ports.swift` | Recomps / ports natifs iOS |
| `Sources/Library.swift` | Émulateurs et sites de skins |

Ajoute `dl: "https://lien-direct/jeu.zip"` à un jeu dans Games.swift : le bouton Installer apparaît.
Les fichiers sont dans l'app Fichiers > Sur mon iPhone > FanVerse.
