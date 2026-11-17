# M01 — Lot 03 : cycle match et temporalité Étoile

17 novembre 2026 (Europe/Paris). **Audit en cours, aucun GO pilote.**
Code commercial relu sur main `4ac75c14d077bc2bf8bc6e3278023d0db8948932`. Original AS Grinta et Carte soirée exclus. Complète M01_CONTRAT_FONCTIONNEL.md et le lot comptes #171 ; ne remplace pas les photographies antérieures.

## Conclusion vérifiée : ancrage Étoile

M03 demandait de résoudre AGENTS contre supabase/tests/README.md. La définition courante du dépôt **et celle installée en base commerciale, relue par SELECT le 17/11**, sont identiques :
`private.match_motm_closes_at(match) = matches.kickoff_at + private.club_rule('motm_window_hours')`.

Défaut contractuel : 24h après kickoff, **pas 24h après validation**. Ouverture après validation ; source de la fenêtre distincte de celle de correction du résultat. La migration 20261111070000_regles_club.sql:227 donne cette définition. La définition de ensure_match_motm_election dans 20261112130000_fonctions_desactivees_silencieuses.sql:90 retourne sans créer si closes_at ≤ opens_at. Il faut donc tester la validation tardive sans promettre une nouvelle fenêtre entière.

Le présent lot corrige la phrase contradictoire du README des tests ; aucune migration ni règle métier changée. Les migrations historiques restent immuables.

Exemple à exécuter : kickoff samedi 20h, durée 24h ; validation dimanche 19h → une heure théorique restante. Validation dimanche 21h → ne pas ouvrir jusqu'au lundi 21h. C'est un attendu issu des helpers, **pas un scénario joué** ; contrôler aussi les états et messages finaux par les RPC publiques.

Les helpers serveur relus pour ouverture : match_features_open_at utilise Europe/Paris et jours/heure du réglage ; match_predictions_open_at utilise le minimum entre standard et availability_opens_at. Aucune valeur de réglage individuelle n'a été lue : ne pas présumer que toutes les équipes gardent 24h ou J-6.

## Commandes et critères

IDs parents D/E/F/G/H/I conservés ; chaque sous-ID devient REC-<sous-ID> pour M03. Chaque ligne doit recevoir entrée, attendu/obtenu, SHA/environnement, preuve et retest. **30 scénarios non exécutés en UI/SQL dans ce lot.**
M02 réalise, M03 teste, M04 vérifie les permissions, M01 maintient le contrat. Cycle sportif obligatoire ; simulation, vidéo, Live, Étoile, pronostics et statistiques suivent leurs modules/options. Toutes les écritures doivent refuser autre équipe/mauvais rôle et être éprouvées avec coupure réseau, deux appareils et paramètres hors bornes ; aucun flag OFF n'efface les données.

| Sous-ID | Acteur | Commande | Critère mesurable | Source | Test existant à rapprocher, non relancé ici |
|---|---|---|---|---|---|
| D01-01 | Admin | Créer/modifier rencontre | Type, date future, lieu, quota, tenue et rendez-vous persistants ; refus après verrou selon workflow dédié. | MATCH | match_form_page_test.dart |
| D06-01 | Tous membres | Ouverture fiche | Défaut J-6 midi Paris ; ouverture anticipée des dispos ouvre aussi fiche/compo/prono ; ouverture tardive ne décale pas standard. | TIME | prediction_opens_with_early_availability.test.sql |
| E01-01 | Joueur | Présent/absent | Dernière réponse confirmée par relecture après timeout ; commentaire privé effacé si présent ; pas de faux succès. | AVAIL | match_availability_network_resilience_test.dart |
| E02-01 | Admin | Ouvrir disponibilités | Maintenant/date personnalisée/automatique cohérents client et serveur ; aucun autre espace affecté. | AVAIL | sports_management_availability_workflow.test.sql |
| E03-01 | Titulaire | Indisponibilité | Bornes incluses, chevauchement/report/retrait cohérents ; motif non accessible aux coéquipiers. | AVAIL | player_unavailability_mode.test.sql |
| E05-01 | Admin | Relancer | Non-répondants seulement, préférences et coupe-circuit respectés ; double clic ne double pas livraison. | WAIT | manual_availability_reminder_pause.test.sql |
| E06-01 | Admin | Quota et coach | Coach disponible hors quota et rotation ; invités comptés selon règles ; pas de doublon d'identité. | WAIT | coach_squad_membership_test.dart |
| E08-01 | Admin | Changer mode attente | Trois modes, rééquilibrage des matchs ouverts ; choix manuels préservés ; matchs gelés inchangés. | WAIT | waitlist_consistent_manual_adjustments.test.sql |
| E09-01 | Admin | Ajuster +/− | Delta atomique, request_id réutilisé en retry, réponse autoritaire réordonne ; jamais +1 automatique. | WAIT | waitlist_consistent_manual_adjustments.test.sql |
| E11-01 | Joueur/admin | Désistement/retour | Recalcul avant gel, aucune promesse de promotion après gel ; retour ne récupère pas automatiquement la place. | WAIT | returning_absent_player_follows_waitlist_order.test.sql |
| E12-01 | Admin | Publier effectif | Sélection cohérente, motif d'exception si requis, publication distinguée de composition ; mauvais rôle refusé. | WAIT | effectif_save_keeps_waitlist_automatic.test.sql |
| F01-01 | Admin | Placer/sauvegarder | Un joueur au plus une fois ; titulaires/banc/postes vides explicites ; reprise conserve le brouillon. | COMPO | sports_management_composition_server.test.sql |
| F04-01 | Admin | Simuler | Seuls convoqués, gardien uniquement GB ; aucun enregistrement automatique ; historique indisponible clairement signalé. | COMPO | composition_simulation_multiclub_replay_test.dart |
| F06-01 | Admin | Publier composition | Joueur ne voit que publiée ; gel respecté ; historique et tenue du match conservés. | COMPO | published_composition_follows_effectif.test.sql |
| F07-01 | Admin | Entre nous | Deux équipes sans doublon ; tous présents selon règle ; aucune contamination pronos externes. | COMPO | internal_visual_composition_v3.test.sql |
| F08-01 | Membre | Lire vidéo | Fallback fixe ; pas d'obligation de clip personnel ; autoplay/rejeu respectent flags et appareil. | COMPO | composition_presentation_test.dart |
| G02-01 | Coach/admin habilité | Prendre/reprendre main | Un seul pilote ; heartbeat/release/takeover cohérents ; admin soumis à live_pilot_mode. | LIVE | live_single_pilot_and_kickoff.test.sql |
| G03-01 | Pilote | Début/pause/reprise | Horloge autoritaire après arrière-plan/reconnexion ; double geste n'avance pas deux fois le chrono. | LIVE | match_live_session_test.dart |
| G04-01 | Pilote | Ajouter/corriger but | Même operation_id sans doublon ; buteur/passeur/CSC cohérents ; option coupée refusée côté serveur. | LIVE | live_score_idempotency.test.sql |
| G05-01 | Pilote | Remplacer | Révision connue ; conflit deux appareils visible ; temps et salves cohérents ; entrant tardif sur banc. | LIVE | live_lineup_optimistic_lock.test.sql |
| G06-01 | Pilote | Changer dispositif | Joueurs conservés sans doublon, expected_lineup_revision vérifiée ; pas de réécriture historique implicite. | LIVE | live_formation_change.test.sql |
| G08-01 | Pilote habilité | Fin et récapitulatif | Fin Live distincte de validation finale ; publication cohérente score/présences/buts, retry sans double finalisation. | LIVE/REPORT | match_live_report_handoff.test.sql |
| G09-01 | Admin | Valider compte rendu | Après timeout relire résultat/version ; identité, buts, passes et présence cohérents ; deux admins ne perdent pas silencieusement leurs corrections. | REPORT | finalization_retry_idempotency.test.sql |
| G09-02 | Admin | Corriger résultat | Délai ancré à validation selon correction_window_hours ; stats/badges/classements recalculés sans doublons injustifiés. | REPORT | match_sport_report_write_landed_test.dart |
| G11-01 | Votant éligible | Voter Étoile | Candidat de ce match/équipe, vote personnel selon motm_self_vote, anonymat ; réponse accepted=true requise. | VOTE | sports_management_motm_vote.test.sql |
| G12-01 | Votant | Fermeture Étoile | Clôture kickoff + motm_window_hours ; validation tardive ne redonne pas 24h ; zéro scrutin créé si closes_at ≤ opens_at. | VOTE/TIME | exhaustive_motm_state_space.test.sql |
| G12-02 | Admin | Annuler scrutin | Motif transmis, state=cancelled confirmé ; pas d'action possible par simple membre. | VOTE | motm_private_boundary.test.sql |
| G12-03 | Tous | Module vote OFF | Ni nouvelle élection ni vote ou notification pertinents ; réactivation sans effacement des historiques. | VOTE | motm_module_off.test.sql |
| H03-01 | Pronostiqueur | Frontière prono/Live | Avant/à/après kickoff-délai club ; pas de prono tardif quand Live OFF ; score invalide et entre-nous refusés. | TIME | prediction_window_test.dart |
| I02-01 | Membre/admin | Contrôle aval | Comparer résultat → stats → classement → badges avec calcul indépendant ; correction et archivage sans double comptage. | REPORT | player_season_statistics.test.sql |

### Sources du chemin réel

- MATCH : lib/features/matches/presentation/match_form_page.dart et data/matches_repository.dart.
- TIME : lib/core/utils/match_window.dart ; helpers private.match_features_open_at, match_predictions_open_at et match_motm_closes_at.
- AVAIL : lib/features/sports_management/data/match_availability_repository.dart, confirmMatchAvailabilityWrite et setMyAvailability ; lib/features/unavailability/.
- WAIT : lib/features/sports_management/data/sport_waitlist_repository.dart, publishEffectif/adjustWaitlistManualCount et presentation/admin_squad_plan_page_effectif.dart.
- COMPO : lib/features/sports_management/data/match_composition_repository.dart et presentation/admin_squad_plan_page_composition.dart, domain/composition_simulation.dart.
- LIVE : lib/features/match_live/data/match_live_repository.dart, claimPilot/takeOverPilot/adjustScore/saveLiveLineup/changeLiveFormation/endMatch/publishRecap.
- REPORT : lib/features/sports_management/data/match_sport_report_repository.dart, submit via admin_submit_match_sport_report et confirmWrite/readBack ; sport_match_finalization_repository.dart.
- VOTE : lib/features/sports_management/data/sport_motm_vote_repository.dart, fetch→get_match_motm_vote, castVote→cast_match_motm_vote, cancel→admin_cancel_match_motm_vote.

Les tests SQL cités résident dans supabase/tests/database ; les tests Dart dans test/ à l'emplacement miroir de lib/. Ce sont des liens de couverture **à examiner**, pas une affirmation que chaque test couvre tout le critère. Certains critères (concurrence/perte réseau et appareil notamment) nécessitent une recette complémentaire.

## Points à traiter et transmission

| Réf. | État prouvé / limite | Action et responsable |
|---|---|---|
| M01-CYCLE-01 | Contradiction documentaire ancrage Étoile confirmée | Correction README dans ce lot ; M03 recette kickoff+durée, validation tardive, frontière exacte et module OFF. |
| M01-CYCLE-02 | confirmWrite pour disponibilités/rapport relu ; pas de test réel de timeout | M03 injecte perte d'accusé et vérifie état autoritaire, sans rejouer aveuglément la validation. |
| M01-CYCLE-03 | Simulation et gel traversent plusieurs modules | M02/M03 rapprochent #137 et les correctifs actuels avant réouverture d'un bug ; absence de nouveau défaut reproduit ici. |
| M01-CYCLE-04 | Fin Live, compte rendu et clôture vote sont trois transitions | M03 teste ordre inversé, fin anticipée, validation tardive et absence de doublons stats/badges. |
| M01-CYCLE-05 | Catalogue de commandes du cycle encore partiel | M01 complète dialogues/gestes secondaires, notifications, archives et les autres unités historiques ; pas d'exhaustivité revendiquée. |

M00 : équipes autonomes, 100 €/équipe/an et pilotes adultes à 11 trois mois gratuits restent acquis. Aucune nouvelle décision propriétaire nécessaire dans ce lot.
M03 : ce rapport répond au point d'ancrage temporel du premier rapport de recette #153 ; utiliser les RPC publiques et vérifier l'état réellement rendu, pas seulement le calcul du helper.
M04/M07 : motif d'absence, identité invités, temps de jeu et votes restent à vérifier selon droits et confidentialité.

## Vérifications réellement réalisées

- Lecture de code des repositories et des helpers SQL, inventaire de tests existants.
- SELECT en lecture seule sur le seul Supabase commercial jvxkhgdopslctpcjrhzw : trois définitions de helpers, sans lecture de données personnelles et sans appel métier mutateur.
- python3 -m unittest discover -s tool/tests -p test_recette_traceability.py : **3 tests PASS**. Contrôle de l'outillage de traçabilité, pas validation du cycle.
- Contrôle documentaire avant livraison : unicité des 30 sous-IDs, existence des fichiers tests cités et correction ciblée de l'ancrage dans README.

Aucun nouveau test Flutter/Deno/pgTAP ni parcours utilisateur exécuté ; pas de capture téléphone, mail/push, match créé, écriture distante, migration, fusion ou publication dans ce lot. Le déploiement de cette baseline n'est pas déduit de main. Les tests nouveaux devront porter sur le candidat effectivement présenté aux pilotes.
