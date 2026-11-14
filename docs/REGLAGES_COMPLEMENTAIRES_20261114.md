# Réglages manquants — enquête et extension du 14 novembre 2026

## Sources vérifiées

- Petit Filet : base de travail `3aa5b9054d4032f0520644c80eec2afcc343fd8c` de `main`.
- AS Grinta : `bea7330600eb8c683d5dbf0faa4d2cd7f2b16574` de `origin/main`, code consulté en lecture seule.
- Base commerciale `jvxkhgdopslctpcjrhzw`, lecture du catalogue `private.club_rule_catalogue()` : **34 règles**, dont deux limites d’attente obsolètes cachées par l’écran ; **7 modules**. Aucune lecture de données personnelles requise pour ce constat.
- Registres précédents : `AUDIT_FONCTIONNALITES_DETAILLE.md`, `MATRICE_164_REGLAGES_CLUB_20261113.md`, `AUDIT_PARITE_AS_GRINTA_REGLAGES_20261113.md`. Leurs classifications ne prouvent pas une validation réelle et leurs descriptions de l’attente automatique sont périmées.
- Chemins comparés : `features/match_live`, `sports_management` (simulation, vidéo, compositions), catalogue SQL, RPC Live, règles d’envoi `send-push`, écran Réglages et synchronisation du club.

## Résultat de l’enquête

Les réglages généraux existent ; les sous-fonctions restent très souvent imposées. En particulier, le Live a des commandes séparées et des paramètres d’affichage qui n’avaient aucune option dans le catalogue. L’animation de composition et la simulation étaient également systématiques. Douze interrupteurs de notifications regroupaient plusieurs situations sans permettre de les distinguer.

La présente extension ajoute **32 réglages**, soit **66 clés de règles** au catalogue (dont les deux limites d’attente conservées pour compatibilité, toujours cachées). Elle ajoute les sections **Composition et vidéo** et **Direct : outils du coach**, et un accès au **catalogue et aux seuils des badges** depuis les récompenses. Les modules généraux sont conservés.

## Inventaire exact des options ajoutées

| Clé | Réglage | Défaut | Effet vérifiable |
|---|---|---|---|
| `live_substitutions` | Direct : remplacements | Activé | Autoriser les remplacements et les salves pendant le direct. Les événements déjà enregistrés restent conservés. |
| `live_formation_changes` | Direct : changer de dispositif | Activé | Autoriser le changement de dispositif et le repositionnement des joueurs pendant le direct. |
| `live_add_players` | Direct : ajouter des joueurs | Activé | Autoriser les ajouts tardifs à la feuille du direct. Ils entrent sur le banc. |
| `live_remove_players` | Direct : retirer du banc | Activé | Autoriser le retrait d’un joueur du banc pendant le direct. |
| `live_scorers` | Direct : saisir les buteurs | Activé | Autoriser l’attribution des buts aux joueurs. Désactiver ne supprime aucune attribution existante ; le score reste saisissable. |
| `live_assists` | Direct : saisir les passeurs | Activé | Proposer et enregistrer les passes décisives. Nécessite la saisie des buteurs ; les anciennes passes sont conservées. |
| `live_own_goals` | Direct : CSC adverses | Activé | Autoriser l’attribution d’un but à un contre-son-camp adverse. Le score reste saisissable sans attribution. |
| `live_event_deletion` | Direct : corriger par suppression | Activé | Autoriser la suppression d’un événement et la diminution du score. Les ajouts restent possibles. |
| `live_restart` | Direct : recommencer le match | Activé | Autoriser la commande de remise à zéro du direct, toujours soumise à confirmation et impossible après export. |
| `live_takeover` | Direct : reprendre la main | Activé | Autoriser un coach habilité à reprendre la main à un autre téléphone. Le pilote unique et les contrôles de rôle restent obligatoires. |
| `live_pause` | Direct : mettre le chrono en pause | Activé | Autoriser les pauses manuelles du chrono. La reprise et les commandes de mi-temps et de fin restent disponibles. |
| `live_show_playing_time` | Direct : temps de jeu affichés | Activé | Afficher les minutes de jeu près du prénom sur le terrain du coach. Le calcul et l’historique sont toujours conservés. |
| `live_show_bench_counts` | Direct : compteurs de passages | Activé | Afficher les repères de passages sur le banc et sur le terrain du coach. Aucun compteur enregistré n’est effacé. |
| `live_next_out` | Direct : suggérer les prochaines sorties | Activé | Colorer les prénoms des joueurs proposés à la prochaine rotation. Le coach garde le choix des remplacements. |
| `live_names_only` | Direct : prénoms sans portraits | Désactivé | Sur le tableau du coach, afficher les prénoms à la place des portraits sur le terrain et le banc. |
| `live_journal_expanded` | Direct : journal du coach déplié | Désactivé | Ouvrir par défaut le journal complet du coach. Il peut toujours le replier pendant le match. |
| `live_substitution_colors` | Direct : couleurs des salves | Activé | Colorer les salves du journal et les compteurs de passages. Les repères restent lisibles sans couleurs. |
| `composition_simulation` | Composition : aide à la simulation | Activé | Proposer à l’administrateur une composition simulée. La sélection et l’enregistrement manuels restent disponibles. |
| `composition_video` | Composition : animation vidéo | Activé | Proposer l’animation de présentation aux joueurs et aux administrateurs. La composition fixe reste visible. |
| `composition_video_autoplay` | Vidéo : lancement automatique | Activé | Lancer la vidéo à la première visite après publication. Si coupé, la vidéo reste consultable avec son bouton. |
| `composition_video_notification_replay` | Vidéo : rejouer depuis la notification | Activé | Relancer une vidéo déjà vue si la composition est ouverte depuis sa notification. Dépend du lancement automatique. |
| `notify_availability_j3` | Relance disponibilité à J-3 | Activé | Envoyer la relance à trois jours du match. Dépend aussi de l’interrupteur général des relances de disponibilité. |
| `notify_availability_j1` | Relance disponibilité à J-1 | Activé | Envoyer la relance la veille du match. Dépend aussi de l’interrupteur général des relances de disponibilité. |
| `notify_live_full_time` | Notification : fin du direct | Activé | Annoncer la fin du match. Dépend aussi de l’interrupteur coup d’envoi et fin du match. |
| `notify_live_goal_us` | Notification : buts marqués | Activé | Notifier les buts du club. Dépend aussi de l’interrupteur des buts en direct. |
| `notify_live_goal_them` | Notification : buts encaissés | Activé | Notifier les buts adverses. Dépend aussi de l’interrupteur des buts en direct. |
| `notify_match_cancelled` | Notification : annulation | Activé | Notifier les annulations de matchs. Dépend aussi de l’interrupteur match annulé ou déplacé. |
| `notify_match_rescheduled_date` | Notification : changement de date | Activé | Notifier les changements de date des matchs. Dépend aussi de l’interrupteur match annulé ou déplacé. |
| `notify_match_rescheduled_time` | Notification : changement d’horaire | Activé | Notifier les changements d’heure des matchs. Dépend aussi de l’interrupteur match annulé ou déplacé. |
| `notify_convocation_promoted` | Notification : promotion en convoqué | Activé | Notifier le passage de la liste d’attente aux convoqués. Dépend aussi de l’interrupteur convocation et liste d’attente. |
| `notify_convocation_demoted` | Notification : passage en attente | Activé | Notifier le passage des convoqués à la liste d’attente. Dépend aussi de l’interrupteur convocation et liste d’attente. |
| `notify_motm_winner` | Étoile : notification au gagnant | Activé | Envoyer le message personnel au gagnant. L’annonce générale dépend du réglage résultat de l’Étoile du match. |

## Contrats d’application

- **Actions Live** : garde sur les RPC publiques existantes, après le contrôle du pilote et sans modifier les permissions d’origine. Les changements de zones, ajouts/retraits et déplacements dans `p_entries` sont aussi contrôlés ; envoyer `p_substitution = null` ne contourne pas la règle. Le point d’entrée d’ajustement du score contrôle aussi le buteur et le retrait d’un but.
- **Historique** : aucun événement, score, passe, compteur, snapshot de composition ou vote n’est effacé en désactivant un réglage. Les attributions existantes peuvent être conservées lors d’une correction sans être recréées.
- **Affichage** : masquer les minutes, compteurs ou conseils ne change pas les calculs. Les préférences d’affichage du coach n’altèrent pas les données montrées aux spectateurs.
- **Composition** : la simulation est un calcul local sans écriture automatique. Sa désactivation coupe son bouton et son gestionnaire. L’animation est contrôlée à son point d’entrée partagé admin/joueur, en plus des contrôles de lancement automatique. Les formations fixes restent visibles.
- **Notifications** : un enfant désactivé coupe son type seulement. Un parent désactivé coupe tous ses enfants même si ceux-ci sont activés. La liste des types coupés est dédupliquée avant sa lecture par `send-push`. Les notifications manuelles restent régies par le contrat existant.
- **Dépendances** : passeurs et CSC dépendent des buteurs ; lancement automatique dépend de la vidéo ; rejeu depuis notification dépend du lancement automatique. Les sous-valeurs sont conservées et les contrôles grisés si le parent ou le module est coupé.
- **Cloisonnement** : les nouvelles valeurs utilisent les mêmes RPC admin, bornes et table privée à RLS que les règles existantes. Les helpers internes sont inaccessibles à `authenticated` et `anon`.
- **Attente** : aucun +1 automatique n’est réintroduit. Les anciennes clés de limite restent cachées.

## Points de l’ancienne matrice qui ne sont pas des interrupteurs à ajouter aveuglément

| Famille | Décision et motif |
|---|---|
| Identité, couleurs, maillots et quota de convocations | Contrôles déjà présents ; pas de deuxième réglage concurrent. Les travaux récents sur les portraits restent intacts. |
| Barèmes, cotes, délais de pronostics, vote Étoile, correction, musique du bilan | Déjà dans le catalogue lu en base ; conservés. |
| Seuils, images, couleurs et noms des badges | Éditeur dédié existant, désormais lié depuis Réglages. |
| Invitation et validation des membres, suspension, permissions et données personnelles | Flux de sécurité et d’intégrité ; ils ne deviennent pas désactivables. |
| Formation initiale par club et catalogue de formations autorisées | Absents comme réglages complets. Ils demandent un contrat commun brouillon/Live/serveur et un catalogue stable, pas un interrupteur local. Non livrés ici. |
| Saison personnalisée, fuseau international, langue et devise | Le produit fonctionne encore selon ses règles françaises. Non livrés ici : changements transversaux de calculs, rappels et historiques. |
| Connexion Facebook | Dépend de la configuration Auth de la plateforme, pas d’un simple choix de club. Non rendue paramétrable ici. |
| Clips individuels des joueurs | Fonction souhaitée, distincte de la vidéo existante et non livrée ; ne pas afficher de faux réglage. |
| Prix, abonnement et quota de stockage | Contrat de la plateforme ; pas de modification financière par le club. |

Cette liste ne prétend pas transformer les 164 unités fonctionnelles du registre historique en 164 réglages : plusieurs sont des opérations métier ou des invariants obligatoires. Les manques transversaux ci-dessus restent explicitement identifiés.

## Validation et limites

Tests ajoutés :

- `club_feature_extension.test.sql` : sauvegarde/relecture des 32 valeurs, bornes, refus joueur, indépendance A/B, retour au défaut et 11 sous-types de notifications (seuls, parent coupé, réactivation, sans doublon).
- `live_feature_rules.test.sql` : appels directs du vrai pilote refusés pour 11 réglages d’action, révision et historique inchangés, réactivation réelle d’une composition, score collectif toujours utilisable sans buteurs, absence de contournement par l’API du score.
- Widgets : options visibles et sauvegardées, dépendance buteur/passeur sans perte de valeur, commandes du pilote sur écran de 390 px, affichage terrain/banc, reprise de main, vidéo coupée, aperçu manuel et notification déjà vue.
- Suite commerciale existante : tests de rôles, de deux clubs, d’idempotence du score, de révision de composition, de remplacements et de notifications conservés. Le test du nombre de règles est mis à jour de 34 à 66.

**État à la création : code implémenté et formaté ; tests CI en attente. Validation Flutter locale indisponible (contrôle automatique d’accès réseau). Aucun déploiement ni migration commerciale exécuté.** Le statut final doit être complété après lecture des résultats sur le SHA exact.

La migration additive est `20261119000000_comprehensive_club_settings.sql` : créée avec le CLI, identifiant neuf situé après les migrations planifiées du dépôt jusqu’au 18/11, aucune migration historique éditée. Elle doit être installée avant de publier le client pour que les nouvelles options soient proposées par le serveur. Le verrou de production n’est pas modifié.
