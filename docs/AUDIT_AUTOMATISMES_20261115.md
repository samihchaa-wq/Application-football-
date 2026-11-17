# Audit des automatismes Petit Filet — 15 novembre 2026

## Périmètre et niveau de preuve

Demande : enquêter sur « Simuler la compo », les pronostics et la liste d'attente, ainsi que leurs dépendances importantes. Rapport d'enquête uniquement : aucune correction métier, migration, fusion ou publication.

- Dépôt commercial : `samihchaa-wq/Application-football-`.
- `main` lu et revérifié : `39d4bccfaca60cdaece81ca5f5e864355b922a93`.
- Base commerciale attendue : `jvxkhgdopslctpcjrhzw`. La connexion Supabase de cette session refuse la lecture de ce projet. Aucun autre projet n'a été interrogé par SQL. Les fonctions effectivement installées, réglages, crons actifs et données en production restent **NON VÉRIFIÉS**.
- Aucun accès aux données d'AS Grinta original ; aucune modification de son dépôt, de sa base ou de son site.
- Les constats ci-dessous sont issus du chemin Flutter et des définitions SQL finales du dépôt, pas simplement d'anciennes migrations prises isolément.

### Preuves de tests consultées

Journaux réellement lus, pas seulement pastilles vertes :

- [Flutter CI 43631600481](https://github.com/samihchaa-wq/Application-football-/actions/runs/43631600481), job `132559235501` : **1 275 tests réussis**, analyse et build Web réussis.
- [Supabase business and RLS tests 43631600498](https://github.com/samihchaa-wq/Application-football-/actions/runs/43631600498), job `132559214811` : **174 fichiers SQL, 2 569 assertions pgTAP**, tous PASS ; pile isolée démarrée, migrations rejouées et lint exécuté.
- SHA de ces exécutions : `0b4b15bcf57b42ae6367fa847817c30648f48343`, PR #132 fusionnée. Comparaison Git avec `main` audité : **aucune différence** dans `supabase/`, `lib/features/sports_management/`, `lib/features/predictions/`, `lib/core/club/` et `lib/core/utils/match_window.dart`. Ce sont donc des preuves pertinentes pour les moteurs audités, sans prétendre que tout le HEAD actuel a été retesté ici.
- Dans ces journaux : 9 604 combinaisons de calcul des points, 120 cas de fenêtre des pronostics, 27 tests dont le chemin contient `composition_simulation`, tests des trois modes d'attente, désistements, publication de composition, séparation de clubs et saison fictive à deux clubs.
- Les comptes de tests décrivent une couverture existante ; ils ne prouvent pas que tous les scénarios métier possibles sont couverts.

L'exécution Flutter locale a été bloquée par le contrôle automatique après une tentative d'accès aux métadonnées de l'environnement. Elle n'est pas comptée comme un test exécuté et n'a pas été relancée par une autre voie. Aucune nouvelle exécution de la suite Flutter/SQL n'est revendiquée dans ce rapport. Une vérification arithmétique indépendante des horaires a été faite avec Python standard et `zoneinfo` ; elle ne remplace pas l'exécution du code Flutter.

## Résultat principal

Les trois moteurs sont implémentés et disposent d'une couverture substantielle. Sept écarts ou risques ressortent de la lecture du chemin réel, plus un comportement de barème à arbitrer. Aucun incident de production précis n'est attribué à ces constats sans observation de la base.

| ID | Sujet | Priorité proposée | Qualification |
|---|---|---|---|
| ATT-01 | Ordre affiché périmé après +/− | P1 | Écart certain du chemin client/serveur |
| ATT-02 | Modification de compteur perdue entre deux admins | P1 | Risque de concurrence établi par le contrat RPC |
| ATT-03 | Nouveau mode d'attente sans recalcul immédiat des effectifs publiés | P1 | Écart certain du chemin serveur |
| SIM-01 | Historique indisponible et placements incertains non signalés | P1 | Repli silencieux et explications non affichées |
| PRO-01 | Cotes recalculables après fermeture des pronostics | P1 | Absence de gel dans le chemin SQL |
| PRO-02 | Matchs archivés exclus du modèle de cotes | P1 | Filtre SQL certain ; impact à reproduire sur base isolée |
| HOR-01 | Heure d'ouverture personnalisée incorrecte à certaines bascules d'heure | P2 | Calcul identifié, comparaison indépendante donnant ±60 min |
| REG-01 | Barème rétroactif, y compris sur les saisons anciennes | Décision métier | Comportement explicite, pas un bug présumé |

P1 : traiter avant une utilisation pilote autonome ; P2 : cas plus rare à corriger avant généralisation. Ces priorités ne constituent pas une preuve de gravité d'un incident en ligne.

## 1. Simuler la composition

### Fonctionnement effectif

Sources : `composition_simulation.dart`, `admin_squad_plan_page_composition.dart`, `admin_squad_plan_page_state.dart`, `match_composition_repository.dart`, `player_position_history.dart` et migration `20261117000000_historique_cotes_et_postes.sql`.

1. Le candidat doit être convoqué dans l'effectif courant de l'éditeur.
2. Le dispositif choisi est conservé ; le moteur cherche une répartition globale des joueurs sur ses postes.
3. L'ordre des critères est : maximiser les joueurs du club titularisés ; compléter avec des invités ; limiter les placements hors des postes crédibles ; favoriser les remplaçants de leur dernière participation ; maximiser l'affinité avec les postes ; départager par le nombre de matchs commencés sur le banc.
4. Les gardiens déclarés jouent uniquement dans les buts. Sans gardien, le poste reste vacant.
5. Les postes proviennent des titularisations enregistrées dans l'application et de l'historique saisi, via l'identité canonique du joueur. Les saisons récentes pèsent davantage ; la demi-vie est de deux saisons.
6. Un joueur sans historique peut être choisi, mais sa compatibilité avec le poste n'est pas connue. À égalité complète, noms puis identifiants départagent de manière déterministe.
7. La simulation modifie le brouillon local. Elle n'appelle aucune RPC d'enregistrement ou de publication ; l'administrateur doit enregistrer. Le réglage permet de désactiver ce bouton.

**Ne pas confondre les compteurs :** l'historique du banc utilisé ici correspond aux matchs commencés remplaçant. Les +1 manuels de la liste d'attente ne sont pas utilisés pour choisir les titulaires.

### SIM-01 — confiance de la proposition invisible

Preuves : `admin_squad_plan_page_state.dart:216–234` ignore l'erreur de lecture de l'historique des postes et retombe sur l'archive. L'archive embarquée commerciale est vide ; `playerPositionArchiveProvider` réaligne cette archive et ne fournit donc pas de profils de secours dans l'état actuel. Le moteur expose `unknownPlacements`, `stretchedPlacements`, `promotedFromBench`, `keptOnBench`, mais ces résultats ne sont consommés par aucun écran dans `lib/`. `_simulateComposition`, à partir de la ligne 338, ne récupère que les placements et l'ordre du banc.

**Scénario :** historique récent inaccessible, archive absente ; la proposition reste possible sans que l'admin sache qu'elle a perdu sa connaissance des postes. Des joueurs inconnus ou hors poste peuvent aussi être proposés sans explication visible.

**Correction proposée :** conserver une aide utilisable, afficher l'indisponibilité des données et les placements à confirmer ; présenter les raisons de rotation. Ne pas inventer de postes ni introduire de données d'AS Grinta.

**Tests à ajouter :** échec RPC d'historique avec archive vide ; distinction entre lecture échouée et historique réellement inexistant ; joueur inconnu ; placement hors poste ; absence de gardien ; vérifier le message affiché et l'absence de publication automatique.

## 2. Pronostics, points et cotes

### Fonctionnement effectif

- Ouverture : J−6 à midi Paris par défaut, ou dès l'ouverture anticipée des disponibilités. Jour et heure sont réglables par club.
- Fermeture : coup d'envoi moins le délai du club, 15 minutes par défaut ; une fermeture explicite peut aussi s'appliquer.
- Serveur : compte actif, match accessible du club, statut à venir, fenêtre ouverte, scores entre 0 et 99. Les matchs « entre nous » sont refusés. Un trigger bloque les nouveaux pronostics quand le module est désactivé.
- Une nouvelle sauvegarde remplace le pronostic existant du même joueur et match. En cas de résultat réseau incertain, le client relit la valeur plutôt que de rejouer aveuglément l'écriture.
- Barème par défaut : mauvais résultat = 0 ; score exact = cote ×2 ; bon résultat avec bon écart ou un score d'équipe exact = cote ×1,5 ; bon résultat seul = cote ×1. Un nul non exact reçoit donc le multiplicateur du bon écart, puisque l'écart vaut zéro.
- Les multiplicateurs sont réglables. Sans cotes, chaque issue vaut 1. Le classement compte les pronostics remplis des matchs terminés/archivés ; les autres joueurs ne lisent pas les pronostics à venir d'un membre.
- Les cotes utilisent la forme du club et les confrontations, avec pondération par récence et bornage limitant les valeurs aberrantes d'un petit historique.

### PRO-01 — fermeture du prono sans gel des cotes

Preuves : `recalculate_upcoming_match_odds_v4` dans `20261111000100_socle_structure.sql:24304` parcourt tout match `a_venir`. `upsert_match_odds_v4:26898` vérifie ce statut mais aucune heure de fermeture, puis remplace les cotes. Les changements d'historique et de règles `odds_*` appellent ce recalcul. La vue des points lit les cotes actuelles, sans photographie liée au pronostic.

**Scénario :** un match reste `a_venir` pendant sa phase Live/avant validation. Après la fermeture de ses pronos, une correction d'un autre résultat, un changement d'historique ou de réglage de cotes peut modifier ses cotes. Les points futurs peuvent alors différer des cotes observées lors de la fermeture.

**Correction proposée :** définir un gel au plus tard à la fermeture, protéger tous les chemins d'écriture des cotes et conserver la valeur utilisée pour les points. La politique avant fermeture reste à décider : cote finale commune ou cote prise à l'enregistrement.

**Tests à ajouter :** changement d'historique/règle avant fermeture, exactement à la fermeture, pendant le Live et après validation ; contrôle d'absence de modification de la cote gelée et des points associés.

### PRO-02 — archiver un résultat le retire du modèle de cotes

Preuves : `20261118000000_cotes_bornees_petit_historique.sql:62` et `:104` ne sélectionnent que `m.status = 'termine'`, contrairement à la lecture des points/postes qui accepte aussi `archive`. `archive_match` change précisément `termine` en `archive`. Le trigger `trigger_recalculate_upcoming_odds_v3` réagit à ce changement et relance les cotes.

**Conséquence déduite :** un résultat sportif identique peut cesser de compter simplement parce qu'il a été archivé. Ce n'est pas le même mécanisme que les matchs importés dans `historical_match_scores`, qui restent inclus.

**Correction proposée :** inclure les matchs terminés ET archivés, et vérifier les matchs « entre nous » pour qu'ils n'alimentent pas les cotes externes. Ajouter un cas avant/après archivage où les cotes doivent rester identiques à résultats et référence constants. Ce scénario n'a pas été exécuté sur PostgreSQL pendant cette enquête.

### REG-01 — changement rétroactif du barème

La migration `20261114002000_bareme_pronostics_club.sql` le dit explicitement et la vue l'applique : changer un multiplicateur recalcule les points des matchs passés, toutes saisons confondues. Ce comportement est testé. Ce n'est donc pas classé automatiquement comme une anomalie.

**Risque métier :** déplacer un ancien classement alors que les titres de saison ont déjà été attribués et enregistrés. Décider si un barème doit être figé par saison ou si la rétroactivité est voulue ; dans ce dernier cas, vérifier la cohérence des titres. Recommandation : barème figé pour les saisons archivées, modification annoncée pour la saison en cours.

## 3. Liste d'attente

### Fonctionnement effectif

La migration finale `20261118001000_waitlist_credits_admin_only_final.sql` remplace les implémentations antérieures : elle supprime le cron `waitlist-credit` et neutralise les fonctions d'attribution, de rattrapage et de retrait automatique. Les compteurs existants sont conservés. Le test SQL correspondant a réellement passé en CI. **Cela prouve le contrat du dépôt et de la base isolée ; pas l'application de cette migration en production.**

Nettoyage de réglages à prévoir : le catalogue conserve `waitlist_cutoff_days` et `waitlist_cutoff_hour` avec des libellés parlant de crédit automatique, alors que l'attribution est neutralisée. Ne pas les présenter comme une commande d'attribution automatique actuelle.

| Mode | Convocation automatique |
|---|---|
| Présence l'an dernier, défaut | Rang de saison décroissant : le bas de la liste est convoqué en premier. Le rang est construit avec +1 manuels, puis présences précédentes et noms. |
| Ordre d'arrivée | +1 manuels décroissants, puis réponse « disponible » la plus ancienne. |
| Choix admin | Tous les disponibles sont automatiquement convoqués ; l'admin place les personnes à écarter en attente. Le quota peut donc être dépassé dans ce mode. |

- Les choix manuels d'effectif sont préservés, sauf notamment désistement ou inéligibilité.
- Un désistement avant le gel entraîne un recalcul ; un retour suit l'ordre et les choix encore applicables, sans droit général à récupérer sa place.
- Le moteur ne recalcule plus à partir de la fermeture avant match. Une disponibilité reste modifiable jusqu'au coup d'envoi : entre ces deux instants, « absent » et « convoqué » peuvent coexister dans les données gelées ; le Live et les décisions admin doivent traiter la présence réelle. Ce comportement doit être expliqué et retesté de bout en bout, pas interprété comme une promotion automatique garantie à T−5.
- Les coachs n'occupent pas les places de la rotation ; les matchs « entre nous » convoquent les présents.

### ATT-01 — +/− change le serveur mais pas l'ordre de l'écran

Preuves : `AdminWaitlistPage._adjustWaitlistCount:62` change seulement le compteur local puis appelle une RPC `void`, sans relecture ni réordonnancement. La RPC `admin_set_waitlist_manual_count` recalcule pourtant le rang puis les effectifs à venir. `copyWith` conserve le rang initial. Un rafraîchissement manuel est nécessaire pour retrouver l'ordre du serveur.

**Conséquence :** l'admin peut lire un ancien ordre et se tromper sur le prochain convoqué, alors que les données serveur suivent déjà le nouveau classement.

**Correction proposée :** retourner/recharger l'état autoritaire après chaque modification réussie, avec gestion des échecs réseau ambigus. Test : ajouter un +1 qui change réellement le rang, puis vérifier l'ordre immédiatement sans tirer pour rafraîchir.

### ATT-02 — +1 perdu si deux admins modifient le même joueur

Preuves : la RPC prend une valeur absolue `p_count`, verrouille la ligne, puis écrit cette valeur. Aucun compteur attendu/version ni delta n'est transmis. Le verrou sérialise les écritures, mais ne corrige pas une valeur calculée sur une ancienne lecture.

**Scénario logique :** les deux écrans lisent 2 ; chaque admin clique une fois sur + ; les deux envoient 3 ; le résultat est 3 au lieu de 4. Même sans simultanéité parfaite, un écran resté ouvert peut écraser une modification récente. Ce scénario n'a pas été joué contre la base en ligne.

**Correction proposée :** RPC de delta atomique pour les boutons +/−, ou refus explicite sur version périmée ; préserver autorisation admin, compteur non négatif et journal. Tests nécessaires avec deux connexions réelles, ainsi que double clic et réponse réseau perdue.

### ATT-03 — changement de mode non appliqué immédiatement aux effectifs publiés

Preuves : `admin_set_club_rule` dans `20261111070000_regles_club.sql:137` ne fait qu'écrire le réglage. Les triggers ajoutés pour `club_rules` signalent le changement aux clients et recalculent les clés `odds_*`, sans rééquilibrage d'attente. `get_match_convocations` ne recalcule qu'un effectif en brouillon. Le test `waitlist_modes.test.sql` appelle lui-même `private.recompute_match_convocations_internal` après le changement de mode.

**Scénario :** effectif déjà publié, modification du mode vers l'ordre d'arrivée : le paramètre est nouveau mais les convocations restent celles d'avant jusqu'à une action qui les recalcule.

**Correction proposée :** appliquer le mode aux matchs encore ouverts dans la même opération serveur, en conservant les décisions admin ; présenter les effets et éviter une rafale de notifications intermédiaires. Test obligatoire via la seule RPC publique de réglage, sans recalcul privé ajouté artificiellement par le test.

## 4. Autre mécanisme important : horaires réglables

### HOR-01 — conversion « midi Paris » réutilisée pour toute heure

Preuves : `matchFeaturesOpenAt:39` utilise l'heure réglable du club mais appelle `_parisOffsetForLocalNoon:187`, qui choisit le décalage pour toute la date selon la situation à midi. Sur la journée de bascule, minuit et 1 h ne suivent pas ce décalage. Le SQL utilise `AT TIME ZONE 'Europe/Paris'`, qui tient compte de l'instant réel.

Vérification arithmétique indépendante avec `zoneinfo`, en reproduisant la décision de décalage du helper :

| Ouverture souhaitée à Paris | Instant correct UTC | Instant déduit du helper client | Écart |
|---|---|---|---|
| 29/03/2026, 00 h | 28/03, 23 h | 28/03, 22 h | −1 h |
| 25/10/2026, 00 h | 24/10, 22 h | 24/10, 23 h | +1 h |
| 28/03/2027, 00 h | 27/03, 23 h | 27/03, 22 h | −1 h |
| 31/10/2027, 00 h | 30/10, 22 h | 30/10, 23 h | +1 h |

Le cas de 1 h présente le même écart ; le midi de ces dates reste correct. Les 48 213 cas temporels verts existants portent sur l'ouverture par défaut à midi, pas les 24 valeurs du nouveau réglage.

**Correction proposée :** conversion de fuseau qui respecte l'heure civile choisie, avec politique explicite pour l'heure inexistante ou doublée ; comparaison UI/SQL pour toutes les heures autorisées, avant/pendant/après bascule.

## 5. Validation restante et ordre proposé

1. Obtenir une lecture de la **seule** base commerciale et comparer définitions installées, registre de migrations, absence du cron de +1, réglages et versions déployées. Ne pas tenter de contourner le refus d'accès.
2. Corriger ATT-01/ATT-02 avec tests d'ordre affiché, concurrence et réseau ; traiter ATT-03 sur le chemin public réel.
3. Corriger PRO-01/PRO-02 avec base isolée et preuve que les points/cotes fermés ne dérivent pas. Arbitrer REG-01 avant toute modification du barème historique.
4. Afficher les limites et raisons de la simulation ; corriger les horaires personnalisés.
5. Recette isolée à deux clubs : plusieurs admins, joueurs/invités/coach, effectif insuffisant/excédentaire, désistement et retour, trois modes d'attente, changements de +1, fermeture, Live, résultat corrigé, archivage et saison suivante.
6. Vérifier séparément les notifications réellement reçues (doublons, bon destinataire, absence d'envoi si module coupé), les tâches planifiées et l'état après perte de réseau. La CI existante vérifie déjà plusieurs contrats d'envoi mais ne prouve pas une livraison sur smartphone.

**Livrable actuel : enquête documentée, couverture CI vérifiée, corrections proposées. Aucun correctif fusionné ni déployé et aucune validation de production prétendue.**
