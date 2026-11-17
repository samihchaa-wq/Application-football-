# M01 — Contrat fonctionnel Petit Filet, premier lot

Publication : 16 novembre 2026 (Europe/Paris). **Mission en cours ; audit exhaustif non terminé.**
Baseline : `5f404e70f70b4e99d754f7064b567d027d66fe03`, main revérifié avant publication.
Environnement : copie locale du seul dépôt commercial et métadonnées Supabase commercial `jvxkhgdopslctpcjrhzw` en lecture seule. Observations serveur et journaux CI collectés le 15/11 au soir.
Plan lu sur PR #147, SHA `dd26ace17dc42c1af8bd9773f578f20e5a29067d`, puis commentaires actualisés.

## 1. Cadrage et continuité

Le [dernier arbitrage consigné par M00](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903574947) remplace l'offre initiale du plan : **100 € par équipe par an dès souscription**, exception de test gratuit pour 2–3 pilotes, portée/durée à contractualiser. Aucune activation de paiement autorisée ici. Les mentions antérieures « année gratuite pour tous », « 100 €/club » et « 10 €/joueur/an » ne doivent pas devenir le contrat futur. Le calendrier pilotes mars/avril 2027 et prospection été reste la référence.

Les **164 IDs A01–N15** de [l'audit initial](../AUDIT_FONCTIONNALITES_DETAILLE.md) sont conservés ; pas de suppression de fonctionnalité ni de réécriture de leur historique. Le [cahier F2-00–F2-29](../CAHIER_DES_CHARGES_FIL_02.md), le [registre QA](../QA_REGISTRE_VALIDATION.md) et les [grilles écran](../qa_saison_20261113/03_ecrans_routes.md) restent les sources antérieures, avec leurs dates et limites. La PR #25 est fusionnée ; CHANTIER la décrit encore ouverte. M00 possède la réconciliation des documents centraux.

Annexes : [66 réglages](M01_REGLAGES_CLUB.md), [48 routes](M01_NAVIGATION.md).

**Ce lot** : contradictions vérifiées, critères prioritaires transmissibles, catalogue serveur de 66 règles et inventaire des routes actuelles.
**Reste à faire** : détailler les 164 fonctions et chaque bouton/formulaire/modale en contrats indépendants, achever action → repository → RPC/Edge → test, vérifier chaque dépendance et faire jouer les scénarios. Aucun pourcentage global de complétude n'est calculé.

## 2. Échelle des preuves

- DOC : ancien document, ne prouve pas l'état actuel.
- CODE : chemin relu, pas une réussite utilisateur.
- DB : objet/définition effectivement lu sur la base commerciale, pas une exécution métier.
- CI : journal d'une suite exécutée sur le SHA cité ; couverture partielle du critère.
- RÉEL : parcours joué dans le client et résultat constaté. **Aucun nouveau parcours RÉEL dans M01.**
- DÉPLOYÉ : une publication ou un objet installé est observé ; ne prouve pas la recette.

Les scénarios `REC-<ID>` ci-dessous sont des **spécifications à exécuter par M03**, pas des tests qui auraient passé. Pour chacun : entrée, attendu/obtenu, SHA, environnement, rôle, horodatage, preuve, anomalie et retest obligatoires. Ajouter refus joueur/autre espace, réseau interrompu et double soumission aux écritures.

## 3. Contrats prioritaires du premier lot

Responsables : **M02 réalisation, M03 recette** sauf mention contraire. M01 maintient les exigences ; M00 arbitre périmètre et échéances. Sources abrégées définies après le tableau. « Obligatoire » concerne le socle ; une option conserve ses historiques quand elle est coupée.

| ID conservé / scénario | Acteurs et caractère | Attendu et critère mesurable | Source et test existant à rapprocher | Observation et dépendance |
|---|---|---|---|---|
| A01 / REC-A01 | Visiteur → admin ; obligatoire | Création d'un espace et de son admin cohérente ; échec intermédiaire sans espace orphelin ; double soumission sans double création. | AUTH, CLUB ; auth_register_page_test.dart | CODE/DB partiels ; M04 contrôle privilèges. |
| A02–A04 / REC-A02 | Visiteur/admin ; obligatoire | Code normalisé ; code invalide refusé ; rotation invalide l'ancien ; nouveau membre n'accède pas aux données avant validation. | AUTH, CLUB ; choose_club_page_test.dart | CODE ; rapprocher F2-00, T01–T05 avec M02. |
| A05–A06 / REC-A05 | Joueur/admin ; obligatoire | Deux homonymes n'écrasent aucun compte ; identifiant existant préservé ; erreur connexion lisible ; reprise de session sans données d'un autre espace. | AUTH ; auth_controller_test.dart | Homonymes encore à instruire ; ne pas imposer une migration d'identifiants sans contrat. |
| A07 / REC-A07 | Visiteur ; statut à arbitrer | Ne présenter OAuth comme disponible que si un parcours effectif et fournisseur configuré existent. | auth_sign_in_page.dart | Pas de bouton Facebook dans la page relue ; ancien audit le recensait. Aucune suppression décidée ici. |
| A08–A10 / REC-A09 | Joueur/public ; socle comptes | Ajouter/confirmer une adresse ; demander lien autonome ; réponse générique pour adresse inconnue ; jeton expiré/rejoué refusé ; nouveau mot de passe utilisable. | MAIL ; forgot_password_dialog_test.dart | CODE et Edge ACTIVE ; délivrabilité, expéditeur et appareil NON VÉRIFIÉS. M02/M09. |
| A11 / REC-A11 | Créateur/membre ; obligatoire | Version et date des acceptations conservées ; textes accessibles avant soumission ; absence d'accord traité selon contrat M07. | AUTH, legal_documents.dart | M07 spécifie obligations ; aucune conformité déduite du formulaire. |
| A13–A15 / REC-A13 | Titulaire ; obligatoire | Export limité au titulaire ; suppression et historique cohérents ; déconnexion purge cache et abonnement appareil sans fuite au compte suivant. | PERSONAL ; personal_data.test.sql, account_local_data_test.dart | Tests existants ; parcours complet et rétention à préciser M04/M07. |
| A16 / REC-A16 | Pending/suspendu ; obligatoire | Routes directes et API refusent les opérations interdites ; information/support accessibles ; réactivation ne mélange aucun espace. | AUTH, CLUB ; club_subscription_test.dart | CODE/DB ; matrice M04 requise. |
| A17, B12 / REC-B12 | Responsable multiéquipe ; décision | Définir espace autonome par équipe OU hiérarchie club/équipes ; documenter comptes partagés, saisons, droits et unité facturée avant de promettre le multiéquipe. | profiles.club_id, clubs, current_club_id() | DB : pas de table public.teams/squads dans l'inventaire lu. Bloque la promesse multiéquipe, pas preuve d'impossibilité définitive. M00/M02/M04/M06. |
| B05–B06 / REC-B05 | Admin ; configurable | Adresse ≤200 caractères sur une ligne ; quota 1–30 ; nouveau formulaire prérempli ; autres espaces et matchs personnalisés préservés. | CLUB, club_settings_page.dart ; club_settings_page_test.dart | CODE : réglages présents, contrairement à l'audit du 12/11. |
| B07 / REC-B07 | Admin/membre ; configurable | Même instant UI/serveur pour J-n à l'heure choisie, y compris changement d'heure et téléphone dans un autre fuseau. | TIME ; match_window_test.dart | CODE/DB : HOR-01 de #137 encore pertinent pour 00/01 h de bascule. |
| B08–B09 / REC-B08 | Admin/membre ; sept modules | OFF masque les entrées et refuse les écritures pertinentes ; réactivation restitue l'historique ; second appareil relit la configuration. | CLUB ; club_rules_test.dart, club_feature_extension.test.sql | CODE/DB ; 7 modules + 66 règles serveur, dont 2 anciennes clés cachées. Pas seulement 8 règles. |
| C01 / REC-C01 | Admin ; obligatoire | Clôture refusée si match bloquant ; archivage atomique ; titres et bilan cohérents ; nouvelle saison ne duplique ni stats ni membres. | SEASON ; season_archive_atomicity.test.sql | CI partielle ; clôture utilisateur isolée non exécutée. M03/M09. |
| C05–C07 / REC-C05 | Coach/gardien/invité ; socle | Coach hors quota/rotation et terrain, inclus dans disponibilités et vote si éligible ; invité sans compte et historique préservé ; gardien selon poste placé. | SPORT ; coach_squad_membership_test.dart | Contrat coach documenté et chemins à rapprocher ; pas de droit admin déduit de « coach ». |
| C09, F10–F12 / REC-C09 | Joueur/admin ; configurable | Photo unique Type joueur ou Autre ; poste GB prioritaire pour tenue ; même rendu fixe/vidéo/après-match ; ancienne référence toujours lisible. | PHOTO ; player_photo_modes_test.dart, goalkeeper_kit_position_test.dart | CODE : remplace les trois téléversements actuels décrits par l'ancien audit ; objets historiques conservés. |
| D01–D04 / REC-D01 | Admin ; socle | Championnat/amical/entre-nous ; numéro de journée cohérent ; date future, rendez-vous et adresse persistants ; annulation/report visibles. | MATCH ; match_form_page_test.dart | CODE : Coupe absent du modèle relu ; ne pas le promettre sans arbitrage. |
| D08 / REC-D08 | Membre ; agenda optionnel | Abonnement ICS ajoute/modifie/annule le bon événement ; révocation du jeton rend le flux inaccessible ; aucun autre espace. | calendar-feed/index.ts | Edge ACTIVE seulement ; réception agenda réelle à éprouver. M04/M09. |
| D09 / REC-D09 | Admin ; socle | Contrat de suppression distinct du verrou d'édition ; essai avant/après kickoff+24h ; dépendances Live/archives et annulations traitées. | match_deletion_window.dart ; match_deletion_window_test.dart | CODE : délai suppression 24h ; commentaire de pastKickoffError parle encore de non-suppression. Réconcilier avec garde serveur. |
| E07–E11 / REC-E09 | Admin/joueur ; trois modes | +/− exclusivement manuel ; deux deltas concurrents conservés ; retry même request_id sans crédit doublé ; ordre affiché = réponse serveur. | WAIT ; waitlist_consistent_manual_adjustments.test.sql | CODE/DB/CI partiels ; ancienne RPC absolue reste pour compatibilité. ATT-01/02 corrigés dans chemin actuel, retest UI restant. |
| E08, E12 / REC-E08 | Admin ; configurable | Changer de mode rééquilibre les matchs ouverts, conserve choix manuels et ne réécrit pas les matchs gelés ; en mode choix admin quota potentiellement dépassé, l'expliquer. | WAIT ; waitlist_modes.test.sql, waitlist_consistent_manual_adjustments.test.sql | CI ; trigger de rééquilibrage effectif à compléter dans la chaîne de preuves DB. |
| F01–F07 / REC-F04 | Admin ; simulation optionnelle | Simulation n'enregistre/publie rien ; seuls convoqués candidats ; gardien uniquement GB ; aucun doublon ; sans historique signaler les placements à confirmer. | COMPO ; composition_simulation_multiclub_replay_test.dart | CODE/CI ; SIM-01 : résultats explicatifs calculés mais non consommés dans UI repérée. |
| F08–F09 / REC-F08 | Membre/admin ; option | Vidéo composition et fallback fixe fonctionnent sans import individuel ; autoplay et rejeu respectent parents OFF ; erreur média ne bloque pas la fiche. | COMPO/PHOTO ; composition_presentation_test.dart | Mini-clips personnels restent un souhait non livré, distinct du fond stade. M05/M07 droits. |
| G01–G08 / REC-G02 | Coach habilité/admin selon règle ; option Live | Un pilote ; prise de main contrôlée ; ajout tardif sur banc ; remplacements/chrono/formation cohérents ; doublon réseau ne double pas un but ; fin puis compte rendu. | LIVE ; live_single_pilot_and_kickoff.test.sql, live_score_idempotency.test.sql | CODE/DB/CI ; droits pilote coach ou admin selon live_pilot_mode, pas tout admin par défaut. |
| G09–G12 / REC-G12 | Admin et votants ; vote optionnel | Validation ouvre vote ; fin à kickoff + durée club, et non validation + durée ; auto-vote selon règle ; corrections répercutées aux stats sans doublon. | REPORT/VOTE ; sport_motm_vote_model_test.dart | DB : match_motm_closes_at = kickoff + motm_window_hours. Cas validation tardive à jouer. |
| H01–H08 / REC-H04 | Membre ; option pronostics | Fermeture serveur stricte ; refus entre-nous ; barème explicite ; cote utilisée pour points ne dérive plus après gel défini ; archivage ne retire pas un résultat pertinent du modèle. | PRONO ; prediction_scoring_club_rules.test.sql | CODE/DB/CI ; PRO-01/02 et REG-01 de #137 restent à traiter/arbitrer. |
| I01–I08, J01–J09 / REC-I02 | Membre/admin ; options stats/badges | Une correction résultat met à jour stats/classements/récompenses selon politique ; alias ne fusionnent pas deux personnes ; OFF conserve les données ; attribution manuelle réservée admin. | STATS/BADGES ; player_season_statistics.test.sql, badge_admin_access.test.sql | Contrats hérités à détailler par sous-fonction ; pas de succès E2E nouveau. M04/M07. |
| K01–K06 / REC-K01 | Membre/admin aperçu ; option bilan | Vraie clôture produit bilan cohérent ; aperçu signalé fictif ; musique désactivable par utilisateur/règle ; échec audio toléré. | WRAPPED ; season_wrapped_visibility_test.dart | Asset audio présent selon sources actuelles, ancienne mention « absent » périmée ; licence M07 distincte. |
| L01–L12 / REC-L01 | Membre/admin ; préférences | Réception push sur appareils visés ; bonne cible ; opt-out et coupe-circuit appliqués ; notification ouvre le bon match ; aucune répétition imprévue. | PUSH ; push_delivery_integrity.test.sql, service_worker_notification_test.dart | Edge/crons actifs et CI ne prouvent pas livraison téléphone. M03/M09. |
| M05–M07 / REC-M05 | Responsable/payeur ; contrat nouveau | Offre par équipe, pas par joueur ; pilotes gratuits identifiés ; montant/échéance/acceptation explicites ; pas de débit implicite après essai. | SUB ; club_subscription.test.sql | DB : défaut essai 30 jours et prix 1000 cents/joueur ; incompatible avec dernier arbitrage. M06/M07 → M02. |
| N01–N15 / REC-N01 | Tous rôles ; intégrité obligatoire | Aucune fuite interespaces ; restauration DB/Auth/Storage démontrée ; version app/schéma tracée ; capacité mesurée et limites connues. | QA et matrice sécurité existantes | Exigences transversales conservées ; responsables M04/M09, recette M03 ; ne valent pas certification. |

### Sources des chemins abrégés

Tous les chemins sont relatifs à la racine du dépôt audité ; tests .dart sous test/ et .sql sous supabase/tests/database/.

- AUTH : lib/features/auth/, lib/app/router/auth_redirect.dart ; CLUB : lib/features/club/data/club_repository.dart, lib/features/admin/presentation/club_settings_page.dart.
- MAIL : lib/features/auth/presentation/auth_sign_in_page.dart → lib/features/auth/data/account_email_repository.dart → supabase/functions/account-email/index.ts → lib/features/auth/presentation/forced_password_change_page.dart.
- PERSONAL : lib/features/profile/data/personal_data_repository.dart, lib/core/storage/account_local_data.dart.
- TIME : lib/core/utils/match_window.dart, private.match_features_open_at, private.match_predictions_open_at.
- SEASON : lib/features/admin/presentation/admin_season_section.dart ; SPORT : lib/features/sports_management/.
- PHOTO : lib/core/storage/player_photo_mode.dart, lib/core/widgets/kit_portrait.dart, docs/changes/photo-unique-modes-20261114.md.
- MATCH : lib/features/matches/ ; WAIT : lib/features/sports_management/data/sport_waitlist_repository.dart et presentation/admin_waitlist_page.dart, public.admin_adjust_waitlist_manual_count.
- COMPO : lib/features/sports_management/domain/composition_simulation.dart, presentation/admin_squad_plan_page_state.dart et admin_squad_plan_page_composition.dart.
- LIVE : lib/features/match_live/, private.is_match_live_pilot_coach ; REPORT/VOTE : lib/features/sports_management/data/sport_match_finalization_repository.dart, sport_motm_vote_repository.dart.
- PRONO : lib/features/predictions/, public.calculate_match_odds_v5, public.upsert_match_odds_v4.
- STATS/BADGES : lib/features/statistics/, lib/features/badges/ ; WRAPPED : lib/features/season_wrapped/.
- PUSH : lib/features/notifications/, lib/features/preferences/, supabase/functions/send-push/, web/sw.js.
- SUB : lib/features/admin/presentation/club_subscription_section.dart, lib/features/club/data/club_subscription.dart, private.club_subscription_summary.

## 4. Règles temporelles à conserver et éprouver

| Transition | Contrat actuel relevé | Cas limite de recette |
|---|---|---|
| Prochain match / accès modules | J-n à heure club, défaut J-6 midi Paris ; accès effectif min(standard, ouverture disponibilité anticipée) | Avant/à/après ; ouverture disponibilité tardive ne retarde pas l'accès standard ; distinguer carte « prochain » et accès fiche. |
| Prono ferme / Live ouvre / gel | Frontière commune par défaut T-15, pilotée par prediction_close_minutes | Comparer chaque garde serveur et client ; 0 et 240 min ; Live OFF n'autorise pas un prono tardif. |
| Disponibilité vs gel effectif | Peut encore changer après gel ; ne pas promettre une promotion automatique en période gelée | Désistement T-5 puis Live, présence réelle et historique distincts. |
| À valider | Live actif autoritaire ; sans Live, durée prévue + marge 15 min ; état terminé/archivé prioritaire | Pause prolongée, retour réseau, fin anticipée. |
| Entre nous | Modèle client considère terminé au kickoff ; cron finish-due-internal-matches | À kickoff, absence de pronostics externes, compositions deux équipes. |
| Vote | Après validation jusqu'à kickoff + motm_window_hours, défaut 24h | Validation après fermeture théorique, égalités, coach votant. |
| Correction | correction_window_hours après validation, défaut 24h | Dernière seconde, badges/classements affectés. |
| Suppression | Code client distinct : avant kickoff+24h | Garde RPC à confirmer ; ne pas déduire d'un commentaire périmé. |
| Saison/bilan | Archivage conditionnel, attribution titres et jobs bilan | Match encore ouvert, échec job, relance et absence de doublon. |

## 5. Backlog référencé et coordination

| Réf. M01 | Sujet / qualification | Priorité de travail et propriétaire | Critère de clôture |
|---|---|---|---|
| M01-EC01 | Modèle commercial obsolète dans SQL/UI | Avant offre ; M06/M07 cadrage, M02 réalisation, M03 recette | Remplacer défaut joueur/30 jours selon contrat équipe et pilotes ; tests états abonnement et absence de débit surprise. |
| M01-EC02 | Unité équipe et comptes multiéquipe non spécifiés | Avant promesse multiéquipe ; M00/M01/M02/M04 | Choix d'architecture documenté, critères et coûts validés ; 2 équipes du même club testées sans mélange. |
| M01-EC03 | Livraison mail non démontrée malgré parcours codé | Avant pilotes ; M02/M09, M03 | Envoi boîte test autorisée, expéditeur/redirection vérifiés, reset/confirmation/expiration réellement joués. |
| M01-EC04 | PRO-01 : cote encore modifiable après fermeture | P1 proposée ; M02/M03 ; reprendre #137 sans ticket concurrent | Gel spécifié et testé avant/à/après fermeture et pendant Live ; pas d'altération des points attendus. |
| M01-EC05 | PRO-02 : modèle cotes filtre seulement termine | P1 proposée ; M02/M03 ; #137 | Même résultat archivé conserve contribution ; cas entre-nous explicitement traité. |
| M01-EC06 | SIM-01 : confiance et raisons simulation invisibles | P1 proposée ; M02/M05 ; #137 | Lecture historique échouée distinguée de vide ; avertissement et placements à confirmer visibles. |
| M01-EC07 | HOR-01 : calcul heure Paris basé sur midi | P2 proposée ; M02/M03 ; #137 | Accord UI/SQL 24 heures sur dates de bascule ; politique heures ambiguës/inexistantes explicite. |
| M01-EC08 | REG-01 : barème rétroactif et titres archivés | Arbitrage M00/M01 avant changement ; M02/M03 | Politique retenue et cohérence classements/titres démontrées. |
| M01-EC09 | ATT-01/02/03 de #137 après correctif #138 | Correctif présent, recette réelle ouverte ; M03 | Ordre immédiat, deux admins, retry perdu, changement mode par seule RPC publique ; pas de recalcul privé ajouté au test. |
| M01-EC10 | Suppression : commentaire vs garde dédiée | À examiner M01/M02/M03 | UI/RPC et aide racontent la même fenêtre, test avant/après. |
| M01-EC11 | Anciennes photos, audio, modules, routes et états docs | Documentation M01, consolidation centrale M00 | Écarts sourcés, historique conservé ; pas de réouverture de correctifs déjà intégrés sans reproduction. |
| M01-EC12 | Exhaustivité commandes et formulaires non atteinte | Prochain lot M01 puis M03 | Chaque contrôle visible identifié, rôle/condition/effet/erreur/test ; tous les IDs historiques détaillés. |

Les écarts PRO/HOR/SIM sont reconfirmés par lecture des chemins concernés, pas reproduits en session utilisateur. La définition serveur de calculate_match_odds_v5 conserve le filtre termine ; upsert_match_odds_v4 ne contrôle que le statut a_venir. Les fonctions de crédit automatique lues retournent 0 ; le cron waitlist-credit est absent de la liste active. Aucune de ces observations n'autorise une mutation.

M02 : garder vos lots comptes/invitations/récupération F2-00/F2-09 et scénarios T01–T05 ; les IDs A01–A10 restent compatibles, pas de renumérotation. M03 : réutiliser les critères REC ci-dessus et distinguer seed de #142 et véritable geste Flutter. M04/M07 : surveiller contact_email et jetons, motifs d'absence, portraits/vidéos, profils mineurs, votes/pronos, export et suppression. M09 : réception email/push, crons, médias et restauration.

## 6. Preuves réellement consultées et limites

- [Flutter CI main](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196815), job 132981054585 : journal lu, **1290 tests passés**, analyse et build réussis. Suite antérieure à ce rapport, aucune relance locale revendiquée.
- [SQL/RLS main](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196869), job 132981054943 : étapes base isolée, concurrence attente, pgTAP et lint réussies ; 176 résumés Files=1 / 2602 assertions relevées dans le journal. Ce total décrit ces résumés, pas toute la couverture Deno/concurrence.
- [Publication](https://github.com/samihchaa-wq/Application-football-/actions/runs/43770267267) et [sauvegarde](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769955168) réussies sur le même SHA ; pas de preuve de restauration ni de SHA effectivement affiché par un téléphone.
- SELECT métadonnées : 54 migrations enregistrées (max_version 20261121000000, **pas une preuve d'alignement par simple maximum**), 8 Edge ACTIVE, 258 signatures de fonctions public et 290 private ; 66 règles, 11 crons actifs. Aucun enregistrement de personne publié.
- [Saison #142](https://github.com/samihchaa-wq/Application-football-/issues/142) et commentaires lus : des données ont été injectées puis rectifiées dans un autre travail ; ne pas réutiliser les 132 pronos initiaux comme preuve de parcours réel. Les limites de publications historiques après kickoff et l'absence de recette iPhone restent explicites.
- [Audit automatismes #137](https://github.com/samihchaa-wq/Application-football-/pull/137) lu sur son SHA c05068719d6d6e700e1454c57720ac00270027d7 ; ne pas le traiter comme état corrigé ou déployé de tous ses écarts.
- HANDOFF dit déploiement manuel ; auto_release_commercial.yml est déclenché sur push main et orchestre sauvegarde/migrations/publication. **Aucune fusion ici.**

Aucun test Flutter local exécuté (SDK absent du PATH au contrôle), aucune saison jouée, aucun vrai JWT HTTP ni upload/export/suppression, aucun push/email déclenché dans M01, aucun essai iPhone/Android. Aucune écriture Supabase, aucune modification AS Grinta original ou Carte soirée, aucun changement applicatif.

## 7. Proposition de gel pilote, non décision

Conserver socle et modules actuellement trouvés, football à 11, expérience existante, données historiques et réglages club. Ne pas annoncer Coupe, clips individuels, formats 5/8 ou hiérarchie multiéquipe comme déjà livrés. Ces demandes restent au registre pour arbitrage M00, pas supprimées du projet.

Prochaine action M01 : décomposer le lot accès/comptes puis le cycle match en commandes élémentaires, compléter chaque ID hérité, relier les tests exacts et transmettre à M03. La clôture complète M01 exige encore cet inventaire et une revue de couverture ; **ce premier lot n'est pas un GO pilote**.
