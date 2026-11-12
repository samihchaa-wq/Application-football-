# MISSION 01 — Audit exhaustif d'AS Grinta vers une application multiclub

Mis à jour le 12 novembre 2026 dans la PR #25. Reprise approfondie du premier audit. **Aucune modification de logiciel ni de données.** Cahier des charges associé : [CAHIER_DES_CHARGES_FIL_2.md](CAHIER_DES_CHARGES_FIL_2.md).

## Méthode, état et réserves

- Comparaison GitHub de l'original **en lecture seule** et du dépôt commercial ; consultation des écrans Flutter, règles SQL/migrations, Edge Functions, tests, documents de spécifications.
- Base commerciale consultée avec **SELECT uniquement** : 19 migrations enregistrées (dernière : 20261112050000), 8 Edge Functions ACTIVE, 59 tables public + 24 private avec RLS, 0 clubs, 0 profils, 0 utilisateurs Auth, 0 matchs. Schéma install_tmp encore présent. Les 3 buckets sont app-assets (public), badge-images (public), profile-photos (privé).
- Les 2 workflows CI associés au commit de départ de PR #25 ont réussi, mais **aucun parcours fonctionnel n'a été testé en environnement commercial** dans cet audit. Ne jamais confondre présence du code, migration appliquée, test automatisé écrit et fonctionnement vérifié.
- **Classification :** 1 conserver ; 2 conserver mais modifier ; 3 paramétrer par club ; 4 activer/désactiver par club ; 5 supprimer uniquement contenu spécifique ou ancienne fonction désactivée. Classements combinés possibles.
- **État :** SRC = code présent, non exécuté ici ; DEP = fonctions ou migrations en place, non testées bout à bout ; PARTIEL = adaptation en cours ; DEV = à construire ; DIFF = présent récemment dans l'original, pas encore commercial ; ABSENT = contenu volontairement non transféré ; DEP-410 = endpoint désactivé conservé par compatibilité.
- **P0** avant club pilote ou vente selon la fonctionnalité ; **P1** avant généralisation ; **P2** amélioration / marché supplémentaire ; **P3** plus tard. Risque = scénario à vérifier, **pas** une vulnérabilité avérée.

## Registre des fonctionnalités

Les identifiants stables servent de références aux tests, décisions et tâches du fil 2.

### Accès, navigation, ergonomie

Sources : lib/app/router/app_router.dart ; lib/app/shell/app_shell.dart ; lib/features/more/presentation/more_page.dart.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| N01 | Accueil redirigé vers calendrier des matchs | 1 | SRC | Préserver le parcours initial et les liens existants | Rupture navigation | P1 |
| N02 | Onglets Calendrier/Statistiques | 1+4 | SRC | Onglet Stats absent si module désactivé | Ecran vide | P1 |
| N03 | Navigation latérale sur ordinateur | 1 | SRC | Maintenir mise en page responsive | Ergonomie | P2 |
| N04 | Recentrer prochain match au lancement et reprise | 1 | SRC | Conserver position lors du retour fiche historique | Perte du contexte | P1 |
| N05 | Liens profonds vers match, composition, profils, notifications | 2 | SRC | Tester après session expirée et PWA installée | Mauvaise page | P1 |
| N06 | Anciennes URL de pronos et statistiques | 1 | SRC | Maintenir redirections compatibles | Liens cassés | P2 |
| N07 | Chargements, erreurs et écrans vides | 1 | SRC | Examiner de vrais clubs vierges et hors ligne | Blocage silencieux | P1 |
| N08 | Aperçu admin « voir comme un joueur » | 1 | SRC | Masquer actions, ne jamais réduire contrôle serveur | Droits confus | P1 |
| N09 | Thème sombre, typographies, icônes, transitions | 2+3 | SRC | Préserver ADN tout en ajoutant identité club | Lisibilité | P2 |
| N10 | Français, formats de date et langue | 2+3 | SRC | Francophone initialement ; prévoir localisation | Extension géographique | P2 |
| N11 | Retour navigateur sans empiler les onglets | 1 | SRC | Tester Android et iOS | Historique saturé | P1 |
| N12 | Cache local, synchronisation et retour au premier plan | 1 | SRC | Purger état d'ancien compte/club | Données résiduelles | P0 |

### Comptes, inscription, profils et rôles

Sources : lib/features/auth/ ; lib/features/profile/ ; lib/features/club/ ; supabase/functions/register-account.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| A01 | Créer un club puis son administrateur | 2 | DEP | Tester atomicité et rollback si création incomplète | Club orphelin | P0 |
| A02 | Rejoindre via code propre au club | 3 | DEP | Contrôle code et rattachement serveur | Intrusion interclub | P0 |
| A03 | Lien d'invitation prérempli | 1 | SRC | Tester format URL et installation PWA | Inscription impossible | P1 |
| A04 | Renouveler le code d'invitation | 3 | DEP | Invalider le précédent | Code compromis | P1 |
| A05 | Créer compte par prénom, nom, mot de passe | 2 | DEP | Validations, erreur claire, collision, anti-abus | Doublons/abuse | P0 |
| A06 | Identifiant généré du nom | 2 | SRC | Corriger limite des homonymes mondiaux | Saturation à plusieurs clubs | P1 |
| A07 | Connexion identifiant + mot de passe | 1 | SRC | Tester e-mail technique/identifiant et mauvais mot de passe | Connexion en panne | P0 |
| A08 | Connexion Facebook OAuth | 2+4 | SRC | Fournisseur non prouvé configuré ; masquer si absent | Bouton inactif | P2 |
| A09 | Connexion Apple en cas de store natif | 2 | DEV | Décider selon mode de distribution | Rejet de publication | P2 |
| A10 | E-mail facultatif du compte | 1 | DEP | Vérifier unicité, modification, droits de lecture | Compte non récupérable | P1 |
| A11 | E-mail de confirmation | 1 | DEP | Tester lien expiré, erreurs et URL retour | Parcours brisé | P0 |
| A12 | Mot de passe oublié / réinitialisé | 1 | SRC | Tester délivrance réelle d'e-mail et session | Perte d'accès | P0 |
| A13 | Changement forcé de mot de passe | 1 | SRC | Bloquer fonctions tant que non terminé | Accès inadéquat | P1 |
| A14 | Changement de mot de passe sur profil | 1 | SRC | Valider policy et erreurs réseau | Compte compromis | P1 |
| A15 | Compte en attente puis validation par admin | 1 | DEP | Zéro accès métier tant qu'en attente | Fuite de données | P0 |
| A16 | Refus/désactivation/réactivation d'un compte | 1 | SRC | Vérifier révocation effective et historique | Accès persistant | P0 |
| A17 | Rôles membre et admin | 1 | DEP | Autorisation en serveur/RLS, pas seulement écran | Elévation de droits | P0 |
| A18 | Coach membre et pilote du Live | 1 | SRC | Hors quota et hors stats joueurs, mais garde pronos | Erreur sportive | P0 |
| A19 | Gardien comme attribut sportif | 1 | SRC | Pas de privilège de compte associé | Droits confus | P1 |
| A20 | Lier compte à joueur canonique | 2 | DEP | Bloquer liaison d'un autre club, contrôler unicité | Usurpation | P0 |
| A21 | Joueur sans compte et invité sans inscription | 1 | SRC | Distinguer titulaire, coach, invité, spectateur | Statistiques incohérentes | P1 |
| A22 | Modifier photo, nom et profil personnel | 2 | SRC | Fichiers cloisonnés, droit d'image, recadrage | Vie privée | P1 |
| A23 | Déconnexion et désabonnement push | 1 | SRC | Purger les données d'appareil et notifications | Fuite appareil partagé | P0 |
| A24 | Téléchargement des données personnelles | 2 | DEP | Tester complétude et sécurité export | RGPD | P0 |
| A25 | Suppression du compte | 2 | DEP | Tester anonymisation sportive et invalidation session | RGPD et historique | P0 |
| A26 | CGU, confidentialité, version d'acceptation | 2 | DEP | Compléter contenu, forcer nouvelle acceptation | Conformité | P0 |
| A27 | Déclaration 15 ans / autorisation parentale | 2 | DEP | Valider fondement juridique et preuve | Mineurs | P0 |
| A28 | Ancien endpoint claim-account | 5 | DEP-410 | Garder 410 de compatibilité, ne pas réactiver | Anciens clients | P3 |

### Personnalisation et règles du club

Sources : lib/features/admin/presentation/club_settings_page.dart ; lib/features/club/data/club_repository.dart ; supabase/migrations/20261111070000_regles_club.sql.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| C01 | Nom et nom court du club | 3 | DEP | Propager partout, export et notifications inclus | Marque erronée | P0 |
| C02 | Logo / écusson neutre par défaut | 3 | DEP | Téléversement, retrait, cache, droits fichier | Exposition de médias | P1 |
| C03 | Couleurs primaire et secondaire | 3 | DEP | Contraste, repli, accessibilité | Texte illisible | P1 |
| C04 | Nom commercial, icônes et manifest | 2 | SRC | Choisir et neutraliser les références visibles | Commercialisation | P1 |
| C05 | Adresse du terrain domicile par défaut | 3 | DIFF | Migrer fonction depuis original, sans copie SQL brute | Lieu et météo erronés | P0 |
| C06 | Nombre habituel de joueurs convoqués | 3 | DIFF | Porter réglage original 1–30 vers club courant | Quota 14 imposé | P0 |
| C07 | Ouverture en jours avant le match | 3 | DEP | Bornes 1–21 jours, règles match conservées | Dates divergentes | P1 |
| C08 | Heure d'ouverture des modules | 3 | DEP | Bornes 0–23 h, DST/fuseau | Mauvaise heure | P1 |
| C09 | Fermeture pronos / gel des équipes | 3 | DEP | Bornes 0–240 min avant coup d'envoi | Course d'états | P1 |
| C10 | Heure de rappel de prono | 3 | DEP | Bornes 0–23 h ; Cron réel | Rappel absent | P1 |
| C11 | Durée du vote après match | 3 | DEP | Bornes 1–168 heures | Vote trop tôt/tard | P1 |
| C12 | Délai de correction du compte rendu | 3 | DEP | Bornes 1–168 heures | Stats définitives erronées | P1 |
| C13 | Jour/heure butoir liste d'attente | 3 | DEP | Bornes 0–7 j et 0–23 h | Injustice | P1 |
| C14 | Interrupteurs Pronos, Stats, HDM, Live, Badges, Bilan, Météo | 4 | DEP | Tester UI et blocage serveur selon la fonction | Contournement | P0 |
| C15 | Interrupteur de gestion sportive globale | 4 | DEV | Future option sous arbitrage des dépendances | Cycle match cassé | P3 |
| C16 | Un club = une équipe/espace | 2 | DEP | Déclarer limite ; multiéquipe à décider plus tard | Clientèle exclue | P2 |
| C17 | Fuseau horaire par club | 3 | DEV | Paris en dur dans SQL et Dart | DOM-TOM/étranger | P2 |
| C18 | Réglages par saison ou par club | 2 | SRC | Dire ce qui s'applique aux matchs futurs | Surprises | P1 |
| C19 | Changement réglage sur deux appareils simultanés | 1 | SRC | Réviser cache via Realtime et refetch | Etat périmé | P1 |

### Saison, calendrier, matches et adversaires

Sources : lib/features/matches/ ; lib/features/admin/presentation/admin_season_section.dart ; supabase/migrations/.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| M01 | Créer / ouvrir une saison | 1 | DEP | Garantir une seule saison ouverte | Saisons concurrentes | P0 |
| M02 | Clôturer/archiver une saison | 1 | SRC | Archiver sans détruire stats et résultats | Données perdues | P1 |
| M03 | Consulter saisons passées | 1 | SRC | Lecture seule et séparation archives historiques | Confusion | P1 |
| M04 | Joueurs persistants à travers saisons | 2 | SRC | Identité canonique sans duplication | Statistiques brisées | P1 |
| M05 | Calendrier mensuel/chronologique et cartes | 1 | SRC | Phases futures, Live, terminées, annulées | UX | P1 |
| M06 | Créer un match avec date/heure/adversaire | 1 | SRC | Validations, collisions, permissions | Planning erroné | P0 |
| M07 | Match de championnat et journée Jn | 1 | SRC | Journée optionnelle et cohérente | Classement incohérent | P1 |
| M08 | Match amical | 1 | SRC | Conserver règles communes | Faible | P1 |
| M09 | Match « entre nous » | 1 | SRC | Deux équipes, nombre de présents 1–11, pas de faux pronos | Exceptions | P1 |
| M10 | Match de coupe | 2 | DEV | Ancienne PR le disait existant ; modèle ne le propose pas | Promesse fausse | P2 |
| M11 | Domicile/extérieur | 1 | SRC | Adapter affichage et lieu aux adversaires | Erreur de localisation | P1 |
| M12 | Rendez-vous par défaut T-30 ou personnalisé | 3 | SRC | Garder rendez-vous indépendant du coup d'envoi | Retards | P1 |
| M13 | Durée de jeu prévue, défaut 90 min | 3 | SRC | Lier futurs formats 5/7/8/11 | Live inadapté | P2 |
| M14 | Modifier date/heure/lieu/adversaire | 1 | SRC | Réinitialiser seulement les états exigés | Réponses perdues | P0 |
| M15 | Annuler/reporter un match | 1 | SRC | Aucune attribution erronée de points/passage | Injustice | P0 |
| M16 | Supprimer match selon fenêtre de sécurité | 1 | SRC | Vérifier Live, score et tombstones ICS | Intégrité | P1 |
| M17 | Événements du club hors match | 1 | SRC | CRUD, lieu, échéance et calendrier | Agenda | P1 |
| M18 | Bibliothèque équipes et stades | 1 | SRC | Éviter doublons, adresses réutilisables | Qualité des données | P1 |
| M19 | Prévisualisation des cotes adversaires | 1 | SRC | Repli sans historique, pas d'adversaire d'AS Grinta | Cotes trompeuses | P1 |
| M20 | Saisie manuelle d'archives de matchs | 2 | PARTIEL | Terminer parcours sans faux Live/prono | Historique contaminé | P1 |
| M21 | Import des données historiques d'AS Grinta | 5 | ABSENT | Ne transférer aucun match/stat/joueur de l'original | Confidentialité | P0 |
| M22 | Rapprochement identités et surnoms historiques | 2 | DEP | Ne pas fusionner des homonymes arbitrairement | Stats fausses | P1 |
| M23 | Flux calendrier .ics et abonnements | 2 | DEP | Token, révocation, mise à jour, Apple/Google/Outlook | Secret de lien | P1 |
| M24 | Identifiant ICS sporteasy-grinta | 2 | SRC | Neutraliser sans briser anciens abonnements | Marque tierce | P1 |
| M25 | Saison implicitement juillet-juin | 3 | SRC | Rendre cycle saison configurable si cible élargie | Bilan mal placé | P2 |


### Disponibilités, convocations et liste d'attente

Sources : lib/features/sports_management/data/match_availability_repository.dart ; presentation/admin_waitlist_page.dart ; docs/changes/refonte-liste-attente-3-regles.md.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| D01 | Déclarer présent/absent/sans réponse | 1 | SRC | Contrôler transitions et accès selon horaire | Convocations erronées | P0 |
| D02 | Ouverture disponibilités J-6 à 12h par défaut | 3 | DEP | Appliquer règles horaires du club | Ouverture inattendue | P1 |
| D03 | Ouverture spécifique anticipée/retardée du match | 3 | SRC | Faire prévaloir choix explicite du match | Fenêtre contradictoire | P1 |
| D04 | Tableau disponibilités et photos des joueurs | 1 | SRC | Rôles, filtres, cache et nouveaux arrivants | Effectif faux | P1 |
| D05 | Indisponibilité sur intervalle de dates | 1 | SRC | Ajouter, modifier, annuler ; dates incluses | Absence non comptée | P1 |
| D06 | Motif d'absence visible seulement intéressé/admin | 1 | SRC | Vérifier RLS, RPC et journaux | Donnée personnelle exposée | P0 |
| D07 | Indisponibilité prime sur réponse et convocation | 1 | SRC | Rattraper match créé/déplacé pendant période | Convoqué à tort | P0 |
| D08 | Blocage modification disponibilité pendant indisponibilité | 1 | SRC | Interdit également à admin, sauf annulation de période | Règles violées | P1 |
| D09 | Désistement d'un convoqué et promotion suivant | 1 | SRC | Priorité, idempotence, notifications réelles | Sureffectif | P0 |
| D10 | Retour d'un convoqué après absence | 1 | SRC | Ne pas dépasser quota, recalcul cohérent | Sureffectif | P0 |
| D11 | Quota par rencontre et règle de club par défaut | 3 | PARTIEL | Créer écran club 1–30, conserver exceptions par match | Quota AS Grinta imposé | P0 |
| D12 | Ordre de liste d'attente historique | 3 | PARTIEL | Réconcilier moteur actualisé, rang et compteur | Injustice | P0 |
| D13 | Trois modes envisagés admin/arrivée/présence | 3 | DEV | Faire confirmer contrat et persistance par match ou club | Modes incompatibles | P1 |
| D14 | Crédit +1 après passage en attente | 3 | PARTIEL | Au plus une fois par match, idempotent au coup d'envoi | Points dupliqués | P0 |
| D15 | Correction admin +/- des passages | 1 | SRC | Journal d'audit, retri automatique sans bouton | Désaccord classement | P1 |
| D16 | Modification manuelle convoqués/attente | 1 | SRC | Conserver choix jusqu'à changement de disponibilité | Choix effacé | P1 |
| D17 | Date/heure limite de crédits d'attente | 3 | DEP | Aucun crédit lors d'annulation, report ou quota élargi | Injustice | P1 |
| D18 | Consultation liste d'attente par joueurs | 1 | SRC | Toujours lecture seule pour non-admin | Elévation de droit | P1 |
| D19 | Joueur permanent sans compte connecté | 1 | DEP | Lier plus tard sans doubler statistiques | Identités dupliquées | P1 |
| D20 | Invités ponctuels / réutilisables / archivage | 1 | SRC | Aucune suppression destructive d'historique | Perte références | P1 |
| D21 | Coach présent hors quota, jamais titulaire ni attente | 1 | SRC | Exception dans tous les états et règles de facturation | Règles incohérentes | P0 |
| D22 | Rappels manuels des joueurs n'ayant pas répondu | 1 | SRC | Exclure indisponibles, éviter répétitions | Spam | P1 |
| D23 | Publication effectif et déclenchement notifications | 1 | SRC | Destinataires corrects, contrôle serveur, gel | Fuite d'info de match | P1 |

### Compositions, maillots, simulations et présentation

Sources : lib/features/sports_management/domain/football_formation.dart ; presentation/admin_squad_plan_page*.dart ; presentation/widgets/composition_presentation*.dart ; lib/features/matches/domain/jersey_option.dart.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| P01 | Editeur terrain de titulaires et banc | 1 | SRC | Glisser-déposer, joueurs uniques, emplacement vide | Compo invalide | P1 |
| P02 | 26 dispositifs actuels de football à 11 | 2+3 | SRC | Créer catalogue adapté aux autres formats | Formats non supportés | P1 |
| P03 | Format football à 11, 8, 7, 5 | 3 | DEV | Régler nombre titulaires, rôles, dispositif et durée | Marché restreint | P1 |
| P04 | Dispositif préféré 4-2-1-3 | 3 | SRC | Changer valeur par défaut par club/format | Préférence AS Grinta | P1 |
| P05 | Simuler un onze automatiquement | 1 | SRC | Conserver priorités, postes, derniers bancs, gardien | Proposition incohérente | P1 |
| P06 | Postes de référence calculés depuis matchs du club | 1 | SRC | Aucun poste historique propre à AS Grinta | Profil artificiel | P1 |
| P07 | Priorité au joueur resté sur banc lors dernier match joué | 1 | SRC | Ne pas forcer poste inadapté | Rotation injuste | P1 |
| P08 | Explication des placements hors poste / poste vide | 1 | SRC | Messages compréhensibles, pas de donnée autre club | Explication absente | P2 |
| P09 | Enregistrer et publier composition | 1 | SRC | Côté serveur, cohérent avec l'effectif | Etat incomplet | P0 |
| P10 | Gel effectif/compo T-15 réglable | 3 | DEP | Respecter le délai choisi, Live et édition postérieure | Modification interdite contournée | P0 |
| P11 | Deux compositions pour un match entre nous | 1 | SRC | Equipe A/B, effectif 1–11, pas de doublons | Joueur dans deux équipes | P1 |
| P12 | Maillots fixes Blanc, Orange, Bleu | 3 | SRC | Créer maillots au choix de club, repli neutre | Aspect spécifique AS Grinta | P0 |
| P13 | Portraits par trois tenues saisonnières | 2+3 | SRC | Associer options photos aux nouveaux maillots | Photos incompatibles | P1 |
| P14 | Animation de composition avant affichage terrain | 1 | SRC | Déclenchement geste utilisateur, groupe, fin de vidéo | Mauvaise expérience | P1 |
| P15 | Vidéo de stade et image de fond | 2 | SRC | Vérifier droits, optimiser diffusion et prévoir sans vidéo | Droits et lenteur | P1 |
| P16 | Mini-vidéos individuelles détourées | 3+4 | DEV | Import/admin/stockage/transparent/non-vidéo ; n'est pas une fonction démontrée | Poids médias et droits | P2 |
| P17 | Portrait fixe pour joueur sans mini-vidéo | 1 | DEV | Garder fallback si option vidéo développée | Composition partielle | P2 |
| P18 | Notification composition rejoue la présentation | 1 | SRC | Respecter marqueur source notification | Animation sautée | P2 |
| P19 | Retrait portraits, maillots et visuels AS Grinta | 5 | DEP | Aucune reprise de données privées/licenciées | Atteinte droits à l'image | P0 |

### Live et temps de jeu

Sources : lib/features/match_live/ ; supabase/migrations/20261112050000_blocage_serveur_mode_live.sql.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| L01 | Live activé/désactivé par club | 4 | DEP | Refus serveur nouvelles sessions/événements ; fin toujours possible | Contournement toggle | P0 |
| L02 | Ouverture Live au gel T-15 | 3 | DEP | Synchroniser avec fermeture pronos | Ouverture trop tôt | P1 |
| L03 | Pilotage par coach ou admin autorisé | 1 | SRC | Vérifier ACL et identité de pilote | Prise de contrôle | P0 |
| L04 | Pilote unique et transfert après reconnexion | 1 | SRC | Tester concurrence 2 appareils et expiration | Double pilotage | P0 |
| L05 | Chronomètre, pause et fin | 1 | SRC | Temps serveur cohérent après retour hors ligne | Temps faux | P1 |
| L06 | But avec buteur et passeur | 1 | SRC | Score transactionnel, aucune double saisie | Résultat corrompu | P0 |
| L07 | Remplacements / salves / temps de jeu | 1 | SRC | Temps cumulés et entrée directe au banc | Minutes fausses | P1 |
| L08 | Changement de tactique durant le live | 1 | SRC | Maintenir joueurs uniques, préserver journal | Etat incohérent | P1 |
| L09 | Ajout/retrait d'un invité ou joueur tardif | 1 | SRC | Nouveau joueur sur le banc, contrôle des doublons | Participation fausse | P1 |
| L10 | Journal des événements, corrections | 1 | SRC | Horodatage, annulation et collisions | Récapitulatif faux | P1 |
| L11 | Alertes buts et abonnements par rencontre | 4 | DEP | Cohérence module, préférences, destinataires | Push vers autre club | P0 |
| L12 | Fin de Live et validation récapitulatif | 1 | SRC | Idempotence, crash et score final cohérent | Match bloqué | P0 |
| L13 | Désactivation Live pendant session active | 4 | DEP | Fin et consultation possibles sans nouvelle création | Session orpheline | P1 |

### Après-match, votes, statistiques et fiches joueurs

Sources : lib/features/sports_management/presentation/match_report_page.dart ; sport_motm_vote_page.dart ; lib/features/statistics/ ; lib/features/players/.

| ID | Fonction et description | Classement | État | Adaptation et contrôle nécessaires | Risque | Priorité |
|---|---|---|---|---|---|---|
| R01 | Score final officiel à valider | 1 | SRC | Vérifier transition Live -> rapport -> passé | Résultat prématuré | P0 |
| R02 | Buteurs, passeurs et présents du rapport | 1 | SRC | Source unique pour statistiques de match | Double comptage | P0 |
| R03 | Clean sheets, gardiens et temps de jeu | 1 | SRC | Vérifier interne, amical, historique et invité | Stats fausses | P1 |
| R04 | Correction de rapport pendant délai du club | 3 | DEP | Recalculer pronos, stats, badges et classement | Correction partielle | P1 |
| R05 | Versionnage / rejouement de validation | 1 | DEP | Rejeter double validation simultanée | Résultat dupliqué | P0 |
| R06 | Vote anonyme du joueur du match | 4 | DEP | Désactivation en SQL, anonymat et permissions | Vote manipulable | P0 |
| R07 | Fenêtre de vote / fermeture automatique | 3 | DEP | Heure selon règle et égalités | Résultat erroné | P1 |
| R08 | Ex-aequo, co-vainqueurs, résultat collectif | 1 | SRC | Afficher gagnants et notifier correctement | Conflit de trophées | P1 |
| R09 | Libellé Homme du match et badges genrés | 2+3 | SRC | Libellé neutre ou réglable, préserver fonction | Inadapté équipes mixtes | P0 |
| R10 | Statistiques collectives et séries | 4 | SRC | Masquage sans perte de données, chiffrages vérifiés | Classement incohérent | P1 |
| R11 | Stats joueurs : buts, passes, matchs, victoire | 4 | SRC | Coach hors stats sportives, invité sous contrôle | Statistiques inexactes | P1 |
| R12 | Classements par saison, précédente et total | 1 | SRC | Etats vides pour club neuf | Tableau cassé | P1 |
| R13 | Fiche joueur, portraits et maillots | 1 | SRC | Photos privées et repli image | Exposition de photo | P1 |
| R14 | Faits du match dans fiche joueur | 1 | SRC | Uniquement résultats validés, jamais Live brut | Contradiction historique | P1 |
| R15 | Identité canonique à travers historique/noms | 1 | DEP | Ne pas fusionner homonymes | Stats attribuées à tort | P1 |
| R16 | Statistiques historiques importées par le club | 2 | PARTIEL | Workflow de saisie/import volontaire, pas de données AS Grinta | Origine incertaine | P2 |

<!-- AUDIT_MISSION_01_APPEND_BLOCKS -->
