# Audit UX/UI écran par écran — synthèse (25 novembre 2026)

Remplace les conclusions de `docs/AUDIT_UX_COMPLET_20261125.md` (premier passage par comptages). Détail par fichier : `docs/audit_ecrans_20261125/` (6 rapports, 1 565 lignes).
Aucun code modifié. À valider avant toute correction.

## Méthode et limites

- **211 fichiers lus en entier** par 6 relecteurs automatiques en parallèle (sports_management 33, matches 28, match_live + bilan 24, admin + plateforme 31, badges + joueurs + stats + pronos 35, connexion + compte + composants partagés 60). Aucun fichier de ces listes lu en partie.
- **Jamais vu à l'écran.** Pas de base locale (Docker absent). Tout est jugé par le code. Texte agrandi, contraste réel, clavier et lecteur d'écran restent « à vérifier ».
- **Les compteurs sont ceux des relecteurs, non dédoublonnés** : 6 bloquants, 300 gênants, 498 détails, 45 à vérifier (849 lignes). Beaucoup de « gênants » sont probablement surévalués ou répétés d'un écran à l'autre : lire les motifs ci-dessous plutôt que le total.
- **J'ai vérifié moi-même dans le code 6 affirmations parmi les plus graves** (résultat plus bas). Le reste n'est pas revérifié.
- Composants appelés depuis d'autres dossiers (cartes de calendrier, en-tête de match, etc.) parfois non lus : leurs défauts ne sont pas tous couverts.

## Corrections de mon premier rapport

- J'avais écrit « squelettes de chargement dans 5 fichiers » : faux. `PfLoader`, `PfSkeleton` et le chargeur indéterminé **ne dessinent rien** (volontaire, d'après les commentaires du code : « sans loader visuel »). L'app n'a donc aucun indicateur de chargement visible.
- J'avais écrit « aucun problème bloquant » : faux. Voir ci-dessous.

## Points bloquants ou graves (6)

| # | Écran | Problème | Vérifié par moi |
|---|---|---|---|
| 1 | Ajout au calendrier (`calendar_entry_form_page`) | Le champ « Nom du stade » s'affiche mais **n'est jamais enregistré**. La saisie est perdue en silence. | **Oui** : le champ n'est jamais relu à l'enregistrement. |
| 2 | Plan d'effectif admin (`admin_squad_plan_page_state`) | Si le réseau coupe au chargement, l'écran affiche « Aucun match disponible, crée un match » au lieu de l'erreur. Pas de « Réessayer ». | **Oui** par lecture : l'erreur n'est affichée que dans une autre branche. |
| 3 | Console plateforme (`platform_control_page`) | Toutes les minutes, au retour d'onglet et au clic sur « Actualiser », la page entière est remplacée par un cercle (invisible, voir ci-dessus : écran vide). Défilement et fiche ouverte perdus. | **Oui** (réglage `skipLoadingOnRefresh: false`). Touche seulement la console de plateforme, pas les joueurs. |
| 4 | Pilotage du direct | Une seule relecture ratée (toutes les 30 s) peut remplacer l'écran de pilotage par une phrase, sans « Réessayer ». | **Non.** Dépend du comportement de la bibliothèque : à confirmer à l'écran. |
| 5 | Direct, score +/− | Pas de verrou anti double appui : un double appui peut ajouter 2 buts. | **Non.** |
| 6 | Bilan de saison | Avance seul, navigation au geste uniquement : inutilisable au clavier, au lecteur d'écran ou au contacteur. « Réduire les animations » ne coupe pas l'avance. | **Non.** Bloquant seulement pour ces usages. |

Autres affirmations que j'ai vérifiées :
- « Menu Test visible par tous les joueurs » : **en partie faux**. Le menu est filtré (`adminOnly`) ; les joueurs ne voient que les types non réservés aux admins. Lesquels : non vérifié.
- « Pronostic jamais saisi affiché 0–0 prêt à enregistrer » : le code reprend bien le score existant ; je n'ai pas confirmé la valeur par défaut. **Non vérifié.**

## Les 12 motifs qui reviennent le plus

1. **Aucun indicateur de chargement visible dans toute l'app** (choix assumé dans le code). Écrans vides pendant l'attente, y compris « Préparation de ton espace… » jusqu'à 15 s. Décision à prendre avec toi : garder ou non.
2. **Erreurs sans « Réessayer »** : calendrier, détail de match, historique, composition, disponibilité, vote homme du match, saison, effectif, notifications, parrainage, abonnement, factures, stats. Souvent seul le geste « tirer pour actualiser » existe.
3. **Erreurs avalées en silence** (bloc qui disparaît : en-tête de match, composition, événements, stats de fiche joueur, carte « Faits du match »). Le droit « coach/admin » en erreur est traité comme « non ».
4. **Formulaires qui perdent la saisie** : adresse écrasée quand on change type/adversaire/domicile ; dispositif tactique qui vide les titulaires ; feuille « Équipes et stades » fermée avant l'envoi ; maillots enregistrés par un bouton tout en bas ; aucun `PopScope` (confirmation de sortie) dans sports_management ni dans les formulaires de match.
5. **Actions sans retour ni anti double appui** : suppression/archivage/réactivation de joueur, « Finir la saison », réglages du direct, options de match admin, changement de mot de passe (aucun message de succès).
6. **Fenêtres fermables pendant l'envoi** (paiement, offre, factures, indisponibilité). Pour l'indisponibilité, le retour ferme aussi la page dessous.
7. **Actions lourdes sans confirmation** : émission de factures numérotées, « Traitée » sur un litige, rôle Admin donné d'un appui.
8. **Accessibilité** : composition, effectif, cases de badge, bilan et choix de type utilisables seulement au toucher (`GestureDetector`) ; sélection non annoncée ; résultats V/N/D portés par la couleur seule ; roues de sélection sans clavier ; zones à toucher de 18 à 34 px (cloches, +/−, boutons vidéo) ; contour des champs ~1,6:1 ; sous-onglets 36 px.
9. **Petits textes** : emblème de badge à 4–8 px (et lu deux fois par un lecteur d'écran), pastilles 10–11 px, spectateur du direct forcé à 100 % de texte.
10. **Débordements probables à texte agrandi** : `FittedBox` qui rétrécit jusqu'à l'illisible, grille figée à 3 colonnes, `Row` sans `Flexible`, hauteurs fixes, « Statistiques » tronqué dans la barre du bas à 130–160 %.
11. **Fenêtres de dialogue non défilables avec champ** (mot de passe oublié, e-mail, suppression de compte) : boutons masqués par le clavier sur petit téléphone. Feuille « Décerner » qui déborde.
12. **Pas de page d'erreur de navigation** : adresse inconnue = page anglaise par défaut ; lien de réinitialisation expiré (`otp_expired`) retombe en silence sur la connexion.

## Autres constats notables (non vérifiés)

- Liste « merged_matches_view » : sur ordinateur, molette et clavier ne comptent pas comme un défilement ; la liste est ramenée de force sur le match mis en avant pendant 5 s.
- Un match en cours ou terminé mais pas encore validé est rangé sous « À venir ».
- Coordonnées de joueurs : si le chargement échoue, tout le monde affiche « Pas de coordonnées » (faux).
- Téléphone et date de naissance visibles de tous les membres, saisis par un admin : vérifier que le membre concerné est informé.
- « Plus tard » sur le bandeau d'installation semble définitif.
- Choix d'une photo : le test de transparence parcourt tous les pixels de la photo pleine résolution (gel possible).
- Prix inconnu affiché « 0,00 € » dans la facturation, alors que la page promet de ne jamais remplacer une mesure manquante par zéro.
- Bouton « Modifier » du mot de passe : génère en fait un lien de réinitialisation.
- Minute > 90 affichée mais non prise en compte (éditeur de buts) ; limite d'effectif enregistrée à chaque chiffre tapé ; publication forcée au-delà de la limite.
- Partage du bilan : tout échec dit « L'image n'a pas pu être préparée », même si seul le navigateur ne sait pas partager ; pas de téléchargement de secours.

## Code mort repéré (à confirmer avant suppression)

- `pronos_hub_history_section.dart` (~400 lignes, `_CalendarSection` jamais instanciée).
- `match_live_running_page` L288-409 (branche « page défilante »).
- Branche « aperçu admin » de `season_wrapped_button`.
- `EmailVerificationPanel` (utilisé nulle part).

## Bons points relevés

Pronostic sans double envoi, confirmations de badge et de suppression de joueur bien faites, largeur de lecture limitée (760 px) sur le calendrier, hub pronos respecte « réduire les animations », dates en français, thème sombre unique donc pas de souci de contraste clair/sombre sur les couleurs en dur du direct, contraste du texte secondaire ~7:1, tous les boutons-icônes nommés.

## Plan de corrections proposé

Chaque lot = une branche courte, tests relancés. Recommandation : 1 à 4 d'abord.

| Lot | Contenu | Effort |
|---|---|---|
| 1 | Bloquants 1 à 3 (nom du stade, « Aucun match » sur erreur, console plateforme) + confirmer 4 et 5 | Petit |
| 2 | Composant commun d'erreur avec « Réessayer », appliqué aux ~15 écrans du motif 2 ; ne plus avaler les erreurs (motif 3) | Moyen |
| 3 | Formulaires : ne plus perdre la saisie (motif 4), anti double appui + retour d'action (5, 6) | Moyen |
| 4 | Décision indicateur de chargement (motif 1) : un petit repère visible, ou on garde le choix actuel | Petit/Moyen |
| 5 | Confirmations des actions lourdes (7) ; page d'erreur de navigation (12) | Petit |
| 6 | Accessibilité : zones à toucher, libellés, clavier sur composition/bilan (8) | Gros |
| 7 | Textes et débordements (9, 10, 11) | Moyen |

## Ce qui reste à faire

- **Toi** : valider les lots, trancher le motif 1 (indicateur de chargement), dire si le bilan doit être accessible au clavier.
- **Moi, après accord** : corriger lot par lot.
- **Besoin d'un environnement avec Docker** pour confirmer les points « à vérifier » en captures (360/768/1280 px, texte à 160 %).
