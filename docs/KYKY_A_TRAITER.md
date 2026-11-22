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
| Calendrier (`/matches`, `/home`, `/pronos`, `/predictions`) | oui | oui | Les 4 routes montrent le même calendrier : pas d'écran d'accueil séparé. Refait : carte « prochain match » mise en avant |
| Détail match, onglet Info (`/matches/:id`) | oui | oui | Refait en blocs |
| Détail match, onglets Effectif, Compo, Prono | oui | non | Compo : terrain déjà lisible. Prono pas ouvert à fond |
| Statistiques (`/stats`, `/statistics`) Joueurs | oui | oui | Bandeau des meilleurs ajouté |
| Statistiques Équipe, Prono (`/predictions/leaderboard`) | oui (Prono) | oui (Prono) | Équipe : non ouvert |
| Fiche joueur, classement (`/stats/joueur…`) | oui | oui | Seulement l'état « introuvable » (il faut un identifiant) |
| Profil (`/profile`) | oui | oui | Centré sur PC, texte en double retiré |
| Paramètres (`/more`, `/admin/settings`) | oui | oui | Plat mais lisible |
| Notifications (`/notifications`) | oui | oui | Onglet Paramètres non ouvert |
| Indisponibilité (`/unavailability`) | oui | oui | État vide seulement |
| Liste d'attente (`/waitlist`, `/admin/waitlist`) | oui | oui | |
| Effectif (`/effectif`, `/players`, `/admin/administration`) | oui | oui | 3 routes, 3 listes proches : à fusionner |
| Armoire à badges (`/armoire`), Badges admin | oui | oui | |
| Bilan de saison (`/wrapped`) | oui | oui | État vide seulement |
| Réglages du club, Maillots, Équipes & stades, Saison, Notification, Ajouter match passé, Invités | oui | oui | Sections repliées non toutes ouvertes |
| Textes légaux (`/legal/cgu`, `/legal/confidentialite`) | oui | oui | Contiennent « [Prénom NOM] » : à compléter avant ouverture (légal) |
| Connexion | oui | oui | |
| Composition admin, finaliser, vote, prono d'un match, historique d'un match, invités d'un match | non | non | Routes avec identifiant : non parcourues |
| Inscription, choix du club, confirmation e-mail, nouveau mot de passe, accepter les conditions | non | non | Parcours de compte : non parcourus |
| Abonnement (`/admin/abonnement`) | non | non | Paiement : interdit |
| Poste de contrôle (`/control`) | non | non | Interdit pour ce compte |
| Mode mois du calendrier | non | non | |

À traiter : fusionner les 3 listes d'effectif, donner un vrai accueil distinct du calendrier, ouvrir les écrans « non » ci-dessus.
