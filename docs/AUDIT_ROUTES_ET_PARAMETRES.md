# Audit des routes, réglages et commandes visibles — Mission 01

Mis à jour le 12 novembre 2026. **Inspection statique du code** du dépôt commercial `main`; aucune route n'a été ouverte en session réelle. Annexe de `AUDIT_FONCTIONNALITES_DETAILLE.md`. Le fichier `lib/app/router/app_router.dart` est la source des chemins; les écrans internes peuvent utiliser des dialogues ou des `Navigator.push` sans route nommée. `Membre actif` et `Admin habilité` désignent le **rôle attendu pour le parcours**, pas une certification des contrôles effectifs côté serveur.

## 1. Matrice de navigation

**Couverture : 41 entrées de routes ou groupes de redirections**, chaque ligne devant être vérifiée aussi en ouverture URL directe, appareil installé, déconnexion, compte pending/suspendu, autre club et module désactivé.

| Route | Page / fonction | Acteur attendu | Paramètre / remarque | ID audit | Test critique |
|---|---|---|---|---|---|
| `/ ; /home ; /accueil` | redirection | Tous | Renvoie vers /matches | R01,A06 | vérifier sans session et après reprise |
| `/matches` | calendrier + pronostics | Membre actif | ?match=<id> sélectionne une carte | D05,H01 | navigation focus, contenu sans match, liens notification |
| `/matches/:matchId` | fiche match | Membre actif | matchId par URL | D13,G10 | match inconnu ou autre club, contenus avant publication |
| `/matches/history/:matchId` | détail historique | Membre actif | matchId historique | D10,I07 | match historique d'un autre club, saisons anciennes |
| `/matches/:matchId/lineup` | composition publiée | Membre actif | matchId | F06,F08 | publication, cache et vidéos absentes |
| `/matches/:matchId/vote` | vote postmatch | Membre actif | matchId | G11,G12 | vote anonyme, fermeture, module éteint |
| `/matches/:matchId/finalize` | compte rendu | Admin/coach habilité (à confirmer) | matchId | G08,G09 | contrôle serveur sur accès direct |
| `/matches/:matchId/prediction` | pronostic match | Membre actif | matchId | H01,H03 | fermeture serveur, module éteint |
| `/matches/:matchId/composition` | éditeur composition | Admin habilité | ?step=... | F01,F06 | accès direct, verrou et exceptions |
| `/matches/:matchId/guests` | invités du match | Admin habilité | matchId | C07,E13 | accès direct, quotas et identité |
| `/admin` | accueil administration | Admin habilité | route différée | M01-M04 | route directe sous aperçu joueur |
| `/admin/administration` | gestion utilisateurs | Admin habilité | route différée | M01,M02 | statuts en attente, RLS |
| `/admin/matches` | gestion calendrier | Admin habilité | route commune MatchesPage | D01-D09 | actions cachées + API serveur |
| `/admin/composition` | compositions | Admin habilité | AdminSquadPlanPage | F01,F06 | droits d'écriture et gel |
| `/admin/guests` | catalogue invités | Admin habilité | route différée | C07 | réutiliser/archiver sans perte |
| `/admin/waitlist` | liste d'attente éditable | Admin habilité | editable par défaut | E07-E11 | droits d'édition, 3 modes |
| `/waitlist` | liste d'attente lecture seule | Membre actif | editable:false | E07 | aucun accès écriture malgré URL |
| `/admin/badges` | administration badges | Admin habilité | route différée | J04,J06 | édition limitée au club |
| `/admin/notification` | notification libre | Admin habilité | route différée | L08 | ciblage club, consentement |
| `/admin/club` | réglages du club | Admin habilité | ClubSettingsPage | B01-B09 | identité, valeurs bornées, flags |
| `/more` | paramètres personnels/admin | Membre actif | raccourcis conditionnés rôle et module | A12,C12 | aperçu joueur, déconnexion et raccourcis |
| `/players` | effectif saison | Admin ou membre selon contrôle UI (à confirmer) | PlayersRegistryPage | C03,C04 | écriture réservée admin même via API |
| `/profile` | profil | Membre actif | ProfilePage | A12-A15 | compte modifié, export et suppression |
| `/armoire` | armoire badges | Membre actif | ArmoirePage | J05 | désactivation module, badges privés |
| `/notifications` | historique et préférences | Membre actif | ?onglet=parametres | L09,L10 | onglet direct et opt-out |
| `/unavailability` | mes indisponibilités | Membre actif | UnavailabilityPage | E03,E04 | plage de dates et motif privé |
| `/stats` | tableau statistiques | Membre actif | ?section=players ou rankings | I01,I05 | module stats off |
| `/stats/joueur` | fiche joueur | Membre actif | joueur depuis URL | I06 | clé arbitraire autre club |
| `/stats/joueur/classement` | classement détaillé | Membre actif | ?stat=...&periode=... | I05 | paramètres invalides et vide |
| `/pronos` | redirection héritée | Tous avec garde auth | ?category=matches/général | H06 | anciennes notifications et favoris |
| `/wrapped` | bilan saison | Membre/admin aperçu | ?apercu=1 | K01-K04 | hors saison, accès direct |
| `/predictions` | redirection héritée | Tous avec garde auth | → /matches | H01 | ancien lien |
| `/predictions/leaderboard` | redirection héritée | Tous avec garde auth | → /stats?section=rankings | H06 | ancien lien |
| `/statistics` | redirection héritée | Tous avec garde auth | → /stats?section=players | I01 | ancien lien |
| `/auth/loading` | chargement d'authentification | Session en cours | AuthLoadingPage | A06 | session expirée |
| `/auth/sign-in` | connexion | Public | AuthSignInPage | A06 | identifiants et erreurs sans fuite |
| `/auth/register` | inscription ou création club | Public | ?code=<invitation> | A01,A02 | invitation périmée |
| `/auth/choose-club` | choix créer/rejoindre | Public | ChooseClubPage | A01,A02 | entrée sans session |
| `/auth/confirm-email` | validation adresse e-mail | Public/avec jeton | ?token=<secret> | A08 | jeton absent, périmé, rejoué |
| `/legal/:slug` | CGU, mentions, confidentialité | Public | slug | A11,N11 | textes à compléter |
| `/auth/new-password` | mot de passe initial à changer | Utilisateur authentifié concerné | ForcedPasswordChangePage | A10 | refus de contourner l'étape |

## 2. Commandes visibles constatées dans le code

| Écran | Commandes à tester une par une | Source |
|---|---|---|
| Connexion | identifiant, mot de passe, Facebook (si fournisseur configuré), mot de passe oublié, inscription, messages d'erreur | `lib/features/auth/presentation/auth_sign_in_page.dart` |
| Inscription | bascule créer/rejoindre, code d'invitation, nom et nom court du club, nom/prénom, email facultatif, mot de passe/confirmation, consentements/âge, soumission | `lib/features/auth/presentation/auth_register_page.dart` |
| Paramètres | ouvrir profil, indisponibilité, liste d'attente lecture/admin, interrupteur aperçu joueur, bibliothèque équipes/stades, réglages du club, administration, déconnexion | `lib/features/more/presentation/more_page.dart` |
| Réglages club | nom, nom court et enregistrer; logo choisir/retirer; couleur primaire et secondaire; code/lien invitation; abonnement; sept modules; huit règles avec boutons ± | `lib/features/admin/presentation/club_settings_page.dart` |
| Fiche joueur | modifier photo/compte, identifiant, email, mot de passe, export et suppression selon les droits | `lib/features/profile/presentation/profile_page.dart` |
| Effectif permanent | ajouter un joueur sans compte, éditer, gardien/coach, lier/délier profil, photos des tenues, retirer | `lib/features/players/presentation/players_registry_page.dart` |
| Match (admin) | type, adversaire, domicile/extérieur, lieu et adresse, date, heure, rendez-vous, nombre convoqués, disponibilité, maillot, enregistrer/supprimer | `lib/features/matches/presentation/match_form_page.dart` |
| Composition (admin) | glisser joueurs, banc, dispositif, simuler, enregistrer, publier, exceptions et retour | `lib/features/sports_management/presentation/admin_squad_plan_page*.dart` |
| Calendrier et fiche | navigation mois/saisons, prochain match, disponibilité, prono, compo publiée, live, résultat, vote et histoire | `lib/features/matches/presentation/` et `lib/features/predictions/presentation/` |
| Live | lancer, chrono, événements, buts/passeurs, changement joueurs, modifications, finaliser | `lib/features/match_live/presentation/` |
| Notifications | préférences Web Push, historique, cloche, lien de navigation, autorisation navigateur | `lib/features/notifications/presentation/` |
| Badges/bilan | armoire, aperçu, administration, déblocage, animations de saison, partage | `lib/features/badges/presentation/`, `lib/features/season_wrapped/presentation/` |

Cette liste de commandes est **un premier registre de composants identifiés, pas encore un inventaire AST exhaustif de chaque `onPressed`/`onTap`** : le fil 03 doit créer/maintenir les cas de test explicites et rapprocher les widgets secondaires.

## 3. Sept interrupteurs activables par club

Source `lib/features/club/data/club_repository.dart`, enum `ClubModule`. Ce sont les **clés exactes attendues** côté API `admin_set_club_module`.

| Clé technique | Module de l'interface | Conséquence à valider |
|---|---|---|
| `predictions` | Pronostics et classement | Entrée masquée et écriture prono refusée |
| `statistics` | Statistiques | Onglet, filtres et routes directes adaptés |
| `man_of_the_match` | Homme du match | Vote masqué et écriture refusée |
| `live_mode` | Mode live | Session et commandes refusées côté serveur |
| `badges` | Badges | Armoire et administration conditionnées, données conservées |
| `season_wrapped` | Bilan fin de saison | Bouton, accès direct et aperçu cohérents |
| `weather` | Météo | Affichage conditionné, aucune fuite interclub |

Le catalogue du code comporte **sept** interrupteurs. **La gestion sportive de base est conçue comme permanente** dans `features/feature_flags/domain/feature_flags.dart`, non comme un huitième interrupteur club. Ajouter cette option uniquement sur décision de produit après vérification des dépendances.

## 4. Huit règles numériques de club

Source SQL `supabase/migrations/20261111070000_regles_club.sql`, fonction `private.club_rule_catalogue()` : **les valeurs sont des défauts, pas des valeurs universelles à imposer**.

| Clé | Paramètre | Défaut | Min–max | Effets associés |
|---|---|---:|---|---|
| `features_open_days` | Jours avant ouverture | 6 j | 1–21 | Disponibilités, compo, pronostics |
| `features_open_hour` | Heure de l'ouverture | 12 h | 0–23 | Mise à disposition selon timezone |
| `prediction_close_minutes` | Fermeture avant coup d'envoi | 15 min | 0–240 | Ferme pronos et ouvre live |
| `prediction_reminder_hour` | Heure rappel prono | 16 h | 0–23 | Notification prévue |
| `motm_window_hours` | Durée vote du match | 24 h | 1–168 | Fenêtre de scrutin |
| `correction_window_hours` | Correction après validation | 24 h | 1–168 | Historique des corrections |
| `waitlist_cutoff_days` | Jours limite attente | 1 j | 0–7 | Crédit des tours d'attente |
| `waitlist_cutoff_hour` | Heure limite attente | 12 h | 0–23 | Crédit des tours d'attente |

Attention : deux réglages partagent plusieurs actions (fermeture prono/ouverture Live); l'UI et les RPC doivent lire **la même valeur**. La notation des heures 'en France' dans le catalogue documente une limite actuelle Europe/Paris, à rendre compatible timezone hors France lorsque ce marché est visé.

## 5. Contrats API et zones d'autorisation

Les RPC suivantes sont directement référencées dans `lib/features/club/data/club_repository.dart` :
`get_club_modules`, `admin_set_club_module`, `get_club_rules`, `admin_set_club_rule`, `admin_regenerate_club_invite_code`, `admin_update_club_identity`, `admin_update_club_colors`, `admin_set_club_logo`.

Points de contrôle par le fil 04 : vérifier `auth.uid()` et adhésion au club actif à l'intérieur des RPC privilégiées; vérifier les vérifications d'admin côté serveur; vérifier les limites d'entrée pour clés inconnues; vérifier que l'option module-off empêche réellement les mutations et laisse les historiques lisibles selon politique du produit; tester un appel avec UUID de match ou de joueur appartenant à un autre club.

Les Edge Functions sont déployées sur le projet commercial mais leur état `ACTIVE` n'est pas une preuve de succès. Tests nécessaires pour les endpoints qui exposent une route publique (inscription, calendrier, notification) : authentification/secret, taux de requêtes, horodatage, données d'autres clubs, durée de vie des liens.

## 6. Grille de validation de chaque route

Pour chaque route de la section 1, renseigner **OK, KO ou NON TESTÉ**, avec date/build et preuve :
1. Ouverture depuis l'interface (bouton ou lien); 2. ouverture directe en URL; 3. anonyme; 4. compte pending; 5. joueur actif de son club; 6. joueur d'un autre club et ID de l'autre club; 7. admin de son club; 8. admin d'un autre club; 9. club suspendu; 10. module off; 11. session expirée; 12. mobile/PWA; 13. écran vide; 14. mauvaise connexion.

Ne pas déduire d'un redirect Flutter qu'une RPC est sécurisée; vérifier l'autorisation en base. Ne pas modifier AS Grinta ni ses données pour exécuter ces scénarios.
