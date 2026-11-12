# Audit fonctionnel approfondi — Mission 01

> Mise à jour : 12 novembre 2026 — **audit documentaire, code, schéma et métadonnées uniquement**. Aucune migration, écriture DB, création d'utilisateur, test réel de parcours ni modification du dépôt AS Grinta.

## 0. Traçabilité et lecture du tableau

**Sources croisées** : `samihchaa-wq/AS-Grinta` (arborescence du dépôt, sans modification), `samihchaa-wq/Application-football-` (code sur `main`, docs et migrations), PR #25 existante (`docs/AUDIT_FONCTIONNALITES.md`), base commerciale Supabase `jvxkhgdopslctpcjrhzw` (métadonnées et requêtes SELECT en lecture seule). Les chemins sont indiqués par groupe; ils signalent les points d'inspection, pas une preuve E2E.

**Classification** : **C** conserver l'expérience telle quelle ; **M** conserver mais modifier ; **P** rendre configurable par club ; **O** rendre activable/désactivable par club ; **S** retirer uniquement un reliquat obsolète confirmé ou un contenu propre à AS Grinta, jamais une fonction utile. **Une fonctionnalité peut aussi cumuler P+O** (retenir la classification primaire dans le tableau et sa capacité facultative dans le cahier des charges).

**État de preuve** : **B** présence dans le code ET objet serveur/schéma compatible identifié; **C** présence dans code ou interface, pas de vérification serveur spécifique; **G** lacune, intégration partielle ou reste à décider; **H** compatibilité historique. **Aucun code B/C n'est déclaré fonctionnel en production** : aucun parcours de bout en bout authentifié n'a été exécuté. **P0** bloque le pilote, la sécurité ou l'exploitation commerciale selon son libellé; **P1** requis pour produit générique cohérent; **P2** cible future/conditionnelle. Une tâche P0 'paiement' bloque **la vente automatisée**, mais pas forcément un pilote gratuit.

## 1. Observations vérifiées le 12 novembre

- Dépôts accessibles : `Application-football-` sur `main` et `AS-Grinta` sur `main`. L'arborescence GitHub du dépôt commercial compte **1 069 chemins**, dont environ **397 sous lib**, **19 migrations commerciales** et **150 fichiers de tests SQL métier**. Celle d'AS Grinta compte **2 467 chemins**, dont **647 migrations historiques**; une comparaison d'arborescence ne remplace pas l'analyse fonctionnelle.
- Supabase commercial en statut **ACTIVE_HEALTHY**, PostgreSQL 17, région `eu-west-3` ; **19 migrations enregistrées**, dernière `20261112050000_blocage_serveur_mode_live`. Comptages observés : **0 club, 0 profil, 0 match, 0 utilisateur Auth, 0 abonnement**.
- Huit fonctions Edge **ACTIVE** : `account-email`, `calendar-feed`, `claim-account`, `claim-club`, `manage-user`, `register-account`, `send-prediction-reminders`, `send-push`. **ACTIVE ne prouve pas la configuration de leurs secrets ni leur succès**; deux endpoints anciens peuvent volontairement répondre 410 selon le contrat de sécurité.
- **59 tables public** et **24 tables private** ont RLS activée, sans table non-RLS dans ces deux schémas selon la requête d'inventaire. Trois buckets : `app-assets` (public), `badge-images` (public), `profile-photos` (privé). Le public en lecture peut être voulu pour des badges, mais les URL/chemins et la protection des photos personnelles doivent être testés.
- **157 fonctions `SECURITY DEFINER` dans `public` sont appelables par le rôle `authenticated`**, à auditer individuellement : ce seul nombre ne démontre **pas** une vulnérabilité, puisque certaines RPC vérifient explicitement les permissions. Les advisors Supabase signalent au moins une famille `function_search_path_mutable` et une famille `authenticated_security_definer_function_executable`; confier l'analyse de risque exploitabilité au fil 4.
- Le fichier `docs/HANDOFF.md` de départ déclarait Edge non déployées et 18 migrations : **information périmée** par rapport aux métadonnées en lecture seule.
- Le déploiement Pages est désactivé, les textes légaux comportent des placeholders et l'intégration des paiements n'est pas présente selon le code et la checklist.

**Limites impératives** : aucune requête n'a connecté un vrai utilisateur, créé deux clubs pilotes, déclenché une notification ou validé le comportement des RPC dans une session. La production originale d'AS Grinta n'a pas été interrogée. Les tests visibles dans le dépôt n'ont pas été exécutés ici. Les files d'implémentation actives dans d'autres fils et l'état des dernières PR doivent être réconciliés avant d'ouvrir un chantier; ne pas écraser leurs travaux.

## 2. Inventaire de référence

Les risques portent sur ce qui doit être vérifié/évité, et ne constituent pas des défaillances reproduites.


### A — Accès et vie du compte

Chemins à confronter : `lib/features/auth/`, `lib/features/profile/`, `supabase/functions/register-account/`, `supabase/functions/account-email/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| A01 | Créer un club et son compte administrateur | M | B | Valider création réelle, doublons, rollback si échec | Usurpation de club, inscription bloquée | P0 |
| A02 | Rejoindre un club par code ou lien partagé | M | B | Confirmer code, expiration/rotation et deep-link PWA | Invitation détournée, mauvais club | P0 |
| A03 | Changer le code d'invitation | C | B | Conserver et vérifier effet immédiat sur anciens liens | Accès par anciens codes | P1 |
| A04 | Inscription joueur avec validation administrateur | C | B | Tester attente, refus et activation avec deux clubs | Compte non autorisé | P0 |
| A05 | Génération de l'identifiant prénom + initiale | M | G | Résoudre homonymes à l'échelle multiclub et prévoir migration douce | Collision et échec d'inscription | P0 |
| A06 | Connexion identifiant et mot de passe | C | B | Tester session, expiration, erreurs et reconnexion | Compte inaccessible | P0 |
| A07 | Connexion Facebook | O | C | Conditionner à OAuth effectivement configuré; masquer sinon | Bouton non fonctionnel | P1 |
| A08 | Adresse e-mail facultative et confirmation | C | B | Valider délivrabilité, confirmation, expiration et doublons | Réinitialisation impossible | P0 |
| A09 | Mot de passe oublié et réinitialisation | C | B | Tester avec/sans e-mail confirmé et jetons expirés | Blocage de comptes | P0 |
| A10 | Mot de passe initial imposant un changement | C | B | Conserver obligation et tester accès refusé tant que non changé | Accès impropre | P1 |
| A11 | Acceptation CGU, politique et âge | M | C | Compléter textes et prouver version acceptée selon parcours | Non-conformité | P0 |
| A12 | Changer son profil et sa photo | C | B | Tester édition, redimensionnement, erreurs d'envoi | Contenus erronés | P1 |
| A13 | Exporter ses données personnelles | C | B | Tester exactitude, périmètre, format et droits | Données manquantes ou fuite | P0 |
| A14 | Supprimer son compte et gérer les données historiques | C | B | Tester anonymisation, statistiques, objets et sessions | Conservation abusive / incohérence | P0 |
| A15 | Déconnexion, révocation push, changement de compte | C | C | Vérifier purge cache et abonnement appareil | Fuite locale entre comptes | P0 |
| A16 | Accès club suspendu ou compte en attente | M | B | Écran adapté, interdiction serveur, voies de support | Contournement de suspension | P0 |
| A17 | Compte unique rattaché à un seul club | M | B | Rendre visible la limite; éviter bascule silencieuse | Usage multiéquipe impossible | P1 |

### B — Structure club, identité, configuration

Chemins à confronter : `lib/features/club/`, `lib/features/admin/presentation/club_settings_page.dart`, `supabase/migrations/20261111030000_reglages_club.sql`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| B01 | Nom et nom court sur tous les écrans | P | B | Éradiquer mentions visibles AS Grinta y compris exports/notifs | Mauvaise identité | P0 |
| B02 | Écusson du club et valeur neutre par défaut | P | B | Tester ajout, remplacement, suppression, cache | Image obsolète | P1 |
| B03 | Couleurs du club et contrastes | P | B | Tester combinaisons accessibles pour widgets/animations | Illisibilité | P1 |
| B04 | Nom commercial et icône installée | M | G | Décider avec fil 5 et garder distinction produit/club | Confusion de marque | P1 |
| B05 | Adresse du terrain à domicile | P | G | Ajouter écran de réglage, préremplir matchs et météo | Météo erronée, ressaisie | P1 |
| B06 | Nombre de convoqués par défaut | P | G | Exposer usual_squad_size dans administration | Quotas AS Grinta réutilisés | P1 |
| B07 | Règles d'ouverture/fermeture et délais | P | B | Documenter bornes, rétroactivité et horaire affiché | Incohérence des fenêtres | P0 |
| B08 | Choix des modules facultatifs | O | B | Vérifier comportement sans perte de données et refus côté serveur | Fonction désactivée utilisable par API | P0 |
| B09 | Changements de paramètres en temps réel | M | B | Tester invalidation du cache, plusieurs appareils, écrans ouverts | Réglage non propagé | P1 |
| B10 | Fuseau horaire du club | P | G | Conserver Paris pour cible initiale; traiter IANA pour hors-fuseau | Décalage calendrier / notifications | P2 |
| B11 | Langue, devise, formats de date | P | G | Limiter marché FR pour lancement puis plan internationalisation | Erreurs hors France | P2 |
| B12 | Un espace équivaut à une seule équipe | M | B | Documenter limite; prévoir architecture si équipe A/B | Facturation et droits multiéquipe | P2 |

### C — Saisons, effectif et identités sportives

Chemins à confronter : `lib/features/players/`, `lib/features/admin/presentation/admin_season_section.dart`, `lib/features/sports_management/data/player_identity_repository.dart`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| C01 | Ouvrir et archiver une saison | C | B | Tester clôture unique, changement et historique | Saison incohérente | P0 |
| C02 | Cycle saisonnier juillet-juin | P | G | Vérifier besoin de saisons personnalisées avant international | Décalage statistiques | P2 |
| C03 | Fichier joueurs avec/sans compte | C | B | Tester création et rattachement sans doublon | Doublons sportifs | P0 |
| C04 | Fusion de l'effectif au rattachement du compte | M | B | Vérifier changement nom, désactivation, retour saison suivante | Identité fragmentée | P0 |
| C05 | Attribut coach sans place dans quota | C | B | Conserver disponibilité, vote, prono et pilotage Live | Coach mal comptabilisé | P1 |
| C06 | Attribut gardien | C | B | Vérifier compositions, statistiques et photos | Poste invalide | P1 |
| C07 | Invités sans compte permanent | C | B | Tester réutilisation, archivage, place dans match, suppression | Perte d'historique | P1 |
| C08 | Historique canonique des joueurs et alias | M | B | Conserver rapprochement prudent des homonymes | Fusion de deux personnes | P1 |
| C09 | Trois photos de maillot par joueur | P | C | Conserver option visuelle, adapter aux maillots du club | Visuels liés AS Grinta | P1 |
| C10 | Statuts membre actif, en attente, départ | C | B | Vérifier traces passées et permissions | Compte réactivé indûment | P0 |
| C11 | Administration des profils et approbation | C | B | Tester toutes actions avec non-admin | Escalade de privilèges | P0 |
| C12 | Aperçu 'voir comme joueur' | C | C | Tester séparation prévisualisation/droits réels | Faux sentiment de contrôle | P1 |

### D — Calendrier et événements

Chemins à confronter : `lib/features/matches/`, `supabase/functions/calendar-feed/index.ts`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| D01 | Créer un match championnat, amical ou « entre nous » ; **coupe non implémentée** | C | B | Valider les trois types présents, et n'ajouter « coupe » qu'après décision produit et tests serveur/client | Match mal catégorisé / promesse commerciale trompeuse | P1 |
| D02 | Journée de championnat | C | B | Gérer doublons, valeurs manquantes, autres compétitions | Classement erroné | P1 |
| D03 | Domicile/extérieur, stade et adversaire | C | B | Conserver bibliothèque équipes/stades, édition/suppression | Adresse dupliquée | P1 |
| D04 | Horaire, lieu et heure de rendez-vous | C | B | Tester modification avant/après ouverture, report | Invitations erronées | P0 |
| D05 | Calendrier mensuel, passé, prochain, live | C | C | Tester focus, chargement paginé, responsive | Parcours perdu | P1 |
| D06 | Fenêtre 'prochain match' J-6 midi par défaut | P | B | Tester horaires locaux + valeurs admin | Accès trop tôt/tard | P0 |
| D07 | Événements de club hors match | C | B | Tester créer, éditer, supprimer, visibilité | Agenda incomplet | P1 |
| D08 | Flux calendrier .ics et liens publics | M | B | Nettoyer identifiants sporteasy-grinta, tester révocation et annulations | Fuite de calendrier / marque concurrente | P1 |
| D09 | Suppression de match et historique des annulations | C | B | Tester verrou, cascade, flux ICS, push | Données orphelines | P0 |
| D10 | Historique de matchs importés | M | B | Conserver lecture seule, aucune contamination pronos/live | Stats mélangées | P1 |
| D11 | Saisie manuelle d'anciens matchs | M | G | Vérifier travaux parallèles et critères d'import | Saisie rétroactive incohérente | P1 |
| D12 | Calcul et affichage météo du match | O | B | Dépend adresse; vérifier repli, localisation et API | Prévision trompeuse | P1 |
| D13 | Affichage score résultat et compétition | C | B | Tester score inhabituel, match annulé, chrono | Affichage faux | P1 |

### E — Disponibilité, convocations et attente

Chemins à confronter : `lib/features/sports_management/data/match_availability_repository.dart`, `lib/features/sports_management/presentation/admin_squad_plan_page_effectif.dart`, `docs/changes/refonte-liste-attente-3-regles.md`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| E01 | Réponse présent/absent au match | C | B | Tester concurrence, rechargement et historiques | Convocation incorrecte | P0 |
| E02 | Ouverture automatique ou anticipée des réponses | P | B | Tester J-6, dérogation match, fermeture | Délai non respecté | P0 |
| E03 | Périodes d'indisponibilité anticipées | C | B | Tester bornes incluses, chevauchement, report et retrait | Absence ignorée | P0 |
| E04 | Motif d'indisponibilité privé | C | B | Tester visibilité joueur/admin uniquement | Vie privée | P0 |
| E05 | Disponibilités sans réponse et relances | P | B | Configurer horaire, éviter spam/doublons | Relance excessive | P1 |
| E06 | Quota convoqués, remplaçants et coach | P | B | Défaut configurable; dépassement contrôlé | Sureffectif | P0 |
| E07 | Liste d'attente par priorité saison précédente | P | B | Rendre l'algorithme lisible et compatible autres modes | Injustice de rotation | P0 |
| E08 | Liste d'attente à 3 modes | P | G | Consolider branche parallèle, tests après migration | Modes divergents | P0 |
| E09 | Passages +1 et compteur en attente | P | G | Valider idempotence, fenêtre J-1, rétroactivité | Tours perdus ou doublés | P0 |
| E10 | Réorganisation manuelle / forcée par admin | P | B | Aligner choix temporaires et moteur automatique | Priorités contradictoires | P0 |
| E11 | Départ, retour, promotion, rétrogradation | C | B | Tester simultanéité et notification seulement sur changement | Liste incohérente | P0 |
| E12 | Effectif publié, gel T-15, exception justifiée | P | B | Tester verrou et correction serveur | Publication contournée | P0 |
| E13 | Invités dans l'effectif du match | C | B | Tester quotas, éligibilité simulation et doublons | Participant fictif | P1 |
| E14 | Match 'entre nous': tous les présents convoqués | C | B | Préserver exception au moteur de liste | Troncature d'équipe | P1 |
| E15 | Validation et notifications effectif | C | B | Tester transitions de publication et ciblage | Alerte injustifiée | P1 |

### F — Composition tactique et présentation

Chemins à confronter : `lib/features/sports_management/domain/football_formation.dart`, `lib/features/sports_management/domain/composition_simulation.dart`, `lib/features/sports_management/presentation/widgets/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| F01 | Éditeur de terrain, placement et remplaçants | C | B | Tester glisser, remplacement, poste vide, petit écran | Position perdue | P0 |
| F02 | Catalogue de 26 formations foot à 11 | P | C | Ajouter formats 5/7/8 si marché visé; conserver 11 | Club de foot réduit exclu | P1 |
| F03 | Dispositif initial 4-2-1-3 | P | G | Défaut défini par club ou format | Préférence AS Grinta imposée | P1 |
| F04 | Simulation de composition optimale | C | C | Vérifier priorités, gardien, remplaçant, historique absent | Compo aberrante | P1 |
| F05 | Profils de postes calculés via matchs passés | C | B | Tester recrue et historique ancien, identités | Biais de sélection | P1 |
| F06 | Publication et correction de composition | C | B | Vérifier verrou, droits et exceptions | Modification non permise | P0 |
| F07 | Compositions de deux équipes 'entre nous' | C | B | Tester équipes déséquilibrées, joueurs 1-11 | Joueur manquant | P1 |
| F08 | Animation d'entrée et stade vidéo | C | C | Préserver ergonomie, fluidité et vérifier droits média | Licence et performances | P1 |
| F09 | Mini-vidéos individuelles détourées 3 à 5 secondes par joueur (souhait produit, distinct de l'animation de stade) | P | G | Aucun parcours d'import/admin et stockage vidéo personnel vérifié ; définir spécification, fallback et coûts avant implémentation | PWA lourde, droits à l'image, média absent | P2 |
| F10 | Portrait fixe si joueur sans mini-vidéo | C | G | Préserver le comportement photographique actuel et exiger fallback lorsque F09 sera réellement réalisé | Présence invisible si vidéo indisponible | P1 |
| F11 | Choix du maillot du match | P | G | Remplacer enum France/Orange/Bleu par catalogue propre club | Identité incorrecte | P1 |
| F12 | Photos de kits associées à joueur/saison | P | B | Associer variantes à catalogue de club, conserver anciens matchs | Références cassées | P1 |

### G — Live, compte rendu, vote

Chemins à confronter : `lib/features/match_live/`, `lib/features/sports_management/presentation/match_report_page.dart`, `lib/features/sports_management/presentation/sport_motm_vote_page.dart`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| G01 | Activation/désactivation Live par club | O | B | Tester refus RPC et écran masqué | Accès désactivé | P0 |
| G02 | Ouverture T-15 et pilote unique | P | B | Conserver règle par défaut; tester deux pilotes | Conflit temps réel | P0 |
| G03 | Chronomètre, début/pause/reprise | C | B | Tester changement appareil, coupure, horloge | Temps de jeu incorrect | P1 |
| G04 | Événements de but et passe décisive | C | B | Tester ajout, annulation, but contre son camp, doublons | Score faux | P0 |
| G05 | Remplacements et temps de jeu | C | B | Tester salves, joueurs tardifs, gardien, banc | Temps de jeu erroné | P1 |
| G06 | Changement de formation en Live | C | B | Tester état concurrent et historique d'événements | Composition corrompue | P1 |
| G07 | Notifications de buts en direct | O | B | Coupler au réglage Live, préférences et permissions | Spam, push sans consentement | P1 |
| G08 | Finalisation récapitulatif du Live | C | B | Valider idempotence et transfert compte rendu | Statistiques non finalisées | P0 |
| G09 | Compte rendu après match et correction | P | B | Vérifier fenêtre 24 h configurable, conflits | Stats rétroactives fausses | P0 |
| G10 | Score, buteurs, passes, présence et clean sheet | C | B | Vérifier cohérence entre live, final, stats, badges | Contradictions | P0 |
| G11 | Vote anonyme de joueur du match | O | B | Neutraliser vocabulaire, préserver anonymat et anti-double vote | Confidentialité du vote | P0 |
| G12 | Ouverture/clôture et résultat du vote | P | B | Tester à la validation, délai et ex æquo | Résultat avant clôture | P1 |

### H — Pronostics et classement

Chemins à confronter : `lib/features/predictions/`, `supabase/migrations/20261111090000_blocage_fonctions_desactivees.sql`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| H01 | Pronostiquer score d'un match | O | B | Tester fenêtre, mise à jour et suppression avant verrou | Pronostic perdu | P0 |
| H02 | Confidentialité des pronos avant résultat | C | B | Vérifier API, vues et écran adversaire | Fuite anticipée | P0 |
| H03 | Fermeture T-15 configurable | P | B | Tester UTC/Paris et changements de date | Prono tardif accepté | P0 |
| H04 | Cotes automatiques basées sur adversaire/historique | C | B | Tester club neuf sans match, résultat rare et archive | Cote aberrante | P1 |
| H05 | Points exact, différence et issue | C | C | Documenter barème et cas égalités/annulations | Classement contesté | P1 |
| H06 | Classement de saison, général et historique | C | B | Tester changements rétroactifs, homonymie et égalités | Points incohérents | P1 |
| H07 | Rappel automatique personnalisé | P | B | Tester heure club, opt-out et idempotence cron | Notifications doubles | P1 |
| H08 | Désactivation pronostics et refus côté serveur | O | B | Tester POST direct, accès anciens classements | Fonction non coupée | P0 |
| H09 | Multiplicateur/prono portefeuille ×2 historique | S | H | Conserver compatibilité tant que dépendances non prouvées; retirer uniquement traces mortes | Regression anciens clients | P2 |

### I — Statistiques, fiches, archives

Chemins à confronter : `lib/features/statistics/`, `lib/features/players/presentation/player_card_page.dart`, `supabase/migrations/20261111000100_socle_structure.sql`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| I01 | Statistiques collectives équipe | O | B | Tester saison courante/précédente/global | Classement erroné | P1 |
| I02 | Statistiques individuelles buts et passes | C | B | Tester corrections d'archives et joueurs sans compte | Attribution erronée | P0 |
| I03 | Clean sheets et statistiques gardiens | C | B | Vérifier cas de remplacement/score encaissé | Récompense injuste | P1 |
| I04 | Participation, titularisation et banc | C | B | Conserver calcul historique, invités et coach | Total inexact | P1 |
| I05 | Classements, filtres et podiums | C | C | Tester rang ex æquo, pagination et saisons | Affichage trompeur | P1 |
| I06 | Carte joueur et historique des matchs | C | C | Vérifier photo, badges, réalisations, saisons vides | Fiche incomplète | P1 |
| I07 | Archives statistiques importées | M | B | Dissocier origine importée et données actuelles | Double comptage | P1 |
| I08 | Désactivation de statistiques sans effacement | O | B | Tester masquage et routes directes, data conservée | Écrans encore accessibles | P1 |

### J — Badges et gamification

Chemins à confronter : `lib/features/badges/`, `supabase/migrations/20261111050000_badges_refonte.sql`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| J01 | Catalogue de badges et catégories | O | B | Vérifier modèles à l'ouverture d'un club vide | Badges absents | P1 |
| J02 | Badges automatiques par seuil | C | B | Tester recalcul, saison/total, rétrocorrection | Attribution erronée | P1 |
| J03 | Badges événementiels et secrets | C | B | Tester combinaisons et non divulgation | Spoilers et répétitions | P1 |
| J04 | Badges manuels par administrateur | C | B | Vérifier audit et refus joueur | Attribution abusive | P0 |
| J05 | Armoire à badges et récompenses affichées | C | C | Conserver présentation et règles de visibilité | UX dégradée | P1 |
| J06 | Images, couleurs et badges stars | P | B | Conserver visuels par club, vérifier droits de fichiers | Propriété intellectuelle | P1 |
| J07 | Noms genrés, protégés, personnalisés | P | G | Neutraliser libellés puis permettre personnalisation | Exclusion / marques | P1 |
| J08 | Seuils en fonction du nombre de matchs | P | G | Étudier réglages pour saisons courtes sans changer défauts | Progression impossible | P2 |
| J09 | Notification d'attribution et boîte de réception | O | B | Tester doublons, lecture et opt-out | Spam | P1 |

### K — Bilan et animations de saison

Chemins à confronter : `lib/features/season_wrapped/`, `assets/composition/`, `assets/audio/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| K01 | Bilan personnel de fin de saison | O | B | Tester éligibilité, données nulles et saison archivée | Bilan vide/faux | P1 |
| K02 | Diapositives et animations partageables | C | C | Préserver rendu mobile/tablette et export | UX perdue | P1 |
| K03 | Aperçu administrateur avec données fictives | C | C | Indiquer clairement démo et jamais créer vraies stats | Confusion factuelle | P1 |
| K04 | Bouton visible entre deux saisons seulement | C | C | Vérifier cycle de vie et accès direct | Accès intempestif | P1 |
| K05 | Musique du bilan | O | G | Fichier audio absent d'après code; activer uniquement avec licence, repli silencieux | Droits musicaux | P2 |
| K06 | Nom Wrapped dans ressources/écran | M | G | Auditer marque visible, décider fil 5/7 | Confusion commerciale | P1 |

### L — Notifications, préférences et PWA

Chemins à confronter : `lib/features/notifications/`, `lib/features/preferences/`, `supabase/functions/send-push/`, `web/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| L01 | Abonnement Web Push et autorisation appareil | C | B | Tester iOS PWA, Android Chrome, desktop, révocation | Push jamais reçu | P0 |
| L02 | Notifications d'ouverture des disponibilités | P | B | Tester par heure et club avec tâches différées | Alerte tardive | P1 |
| L03 | Convocation, désistement, liste d'attente | C | B | Vérifier véritable changement de statut uniquement | Spam / mauvaise cible | P0 |
| L04 | Changement, annulation ou report de match | C | B | Tester ciblage et deep-link sur fiche actuelle | Information périmée | P0 |
| L05 | Composition publiée | O | B | Tester horaires, gel et préférences | Alerte inexistante | P1 |
| L06 | Pronostics, vote HDM et résultat | O | B | Tester limites/horaires et exclusions | Spoiler / relance multiple | P1 |
| L07 | Badge débloqué | O | B | Tester une seule annonce par attribution | Doubles notifications | P1 |
| L08 | Message libre administrateur et sélection destinataires | C | B | Tester périmètre, quota et contrôle admin | Message à mauvais club | P0 |
| L09 | Préférences individuelles et coupe-circuit club | P | B | Tester opt-out serveur sans réinscription | Non-respect des choix | P0 |
| L10 | Historique notifications et pastille non lue | C | B | Tester lecture, suppression, synchronisation | Boîte incohérente | P1 |
| L11 | Service worker, manifeste et installation PWA | M | C | Tester cache, version, session et liens profonds | App obsolète | P0 |
| L12 | Météo et push via tâche planifiée | M | B | Confirmer cron/secrets/accès API, surveiller erreurs | Fonction seulement déployée | P0 |

### M — Administration, support et business

Chemins à confronter : `lib/features/admin/`, `lib/features/club/data/club_subscription.dart`, `docs/exploitation.md`, `.github/workflows/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| M01 | Tableau admin comptes en attente | C | B | Tester tri, activation, refus, suppression | Administration bloquée | P0 |
| M02 | Éditer membres, effectif, badges et profils | C | B | Contrôler droits RPC, journal d'actions | Escalade | P0 |
| M03 | Éditer matchs, saisons et paramètres | C | B | Tester effets collatéraux et validation serveur | Données incohérentes | P0 |
| M04 | Envoi de notification libre | C | B | Vérifier authentification et destinataires | Abus de communication | P0 |
| M05 | Gestion du statut d'abonnement et essai 30 jours | M | B | Tester expiration, suspension, reprise, calendrier | Accès payé refusé | P0 |
| M06 | Prix indicatif 10 euros/joueur/an | P | G | Décision commerciale à prendre; pas de prix définitif | Promesse tarifaire incohérente | P1 |
| M07 | Paiement, facturation et renouvellement | M | G | Aucun Stripe intégré, prévoir webhooks idempotents | Impossible de vendre de façon automatisée | P0 |
| M08 | Console éditeur et opérateur de plateforme | M | B | Configurer opérateur et MFA/support sans accéder à autre club | Privilèges élevés | P0 |
| M09 | Quotas stockage et fichiers | P | B | Mesurer selon clubs, limiter vidéos, prévoir purge | Coûts croissants | P1 |
| M10 | Sauvegarde, restauration et supervision | M | G | Configurer secrets CI, exécuter restauration test | Perte des données | P0 |
| M11 | Journal d'incidents et support | M | B | Documenter procédures, données personnelles et alertes | Support ingérable | P1 |
| M12 | Gestion des comptes d'un club payant suspendu | M | B | Vérifier accès aux données/export avant effacement | Litige RGPD | P0 |

### N — Données, sécurité, déploiement et exploitation

Chemins à confronter : `supabase/migrations/`, `supabase/tests/database/`, `docs/COMMERCIAL_LAUNCH_CHECKLIST.md`, `.github/workflows/`.

| ID | Fonction et description | Décision | Preuve | Adaptation / vérification requise | Risque | Priorité |
|---|---|---|---|---|---|---|
| N01 | Isolation par club tables PostgreSQL | C | B | Tests A/B directs sur REST/RPC, RLS et fonctions definer | Fuite interclub | P0 |
| N02 | Isolation par club Storage | C | B | Tester chemins devinés et accès public des buckets | Photos d'autres clubs accessibles | P0 |
| N03 | Isolation par club Realtime et caches | C | B | Tester changement de session, connexions simultanées | Données du précédent club | P0 |
| N04 | Fonctions privilégiées SECURITY DEFINER | M | B | Auditer 157 RPC exécutables par authenticated et contrôles internes | Escalade ou accès horizontal | P0 |
| N05 | Endpoint publics, Web Push et anti-abus | M | B | Tester secrets, signature, taux, spam et payload | Abus coûteux | P0 |
| N06 | Migrations installées vs dépôt | M | B | 19 versions présentes y compris blocage live 20261112050000 | Dérive documentation/déploiement | P0 |
| N07 | État des Edge Functions commerciales | M | B | Huit fonctions ACTIVE; vérifier secrets et end-to-end | Endpoints en panne malgré déploiement | P0 |
| N08 | Tables et migrations testées en CI | C | C | Lancer contrôles GitHub avant fusion puis reproduire sur base isolée | Régressions invisibles | P0 |
| N09 | Déploiement site commercial actuellement désactivé | M | G | Maintenir désactivé tant que checklist lancement non passée | Accès public prématuré | P0 |
| N10 | Confidentialité du dépôt et de son historique | M | G | Traiter l'historique potentiellement sensible selon fil juridique/sécurité | Divulgation de données | P0 |
| N11 | Informations légales incomplètes | M | G | Compléter éditeur, SIRET, hébergeur, délais, consentement | Vente non conforme | P0 |
| N12 | Compatibilité des anciennes routes, RPC et clients | C | B | Ne retirer aucune API sur simple nom 'legacy' | PWA ancienne cassée | P1 |
| N13 | Dépendances Flutter/JS et licences médias | M | C | Scanner SBOM, versions, vidéos, images et typographies | Vulnérabilités / contrefaçon | P1 |
| N14 | Performance à 2, 20, 200 clubs | M | G | Tester contention, frais, cron, photos et ralentissements réels | Charge non maîtrisée | P1 |
| N15 | Protection antifuite profils et exports | C | B | Vérifier permissions sur compte inactif et lien deviné | Accès illicite | P0 |

## 3. Règles de décision à préserver

1. **Toutes les capacités utiles d'AS Grinta sont conservées**. Seuls les contenus, réglages, libellés ou reliquats techniques définitivement obsolètes peuvent être retirés, avec preuve d'absence de dépendances.
2. Pour les modules optionnels (pronostics, statistiques, HDM, live, badges, bilan, météo), la désactivation doit masquer l'UI **et** interdire les opérations d'écriture pertinentes côté serveur; ne jamais effacer des données automatiquement en éteignant un module.
3. Les règles de disponibilité, quota, attente, formation et durée doivent avoir une source de vérité par club; les valeurs historiques d'AS Grinta peuvent servir de **défauts**, pas de constantes non modifiables.
4. Le cycle complet du match est une transaction fonctionnelle : calendrier → ouverture → réponses → convoqués → compo → gel → live facultatif → compte rendu → vote facultatif → statistiques/badges/pronos → saison. Aucun chantier ne doit casser les liens entre étapes.
5. Préserver l'UX et la DA actuelles (animations, calendrier, fiches, badges, partage), mais neutraliser les marques/noms/images du club d'origine et obtenir les droits sur médias avant commercialisation.
6. Les règles coach/gardien/invité, entre-nous, saisons archivées et retrocorrections méritent des tests spécifiques : elles traversent plusieurs modules.

## 3 bis. Corrections vérifiées et coordination avec le fil 00

- **PR #29 — CHANTIER** : le fil 00 est responsable du pilotage des neuf missions. Son tableau est disponible sur la branche de la [PR #29](https://github.com/samihchaa-wq/Application-football-/pull/29) (non fusionnée au moment de ce contrôle). La présente PR #25 alimente **01 → 02**, et les risques sont transmis à **03/04/05/07/09**. L'état documentaire ne constitue pas un feu vert de développement ni de déploiement.
- **Type de rencontre :** le modèle Dart `lib/features/matches/domain/match_model.dart` admet actuellement `championnat`, `amical` et `entre_nous`, et le formulaire de création propose les mêmes familles. Le type « coupe », mentionné dans la version initiale de cette matrice, **n'est pas une fonction livrée**. La correction a été faite en D01. Une extension coupe doit être décidée et spécifiée séparément.
- **Import de vidéos individuelles :** `player_composition_video.dart` orchestre la **présentation de composition** sur fond de stade, pas un import de clip transparent pour chaque footballeur. Un éditeur d'images de joueur n'implique pas un pipeline de stockage des vidéos. F09/F10 sont donc des besoins **non démontrés en fonctionnement**, à ne pas annoncer en commercialisation.
- **Réglages récents de l'original :** `AS-Grinta/supabase/migrations/20261111100000_admin_club_defaults.sql` prévoit quota usuel de joueurs et adresse du terrain par défaut. Cette migration n'existe pas dans les 19 migrations commerciales enregistrées. **Ne pas la recopier telle quelle :** ses requêtes présument une table `club_settings` singleton ; le modèle commercial est multiclub. Tâches F2-01/02 à adapter aux `club_id` et à tester sur deux clubs.
- **Module activable :** `ClubModule` expose sept interrupteurs (pronostics, statistiques, vote, live, badges, bilan de saison, météo). Les couches Flutter et SQL peuvent avoir des comportements différents à l'arrêt : la matrice de tests des toggles doit préciser pour chacun lecture, création, notification, données historiques et réactivation.
- **Notifications / endpoint :** présence d'une Edge Function en état ACTIVE ne prouve ni configuration VAPID, ni planification, ni réception sur téléphone. Les deux fonctions héritées `claim-account` et `send-prediction-reminders` sont décrites comme endpoints de compatibilité 410 dans `docs/business-security-matrix.md`; **ne pas les compter comme des parcours actifs**.
- **Risque sécurité :** les 157 fonctions `SECURITY DEFINER` appelables par `authenticated` sont une **surface à auditer**, et non 157 failles confirmées. Fil 04 : inventorier ACL, contrôles internes, `search_path`, RLS et preuves A/B. Ne pas effectuer d'écriture SQL pendant la mission 01.
- **Incertitude de couverture :** les 164 lignes sont le **référentiel métier**. Un audit interaction-par-interaction (routes, boutons, modales, RPC et interactions d'admin) doit encore être rapproché d'un relevé de test des écrans par les fils 02/03 ; ne pas prétendre l'exhaustivité opérationnelle.

### Registre d'arbitrage à faire valider par le propriétaire

| Réf. | Décision demandée | Proposition soumise, sans modification appliquée |
|---|---|---|
| DEC-01 | Périmètre initial : une équipe par club/espace ou multiéquipe | Une équipe/espace pour le pilote, transparent dans l'offre |
| DEC-02 | Foot à 11 seulement au lancement ou aussi 5/7/8 | Lancer à 11 si cible initiale 11, développer les autres formats avant de les vendre |
| DEC-03 | Pseudo lisible global, par club, ou e-mail obligatoire | Corriger les homonymes sans rendre l'e-mail obligatoire par surprise |
| DEC-04 | Choix des maillots : couleurs, modèles ou fichiers propres au club | Prévoir catalogue par club, fallback neutre |
| DEC-05 | Nom du trophée Homme du match et badges genrés | Libellé inclusif neutre ou modifiable ; coordination DA/juridique |
| DEC-06 | Import mini-vidéos individuelles au lancement ou plus tard | Option à spécifier, pas une fonction existante confirmée |
| DEC-07 | Prix, modèle d'abonnement, moyens de paiement, essai | Réservé aux fils 06/07 et au propriétaire ; ne pas facturer selon le défaut technique |
| DEC-08 | Marque, propriété/licences vidéos et musique | Réservé aux fils 05/07 ; ne pas transporter de média original sans droits |


## 4. Zones à explorer pour atteindre une exhaustivité démontrable

- Inventorier chaque route `go_router`, bouton, dialogue, contrôle, paramètre et action des `lib/features/**/presentation/**`, puis relier action → dépôt Dart → table/RPC/Edge Function → test de permission/résultat. Les lignes ci-dessus sont un **inventaire de fonctions métiers**, pas encore un tableau bouton-par-bouton.
- Cartographier toutes les RPC `public`, triggers, CRON, objets Storage, policies, scripts CI; faire valider via les fils 3/4. Les modèles d'accès détaillés et la matrice des cas limites relèvent de ces fils.
- Confronter les différences de versions/branches : PR #25, futurs correctifs de liste d'attente et historique, déploiement Edge, réglages horaires et demandes nouvelles. Une arborescence n'est qu'un instantané.
- Demander au fil 3 les preuves E2E sur une base de test autorisée avec deux clubs A/B et les résultats détaillés, **sans données AS Grinta**.

**Nombre d'éléments inventoriés : 164**, sans sous-entendre qu'ils ont tous été testés en fonctionnement réel. Référentiel de tâches et critères dans `docs/CAHIER_DES_CHARGES_FIL_02.md`.
