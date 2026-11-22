# Kyky : à traiter (hors lot)

Une ligne par point : quoi, où, gravité. Le propriétaire choisit l'ordre.

- Légal : Stripe est cité dans la politique de confidentialité mais absent de la liste des sous-traitants de l'accord sur les données (`lib/features/legal/domain/legal_documents.dart`, section « Sous-traitants »). Gravité moyenne. Modifier un texte légal peut imposer une nouvelle acceptation par les utilisateurs : décision du propriétaire, puis avocat.
- Légal : les CGV disent « sans remboursement de la période en cours » mais l'appli permet à l'éditeur de rembourser (double paiement, erreur). Prévoir une phrase sur ces cas. Gravité faible.
- Bug déconnexion gestionnaire : correctifs déjà fusionnés (Poste de contrôle + profil au retour), tests verts. Pas encore essayé sur vrai téléphone ni ordinateur. Gravité haute tant que non confirmé.
- Outils : ni Supabase CLI ni Deno sur cette machine, donc pas de test des règles d'accès (RLS) ni des fonctions Stripe en local. Gravité moyenne.
- Identité visuelle : écrans accueil/match/profil/Poste de contrôle non audités à l'écran (pas de serveur) ; textes forcés w400 partout, cartes toutes identiques, emojis à revoir — moyenne

## Inventaire des écrans (démo FC Démo, 22/11/2026)

Vu en vrai = ouvert dans la démo (téléphone 390x844 et ordinateur 1440x900), avec capture. Les captures sont dans le dossier de travail de la session, pas dans le dépôt.

| Écran (route) | Tél | PC | Remarque |
|---|---|---|---|
| Accueil (`/accueil`, `/home`, `/`) | oui | oui | NOUVEAU (lot 2) : prochain match, présence, derniers résultats, Homme du match, raccourcis. Vu en vrai sur build local |
| Calendrier (`/matches`, `/pronos`, `/predictions`) | oui | oui | Carte « prochain match » mise en avant ; compte à rebours qui se met à jour seul |
| Détail match, onglet Info (`/matches/:id`) | oui | oui | Refait en blocs |
| Détail match, onglets Effectif, Compo, Prono | oui | non | Compo : terrain déjà lisible. Prono pas ouvert à fond |
| Statistiques (`/stats`, `/statistics`) Joueurs | oui | oui | Bandeau des meilleurs ajouté |
| Statistiques Équipe (`/stats` onglet Équipe) | oui | non | Graphiques déjà présents (anneau de bilan, buts, écart de score en barres, séries) : rien à refaire |
| Statistiques Prono (`/predictions/leaderboard`) | oui | oui | |
| Fiche joueur, classement (`/stats/joueur…`) | oui | oui | Seulement l'état « introuvable » (il faut un identifiant) |
| Profil (`/profile`) | oui | oui | Centré sur PC, texte en double retiré |
| Paramètres (`/more`, `/admin/settings`) | oui | oui | Plat mais lisible |
| Notifications (`/notifications`) | oui | oui | Onglet Paramètres non ouvert |
| Indisponibilité (`/unavailability`) | oui | oui | État vide seulement |
| Liste d'attente (`/waitlist`, `/admin/waitlist`) | oui | oui | |
| Effectif (`/effectif`, `/players`, `/admin/administration`) | oui | oui | FUSIONNÉ (lot 2) : un écran, onglets Annuaire / Joueurs / Inscriptions (admin) ; membre simple : annuaire seul |
| Armoire à badges (`/armoire`), Badges admin | oui | oui | |
| Bilan de saison (`/wrapped`) | oui | oui | État vide seulement |
| Réglages du club (liste des sections) | oui | oui | Redessiné : icône colorée, titre plus grand, une ligne d'explication par section. Contenu des sections non ouvert en démo |
| Maillots, Équipes & stades, Saison, Notification, Invités | oui | oui | |
| Ajouter un match passé (`/admin/history`) | oui | non | Redessiné (lot 3) : étapes numérotées, score en tableau d'affichage coloré, largeur limitée sur grand écran. Vu en téléphone sur build local ; PC non recapturé |
| Détail d'un match joué (fiche + terrain) | oui | non | Sur la démo, les 11 joueurs du match du 11/11 se chevauchent sur le terrain (positions de la démo en diagonale ?) : à vérifier si c'est la donnée ou le code |
| Textes légaux (`/legal/cgu`, `/legal/confidentialite`) | oui | oui | Contiennent « [Prénom NOM] » : à compléter avant ouverture (légal) |
| Connexion | oui | oui | |
| Composition admin, finaliser, vote, prono d'un match, historique d'un match, invités d'un match | non | non | Routes avec identifiant : non parcourues |
| Inscription, choix du club, confirmation e-mail, nouveau mot de passe, accepter les conditions | non | non | Parcours de compte : non parcourus |
| Abonnement (`/admin/abonnement`) | non | non | Paiement : interdit |
| Poste de contrôle (`/control`) | non | non | Interdit pour ce compte |
| Mode mois du calendrier | non | non | |

À traiter : redessiner « Ajouter un match passé », ouvrir les écrans « non » ci-dessus (ils demandent de créer des matchs dans FC Démo : composition admin, finaliser, vote, prono, historique, invités, mode mois), tester les états vide/erreur un par un. Corrigé (lot 3) : la barre du bas surligne Accueil sur Effectif, Réglages et Profil. Accueil PC : raccourcis sous le prochain match (plus de zone vide).

Non parcouru au lot 3 : aucune donnée créée dans FC Démo (le choix de date est une roue sur canvas, les identifiants de match ne sont pas lisibles dans l'adresse). Restent : vote, prono, finaliser, invités d'un match, mode mois, états vide/erreur/hors-ligne.
