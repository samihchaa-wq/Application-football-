# PETIT FILET — PLAN DIRECTEUR DE LANCEMENT 2026–2027

**Édition : 14 novembre 2026 — document de pilotage proposé, non encore approuvé.**  
**Cible : première publication officielle iOS / Android et lancement progressif en mai 2027.**  
**Dépôt concerné :** samihchaa-wq/Application-football-  
**Application d'origine : AS Grinta — consultation en lecture seule ; modification interdite.**

## Mode d'emploi

Ce document est une feuille de route d'exécution, pas un certificat de conformité ni l'ordre de publier. Toute tâche a un responsable, un livrable, des preuves et une porte de validation. L'état « code présent » ne vaut jamais « testé réellement ». Les décisions sensibles (migration, création de compte, dépenses, premiers clients, publication) demandent l'autorisation explicite du propriétaire. Les dates sont des objectifs révisables, pas des garanties.

Statuts : **NON COMMENCÉ / EN COURS / À TESTER / VALIDÉ / BLOQUÉ**. Priorités : **P0** empêche d'accueillir de vrais clients, **P1** indispensable avant boutique ou paiement, **P2** après lancement si sans risque.

## Décisions du propriétaire — validées le 14 novembre 2026

Ces décisions ont été données explicitement pour l'orientation du plan et sont **retenues pour le cadrage V1**. Elles ne constituent pas une approbation des prix, des dépenses, des migrations, des premiers recrutements, des fusions de PR ni de la publication.

| Référence | Choix retenu | Conséquence sur la feuille de route | À préciser |
| --- | --- | --- | --- |
| **DEC-V1-B** — périmètre V1 | **B : fonctions essentielles + options déjà prêtes, nouveautés non essentielles en V1.1** | Prioriser la stabilité, les parcours métier critiques et les fonctionnalités existantes prêtes ; tout ajout non indispensable doit aller dans le backlog V1.1. Les bugs P0/P1 restent à corriger. | Matrice définitive « indispensable / déjà prêt / à reporter », à signer lors de G0. |
| **DEC-OFFRE-A** — modèle commercial | **A : abonnement annuel par club** | Un club souscrit un seul abonnement annuel pour son espace ; ses joueurs ne sont pas facturés individuellement par Petit Filet. Concevoir tarifs et gestion d'accès selon cette logique. | Prix, limites éventuelles, essai, TVA, facturation, renouvellement, paiement et règles stores non arrêtés. |
| **DEC-PILOTE-B** — clubs pilotes | **B : un premier club, puis deux autres progressivement** | Appliquer une ouverture séquentielle A → B → C, avec bilan et feu vert à chaque changement d'échelle. | Clubs, dates et conditions d'accueil réel à confirmer après les portes de sécurité et de droit. |

**Statut de ces trois décisions : APPROUVÉES au niveau du cadrage ; leur exécution reste soumise aux gates et autorisations particulières ci-dessous.**

## Décisions complémentaires du propriétaire — Q01 à Q12, validées le 14 novembre 2026

**Portée :** choix explicites du propriétaire pour la première version commerciale de Petit Filet. Les **12 réponses sont A**. Ils précisent et, lorsqu'ils sont plus exigeants, **prévalent sur la règle antérieure DEC-V1-B** (« fonctionnalités essentielles et options déjà prêtes ») : toutes les fonctionnalités expressément déclarées obligatoires ci-dessous doivent être **développées, testées et livrées**, même si elles ne sont pas encore prêtes.

**Légende :** « impératif V1 » = critère de sortie non reportable ; « V1.1 » = report autorisé seulement pour les fonctions non comprises dans l'engagement Q01–Q12. Le choix de cadrage général V1=B reste valable pour les nouveautés accessoires.

| Décision | Impératif de lancement V1 | Critère de vérification avant GO | Report express en V1.1 / après |
| --- | --- | --- | --- |
| Q01 | **A — Matchs amicaux et championnat** | Types et flux amical/championnat créés, affichés et finalisés correctement ; l'option « coupe » n'est pas proposée comme disponible en V1. | Matchs de coupe, formats de tournoi et gestion avancée associée. |
| Q02 | **A — Module Live complet** | Score, buts, buteurs/passeurs selon réglages, remplacements, compositions, événements, corrections et habilitations ; scénarios réels de concurrence et historique conservé. | Nouveaux outils de Live non préexistants et non demandés pour la V1. |
| Q03 | **A — Compositions avant/pendant/après** | Composition publiée, Live, après-match et historique, avec portraits et ensembles maillots joueur/gardien conformes au match, y compris partage et transitions. | Nouvelles variantes de terrain ou animations supplémentaires non nécessaires aux parcours existants. |
| Q04 | **A — Historique, statistiques et clôture** | Saisie/import manuel de matchs historiques, calculs joueurs/équipe, clôture saison, distinctions et bilan/« Wrapped » complets ; tests de fin de saison sur copie isolée. | Nouveaux types de rapports ou exports avancés absents du produit. |
| Q05 | **A — Portraits et maillots réalistes partout** | Rendu réaliste cohérent sur profil, effectif, fiche, compositions, Live et vidéo ; source du visage inchangée ; patron photo/couronne fidèle ; représentation simple dans Info maillots. | Styles supplémentaires de maillots ou animations purement décoratives. |
| Q06 | **A — Vidéo de composition OBLIGATOIRE** | Vidéo de composition fonctionnelle et visuellement validée sur Web, iOS, Android ; aucun nom AS Grinta dans le public ; contrôle de désactivation par club possible. Son absence bloque la V1, même si la date recule. | Nouveaux montages vidéo ou clips individuels non déjà livrés. |
| Q07 | **A — Pronostics complets** | Cotes bornées, pronostics, points, résultats, verrouillage selon délais, classements et réglages par club testés de bout en bout. | Nouveaux marchés de pronostics ou modes de jeu non existants. |
| Q08 | **A — Tous les badges existants et récompenses** | Catalogue de badges existants, conditions d'attribution, seuils, Étoile du match, votes, classements et récompenses vérifiés en multi-club et en fin de saison. | Nouvelles familles de badges et nouveaux trophées non présents. |
| Q09 | **A — Parité Administration AS Grinta** | Reproduction fidèle des écrans, actions, gestes, états et parcours de l'Administration AS Grinta actuelle ; adaptations UNIQUEMENT nécessaires à l'isolation multiclub, à l'intégrité ou aux droits. AS Grinta consulté en lecture seule. | Fonctions administratives entièrement nouvelles, sans équivalent et sans nécessité V1. |
| Q10 | **A — Tous les réglages des fonctions optionnelles EXISTANTES** | Inventaire exhaustif des fonctions optionnelles déjà présentes ; option par club visible, persistante, applicable dans l'UI ET côté serveur (RPC/Edge), avec dépendances, historique conservé et tests A/B ; contrôles de sécurité non désactivables. | Réglages de nouvelles fonctions non encore présentes ; paramètres sans utilité métier établie. |
| Q11 | **A — Notifications push natives et e-mails** | Push iOS via APNs et Android via FCM ou solution homologuée, ainsi que les e-mails nécessaires ; test de réception, désactivation, déduplication, liens, permissions et absence de fuite interclub sur vrais appareils. | Canaux additionnels non essentiels (SMS, intégrations messageries, campagnes marketing). |
| Q12 | **A — Inscription et onboarding autonomes** | Un club inconnu crée son compte, son club, les invitations, les rôles, une saison et ses réglages sans intervention obligatoire de l'éditeur ; tests nouveaux clubs, erreurs et aide en libre-service. | Onboarding assisté premium et automatisations commerciales avancées non indispensables. |

### Contrats métiers transversaux V1 à ne pas perdre

1. **Maillots :** configuration initiale d'**un seul ensemble** par club, avec possibilité d'en créer **autant que nécessaire** ; chaque ensemble associe tenue des joueurs et du gardien, couleurs et motif. L'édition des ensembles doit être intégrée à un **menu déroulant dans Réglages**, cohérent avec les autres menus. L'administrateur choisit la tenue du match ; le choix doit suivre **Info maillots, compositions avant/pendant/après, Live, vidéo, historique et portraits concernés**, sans changer rétroactivement les snapshots figés. Une interface simple est suffisante pour **Info**, contrairement aux portraits réalistes. **État réel à tester** : un document du 13/11 signale encore la limite technique de trois tenues.
2. **Photos des joueurs :** les joueurs chargent librement leurs propres photos, notamment sur fond transparent ; recadrage avec patron maillot et **vraie couronne** de composition ; le visage et la photo source restent intacts, sans incrustation permanente du maillot. Le rendu choisi par le club s'applique à l'affichage dans les surfaces prévues. Tester transparence, alignement, silhouette et formats réels.
3. **Vidéo :** le moteur et la vidéo de composition font obligatoirement partie de la V1 (**Q06=A**) ; l'administrateur peut toutefois désactiver **son usage dans son club** (**Q10=A**). Une fonction livrée et paramétrable peut être inactive pour un club sans être exclue du produit. Suppression de toute inscription « AS Grinta » du public du stade ; aucun texte de remplacement.
4. **Liste d'attente :** **aucun +1 automatique**, seuls les administrateurs gèrent les crédits manuellement. Ce contrat reste en vigueur même avec le Live complet et tous les réglages.
5. **Administration :** « exactement la même » signifie identité visuelle et fonctionnelle maximale avec l'Administration récente d'AS Grinta, **sans recopier son contexte mono-club, ses secrets ni ses données**, et sans affaiblir les règles Supabase multiclubs.
6. **Réglages :** « toutes les fonctionnalités optionnelles existantes » ne signifie pas rendre désactivables la sécurité, les autorisations, le RGPD, les sauvegardes, l'intégrité des données ou les obligations des boutiques. Faire l'inventaire des fonctions réellement optionnelles et prouver qu'une option désactivée l'est également **côté serveur**. Préserver l'historique.
7. **Coupe :** **Q01=A** reporte explicitement le type « coupe » à V1.1. Masquer toute promesse ou sélection inopérante en V1 ; les rencontres existantes ne doivent pas être corrompues par le report.
8. **Autonomie :** l'abonnement annuel **par club** (DEC-OFFRE-A) et l'onboarding autonome (Q12=A) coexistent. L'inscription et la configuration du club ne doivent pas exiger une intervention manuelle permanente ; la souscription/paiement et les autorisations commerciales restent à concevoir et valider séparément.
9. **Sécurité et tests :** ces 12 choix sont des engagements de **périmètre**, pas une déclaration de fonctionnalités déjà testées ou publiées. Aucun P0/P1 ouvert, aucun accès interclub non autorisé ni défaut de récupération des données ne peut être justifié par une demande de lancement rapide.

### Registre des contradictions et arbitrages

| Sujet | Contradiction / historique | Arbitrage retenu maintenant | Effet sur la trajectoire |
| --- | --- | --- | --- |
| **V1=B versus 12 choix A** | « Essentielles et options déjà prêtes » pouvait autoriser à reporter des fonctions inachevées. Q02–Q12 exigent pourtant de nombreuses fonctions complètes. | **Q01–Q12 sont prioritaires** : seule une nouveauté accessoire non listée peut être reportée en V1.1. | V1 plus large et plus coûteuse en QA ; date mai 2027 **conditionnelle**. |
| **Vidéo facultative vs obligatoire** | Le gel V1 et le précédent QCM recommandaient de ne conserver la vidéo que si prête. | **Q06=A : vidéo obligatoire**, sans possibilité de la reporter pour tenir la date ; son **activation par club** reste facultative. | Préparer iOS/Android et tests média dès la recette ; retarder la publication si nécessaire. |
| **Maillots uniquement Info / photos libres vs habillage généralisé** | Anciennes demandes et passages historiques de l'issue #67 limitaient les PNG à Info et écartaient le maillot des portraits. Décision ultérieure sur patron et compositions, PR #111 et Q03/Q05 confirment le rendu réaliste étendu. | **Dernières décisions Q03/Q05 + contrat maillots du 13/11** : habillage visuel sur surfaces prévues, photo d'origine libre et non modifiée, rendu Info schématique. | Ne pas réintroduire l'ancien contrat « Info seulement ». |
| **Trois tenues fixes vs ensembles illimités** | Le socle historique codait trois tenues, tandis que la décision ultérieure demande une tenue initiale et des ajouts illimités, avec choix via menu déroulant. | **Illimité et un seul ensemble initial en V1**, chacun avec tenue gardien associée, choix par match. | Vérifier modèles, RPC, snapshots, migrations à préparer dans PR séparée ; **ne rien appliquer en base** sans accord. |
| **« Exactement AS Grinta » vs multiclub** | L'Administration originale est mono-club et ses anciennes opérations ne conviennent pas toutes telles quelles. | **Q09=A** pour la parité d'usage, mais sécurité multiclub et données fictives **priment** sur la copie littérale. | Revue UI de référence + tests d'autorisations nécessaires. |
| **Réglages partout vs règles incontournables** | « Toutes les fonctionnalités optionnelles » pourrait être compris comme « absolument tout peut être désactivé ». | **Q10=A** sur le catalogue des fonctions facultatives **existantes uniquement** ; les contrôles de sécurité/données et obligations légales sont inamovibles. | Inventaire exhaustif, cas limites et tests UI/serveur par club. |
| **Types de match** | Issue #101 notait l'absence de « coupe », tandis que l'ambition d'une gestion de saison intégrale pouvait laisser croire aux coupes. | **Q01=A** : amicaux et championnat V1, coupe V1.1. | Clarifier interface, aide, tests et backlog. |
| **Objectif mai 2027 vs qualité obligatoire** | Le calendrier prévoyait mai 2027 sous réserve ; Q06 accepte un retard pour la vidéo et Q02–Q12 imposent une validation exhaustive. | **La qualité, le périmètre déclaré et les gates GO/NO-GO priment sur mai 2027.** | Ne pas annoncer de date ferme de sortie, réévaluer le chemin critique chaque semaine. |

**Aucune ambiguïté résiduelle ne donne le droit de modifier AS Grinta original, de déployer, de dépenser ou de fusionner.** Les questions techniques non résolues deviennent des tâches de validation, pas des changements arbitraires de décision.

### Définition de « terminé V1 » pour chaque ligne Q01–Q12

- **Spécifié** : interactions, règles métier, comportement lors d'une option désactivée et données historiques définis.
- **Codé** : Flutter/SQL/Edge concernés avec tests ; si une migration devient nécessaire, elle est proposée séparément et non exécutée implicitement.
- **Intégré** : comportement vérifié après fusion et environnement conforme, sans modifier l'original AS Grinta.
- **Testé** : résultat écran **ET serveur**, tests interclubs A/B, appareils iOS/Android/Web adaptés et historique après changement.
- **Accepté** : M03/M04/M05 selon risque, revue du propriétaire pour le visuel/Administration, et gate GO approuvé.
- **Publié** : SHA et version réellement en service, distincts de la seule présence dans GitHub.

## 1. Photographie vérifiée le 14 novembre 2026

- Branche main : commit 7f28d9eb84bcea4e5c811f5c9c182271fbf15e1a, CI Flutter et déploiement Cloudflare verts. Branche non protégée.
- PR #115 sur le rendu maillot : ouverte ; CI Flutter en cours au dernier contrôle. PR #114, #113, #112 : fusionnées.
- Supabase commercial application-football (région Paris, projet jvxkhgdopslctpcjrhzw) : actif, 61 tables public avec RLS, 2 clubs et 4 matchs ; 51 migrations inscrites, 8 Edge Functions. Il existe des éléments de test, pas une saison complète prouvée.
- Advisor sécurité : 164 alertes WARN sur fonctions SECURITY DEFINER exécutables par authenticated (à examiner fonction par fonction ; pas 164 failles démontrées), une alerte sur protection mots de passe compromis, une INFO RLS sans policy dans le schéma privé.
- Le registre QA recense 164 fonctionnalités métier et une saison scénarisée de 31 rencontres dont 1 annulée ; les parcours complets sont explicitement « NON VÉRIFIÉS ».
- Le dépôt expose web/ mais pas de répertoires android/ ni ios/ à la racine ; pubspec.yaml porte encore le nom technique « as_grinta » et la description « Application officielle ASG. » ; analyser tous les identifiants hérités avant la publication native, sans renommage aveugle des imports.
- Les modèles légaux contiennent des champs à compléter. Les paiements Stripe ne sont pas opérationnels. Le dossier de pilote réel n'est pas exécuté.

**Verdict initial : NO-GO pour stores commerciaux et clubs réels.**

## 2. Définition du premier lancement (MVP commercial)

**Décisions DEC-V1-B et Q01–Q12 :** la première publication contient **obligatoirement les douze familles explicitement retenues**, y compris vidéo, Live, portraits réalistes, Administration à parité et réglages exhaustifs, indépendamment de leur état actuel. Le choix général V1=B limite seulement les **nouveautés non essentielles et non couvertes** par les QCM : elles vont en V1.1. Le périmètre métier envisagé comprend la création d'un club, l'invitation et la validation des joueurs, l'effectif, les saisons et matchs, les disponibilités/convocations, les compositions, le Live, les pronostics, les badges/statistiques, les réglages par club, le profil et les photos, les notifications (ou une alternative fiable), l'administration et l'historique. M00/M01/M02 doivent valider les éléments exacts dans la matrice G0, sans présumer qu'ils sont tous déjà fiables. Les fonctions optionnelles doivent pouvoir être désactivées sans casser la navigation ni exposer leurs API.

À décider et figer : football à 11 en première version, rôle du coach, nombre de clubs par utilisateur, gratuit/payant, nombre de tenues et modèle visuel, suppression des +1 automatiques, comportement sans réseau, fonctionnalités accessibles aux clubs en essai.

**Backlog V1.1 approuvé par principe (DEC-V1-B, précisé par Q01–Q12) :** **matchs de coupe** et nouvelles fonctionnalités non indispensables **hors des engagements Q01–Q12**. Une fonctionnalité expressément obligatoire ne peut plus être reportée au motif qu'elle n'est pas prête à la date du gel. Exemples possibles à arbitrer : nouveaux sports, nouvelles catégories complexes, nouvelles animations non essentielles, marketplace, réseau social, personnalisation infinie. La liste finale est établie par M01/M02 et validée par M00 ; un défaut P0/P1 sur une fonction essentielle ne doit jamais être reporté par facilité.

### Portes GO/NO-GO

| Porte | Feu vert exigé | Preuve à joindre |
| --- | --- | --- |
| G0 — Cadrage figé | DEC-V1-B/DEC-OFFRE-A/DEC-PILOTE-B et **Q01–Q12** inscrits ; engagements obligatoires V1 distingués du backlog V1.1 (coupes reportées) ; prix et paiements restent à arbitrer avant G5 | Matrice 164 fonctionnalités annotée « V1 impératif / V1.1 », registre des contradictions et décisions |
| G1 — Sécurité du socle | Aucun accès interclub non autorisé ; rôles et comptes suspendus testés ; sauvegarde/restauration DB + fichiers démontrée | Campagne A/B, rapports RLS/RPC/Storage/Edge/Realtime, exercice de restauration |
| G2 — Recette métier | **Q01–Q10 et Q12** validés en conditions réelles et en test serveur ; vidéo et maillots contrôlés sur appareils, saison complète isolée ; aucun P0/P1 ouvert | Matrice d'acceptation QCM + journal QA horodaté, captures, assertions et anomalies clôturées |
| G3 — Version mobile | iOS et Android installables ; identité, photos, vidéo (Q06), push et e-mails nécessaires (Q11), liens et reprises vérifiés sur vrais appareils | Builds signés, traces de réception, essais appareils réels, rapport TestFlight / Google interne |
| G4 — Réel pilote | Ouverture séquentielle A puis B puis C : chaque club rejoint après feu vert du précédent et des validations sécurité/juridiques ; deux matchs par club visés ; autonomie et remontées évaluées | Compte rendu A avant B, puis B avant C, consentements, indicateurs et GO utilisateur |
| G5 — Juridique / commerce | Éditeur identifié, marque et ressources revues, CGU/CGV/RGPD, suppression, paiement conforme et support prêts | Validation M07/M06, liens publics, preuves de test facturation |
| G6 — Boutiques | Fiches et déclarations complètes, certificats valides, testeurs/Apple Review, zéro défaut bloquant | Liens des builds, résolutions App Review et Play Console |
| G7 — Ouverture | G1–G6 verts, pilotage de publication, monitoring et procédure retour arrière approuvés | PV de décision GO signé, commit/tag et plan de lancement |

Les seuils métier proposés ci-dessous ne sont pas des résultats mesurés ; ils devront être confirmés par le propriétaire.

## 3. Lots de travail — responsables, tâches et preuves

### LOT 00 — Chef de projet / gouvernance (M00 ; P0 ; dès maintenant)
1. Désigner le document comme feuille de route de référence après approbation, articulé avec docs/HANDOFF.md et docs/CHANTIER.md.
2. Centraliser les demandes dans une seule liste : ticket, priorité, responsable, PR, CI, statut en production, test réel et décision requise. Fermer les tickets résolus avec preuve, sans fermer ceux dont seul le code est fusionné.
3. Figer le scope MVP selon Q01–Q12 et la définition de « terminé ». **Ne jamais déplacer en V1.1 une fonctionnalité QCM obligatoire** pour sauver le calendrier ; toute nouvelle fonction hors des douze relève du backlog V1.1, sauf arbitrage ultérieur explicite.
4. Chaque semaine : vérification du SHA réellement déployé, écarts GitHub/Supabase, risques, coût, planning, trois décisions maximum demandées au propriétaire.
5. Chaque GO requiert les rapports croisés M02/M03/M04/M07/M08/M09 ; pas d'approbation automatique par une seule CI verte.
**Livrables :** tableau consolidé P0/P1/P2, calendrier dépendances, registre risques, PV de chaque gate.

### LOT 01 — Finir et figer le produit (M01/M02/M05 ; P0/P1 ; novembre–décembre)
1. Réconcilier les demandes #66 réglages, #67 tenues, #68 crédits d'attente manuels, #70 administration, #71 vidéo neutre, #101 type de match « coupe », PR #115 rendu maillot. **Coupes reportées V1.1 (Q01) ; toutes les autres fonctions visées par Q02–Q10 et Q12 sont des obligations V1.** Revue AS Grinta uniquement en lecture.
2. Inventorier toutes les options : clé, valeur par défaut, dépendances, emplacement Réglages, UI masquée, RPC/Edge/DB bloquées, persistance, historique préservé, comportement après réactivation ; tester A et B avec valeurs différentes.
3. Approuver les visuels joueurs : visage non déformé, photo source libre/transparente et non retouchée, couronne identique à la composition, maillot réaliste dans patron/profil/effectif/compo/Live/vidéo ; **un ensemble de tenue initial, ajouts illimités, gardien associé, sélection via menu déroulant** et snapshot par match. Info maillots conserve une représentation simplifiée.
4. Faire apparaître le résultat choisi partout où il doit l'être, puis figer les composants centraux pour éviter des corrections indépendantes d'un écran à l'autre.
5. Tester un nouveau club vide et un club riche en données, sans dépendance à un identifiant de l'ancien AS Grinta.
6. Vérifier l'historique et la cohérence de la décision « +1 de liste d'attente exclusivement manuel » dans la base réellement utilisée.
7. Soumettre une version V1-RC uniquement si les obligations Q01–Q12 sont couvertes ; reporter les **coupes et fonctions nouvelles non essentielles**. Les vidéos de composition restent non reportables (Q06=A), même si la date de mai doit changer.
**Preuve :** maquettes validées, scénarios UI/SQL, liste de comparaison et audit de non-régression.

### LOT 02 — Assainir dépôt et livraisons (M02/M04/M09 ; P0 ; novembre)
1. Protéger main : revue PR, contrôles CI requis, interdiction de push direct, vérification des droits et de l'authentification des automatisations.
2. Différencier « PR fusionnée », « workflow réussi », « version déployée » et « testé réel » ; corriger tout tableau qui les confond.
3. Versionner web, Android et iOS avec le même numéro commercial, tags immuables et changelog, identifier les SHA de backend et de client.
4. CI minimum : formatage, analyse Flutter, tests unitaires/widgets, tests SQL/RPC sécurité, scans dépendances, analyse des migrations, build Web + Android ; build iOS sur macOS lorsque prêt. Faire échouer la CI si test important n'a pas tourné.
5. Déployer seulement les releases approuvées, avec rollback Web, approche additive en DB et compatibilité ancien client/nouveau backend.
6. Auditer les secrets (GitHub Actions, Supabase, Cloudflare, certificats mobiles), les dépendances et l'historique public de GitHub. Ne jamais inclure de secrets ni données personnelles dans des issues publiques.
**Preuve :** protection effective main, workflows qui échouent volontairement en cas de prérequis manquant, release tag reproductible.

### LOT 03 — Recette intégrale et résistance (M03 ; P0 ; décembre–janvier)
1. Reprendre les 164 fonctionnalités du registre ; pour chaque ligne tracer rôle, version, scénario, résultat écran, résultat serveur, preuve, date et testeur.
2. Exécuter la campagne d'une saison : au moins 30 rencontres dont **amicaux et championnat** (le type **coupe est hors V1**), annulation et corrections ; tester création, disponibilité, attente manuelle, compositions, Live complet, score, finalisation, pronostics, statistiques et révision. **Inclure vidéo obligatoire, badges complets et réglages par club**.
3. Simuler la clôture exclusivement sur une copie isolée. Vérifier conservation des matchs, récompenses, Wrapped et passage à une nouvelle saison. Ne jamais clôturer un club commercial réel à titre de test.
4. Cas limites : aucun joueur, 1/11/30 joueurs, un gardien absent, invités, changement de tenue, badge ambigu, ex-aequo homme du match, scores atypiques, dates/fuseaux, double-clic, écrans vides, beaucoup d'historiques, annulation.
5. Matrice de rôles : admin A, joueur A, coach A, admin B, joueur B, suspendu, supprimé, invité, session expirée ; tester les appels directs et pas seulement les écrans.
6. Parcours comptes : création, invitation, lien profond, validation, e-mails, perte de mot de passe, réauthentification, suppression et export.
7. Matrice appareils : petit/grand iPhone, Android entrée/milieu de gamme, tablettes pertinentes, PWA et navigateurs principaux ; clair/sombre, orientation, accessibilité, lecteurs d'écran, textes longs.
8. Interruptions : coupure réseau, réseau lent, double action de deux admins, arrière-plan, reprise à froid, session expirée au milieu d'un match, gros médias et stockage plein.
9. Ne pas confondre la présence d'une assertion automatique et le résultat réel observé.
**Sortie :** zéro P0/P1 restant ; 100 % des parcours critiques validés ; autres anomalies triées, corrigées ou acceptées explicitement.

### LOT 04 — Audit sécurité multiclub et reprise (M04/M09 ; P0 ; novembre–janvier)
1. Construire une matrice d'attaque contrôlée A↔B pour SELECT/INSERT/UPDATE/DELETE, RPC, Edge, Storage, Realtime, calendriers, photos et notifications.
2. Revoir chaque SECURITY DEFINER exposée ; confirmer contrôles internes auth.uid(), club_id, statut du club, rôle et portée de l'appel. Les 164 avertissements ne sont pas présumés 164 failles.
3. Tester contournements par références UUID d'un autre club, changement de rôle, statut suspendu, JWT périmé, modification de paramètres métier directement via API.
4. Vérifier toutes les tables exposées, politiques RLS, vues, privilèges EXECUTE et fonctions internes ; service_role jamais embarqué dans le client.
5. Vérifier protections Auth : mots de passe, récupération, rate limits, SMTP, anti-abus, secrets et rotation éventuelle seulement si justifiée.
6. Historique Git public : détecter secrets et anciennes données potentiellement personnelles sans les recopier en issue ou PR ; classer le risque et définir remédiation ciblée.
7. Configurer sauvegardes DB ET médias Storage ; prouver restauration complète dans un autre projet isolé, vérifier fichiers octet pour octet, rôles, Auth et permaliens.
8. Proposer RPO de 24 h et RTO de 4 h comme objectifs initiaux à arbitrer selon coûts (non garantis tant qu'un exercice réel n'est pas passé).
9. Mesurer trafic normal et pics de matchs (simultanéité, notifications, connexions, prises de score), définir limites et quotas, surveiller la facture.
**Sortie :** rapport de tests hostiles, corrections re-testées, exercice restauration et approbation avant données réelles.

### LOT 05 — Architecture environnements et exploitation (M09/M02 ; P0/P1 ; décembre–janvier)
1. Définir local/test, staging isolé, production. Ne jamais utiliser la base AS Grinta originale. Décider s'il faut repartir sur une production vierge ou gérer explicitement les deux clubs fictifs de la base commerciale existante.
2. Avant tout changement de base : confirmer projet cible, sauvegarde, migration append-only, tests post-migration, compatibilité clients, possibilité de correction.
3. Tester DNS / domaine Petit Filet, HTTPS, CSP, politique cache PWA, URL d'invitation, page légale et URL de suppression de compte.
4. Vérifier Cloudflare Pages pour service commercial, publication manuelle, monitoring, disponibilité, page d'état et alertes réelles.
5. Configurer SMTP transactionnel professionnel (SPF/DKIM/DMARC), liens de confirmation, anti-spam et flux de récupération.
6. Superviser Edge, Postgres, Storage, Auth, Realtime, pannes d'e-mails et délais notifications ; journal d'incidents sans données personnelles en clair.
7. Test d'alerte volontaire contrôlée et plan d'astreinte proportionné à une petite entreprise.
**Sortie :** environnement reproductible, une commande de diagnostic, runbooks et coût mensuel mesuré.

### LOT 06 — Transformer Flutter Web en applications mobiles (M02/M03 ; P0 stores ; décembre–février)
1. Créer répertoires et projets natifs android/ et ios/ UNIQUEMENT sur le dépôt Petit Filet, par PR dédiée, à partir d'une version Flutter et des plugins figée.
2. Faire l'inventaire des dépendances spécifiques Web (imports conditionnels, service worker, Web Push, authentification navigateur, sélecteur photo, **vidéo de composition obligatoire**, partage, téléchargement). Introduire des adaptateurs mobiles plutôt que dupliquer le métier.
3. Identité mobile : nom affiché Petit Filet, identifiants d'application stables, icônes, splash, permissions minimales, écran hors ligne et paramètres de confidentialité.
4. Connexion : Supabase Auth mobile, stockage sécurisé des sessions, retour de navigateur, liens d'invitation et de récupération, deep links Android/iOS (App Links / Universal Links), gestion de plusieurs clubs sans collision.
5. Photos : galerie, permissions, recadrage, transparence, fichiers volumineux, annulation et stockage ; maillots identiques à la Web mais rendus propres aux tailles d'écran.
6. Push natif : APNs côté iOS, FCM côté Android ou passerelle choisie ; tokens par appareil, révocation, préférences par club, absence de doublons avec la PWA, reçus sur appareils réels.
7. Partage : composition vidéo/images, liens, calendrier, pièces jointes, arrivée depuis notification ; tester app en avant-plan, arrière-plan et arrêtée.
8. Ajouter tests de performance, crash, batterie, espace et navigation ; respecter l'accessibilité système et les boutons de retour.
9. Builds signés reproductibles. Android AAB, versionCode, signature Play App Signing ; iOS archive IPA via Xcode/macOS, provisionnement et certificats ; secrets uniquement en CI sécurisée.
10. Synchroniser les règles Web et mobile ; ne pas lancer un client store dépendant d'une migration non publiée et non rétrocompatible.
**Sortie :** application iPhone et Android utilisable sans PWA, testée par vrais testeurs.

### LOT 07 — Notifications, fiabilité du Live et médias (M02/M03/M09 ; P0/P1 ; janvier–février)
1. Identifier chaque notification existante, l'option par club, la préférence du joueur, l'événement producteur, la date, le canal, le destinataire et le mécanisme de déduplication.
2. Contrôler ouverture des disponibilités, rappels, pronostics, Live, résultats, classement, badges et **e-mails essentiels** ; vérifier **les push iOS et Android sur vrais appareils (Q11=A)** et ne jamais compter un envoi serveur comme « reçu ».
3. Évaluer l'observabilité des livraisons et le nettoyage des tokens invalides ; tests réel iPhone/Android et en PWA installée.
4. Prévoir que l'information cruciale reste consultable dans l'app même si les notifications sont refusées, en retard ou perdues.
5. Vérifier la vidéo de composition et le stade sans inscription AS Grinta, droit d'utilisation de chaque média, performance sur appareils modestes.
**Sortie :** matrice de réception par OS, zéro fuite interclub, expérience dégradée acceptable.

### LOT 08 — RGPD, droit et propriété intellectuelle (M07/M05 ; P0 ; dès maintenant à mars)
1. Vérifier le nom Petit Filet : DATA INPI, recherche de ressemblances, entreprises, domaines, stores et classes pertinentes ; ne pas déposer de marque avant revue et accord de coût.
2. Définir entité juridique de l'éditeur, identité publique, coordonnées professionnelles, régime de facturation/TVA, support et assurance éventuelle.
3. Qualifier précisément responsable de traitement et sous-traitants selon finalités (club, joueur, éditeur), sous-traitants ultérieurs, transferts et DPA.
4. Minimiser données : noms, photos, disponibilités, votes, statistiques, fichiers, notifications, logs. Les motifs libres d'indisponibilité pouvant révéler la santé demandent une décision juridique spécifique ; considérer leur retrait ou désactivation par défaut.
5. Gérer mineurs et droit à l'image : information, autorisations nécessaires, preuve et retrait ; démarrer les pilotes avec adultes consentants pour réduire les risques initiaux.
6. Finaliser mentions légales, CGU, CGV, politique de confidentialité, accord sur les données, politique de conservation, export/suppression et contrats.
7. Vérifier réellement suppression de compte au sein de l'app ET via une ressource Web publique (exigence Google), effacement des médias, contrats et exceptions de conservation documentées.
8. Auditer images, logos, sons, vidéos, modèles, fonts, licences de plugins, créations IA, histoire du dépôt public ; publier les attributions nécessaires sans dévoiler d'anciens comptes.
9. Déclaration Apple App Privacy, Google Data Safety, permissions, classification d'âge et statut professionnel DSA ; cohérence exacte avec le comportement réel.
10. Faire relire les points juridiques importants par un professionnel avant première vente ; le document interne est une préparation.
**Sortie :** URL publiques légales valables, registre de traitements, preuves d'effacement, licences, accord pour premiers clients.

### LOT 09 — Offre, abonnement et paiement (M06/M02/M07 ; P1 ; novembre–mars)
1. **Décision DEC-OFFRE-A validée : abonnement annuel par club.** Construire l'offre et le modèle d'accès autour d'un seul abonnement souscrit par le club, avec administrateur/association comme interlocuteur commercial à qualifier. Les joueurs de ce club ne sont pas facturés individuellement par Petit Filet. Premier segment envisagé : clubs loisirs adultes de football à 11 (positionnement précis encore à confirmer).
2. Arbitrer période d'essai, accès à la fin de l'essai, compte propriétaire, limites de stockage, club suspendu, données à récupérer, changement de saison.
3. Tester plusieurs **prix annuels par club** à partir des coûts et enquêtes pilotes (le prix par joueur présent dans le code n'est pas un tarif officiel). Arbitrer les éventuelles limites d'effectif, options ou quotas sans transformer implicitement le modèle approuvé en facturation individuelle. Comparer seuil de rentabilité, saisonnalité et risque de support.
4. Choisir parcours de facturation : virement + facture pour très peu de clubs si conforme au marché et aux règles stores, ou Stripe côté Web avec webhooks signés et état d'accès côté serveur. Les achats de services numériques dans les apps sont soumis aux politiques Apple 3.1 et Google Play Payments, variables selon canal, pays et clientèle : faire valider le parcours avant de coder des liens d'achat externes.
5. Tester échec de paiement, remboursement, prolongation, changement d'effectif, annulation et réactivation, expiration et maintien de l'accès aux données conformément au contrat.
6. Calculer marge nette à 5, 10, 25, 50 clubs en incluant services cloud, commissions, comptabilité, support, taxes et temps de travail. Aucun tarif final sans décision.
7. Rédiger offre pilote gratuite séparée de l'offre payante et éviter toute promesse commerciale non démontrée.
**Sortie :** offre compréhensible, facturation testée, conformité boutiques validée, coûts suivis.

### LOT 10 — Pilotes indépendants (M08/M03/M06 ; P0 avant vente ; février–avril)
1. **Décision DEC-PILOTE-B validée : pilote progressif, un club A puis deux clubs B et C.** N'inviter de vrais clubs qu'après G1 sécurité et conformité juridique nécessaire. Proposition de dimension : trois clubs adultes de 15–30 joueurs avec consentement et administrateur volontaire, au moins deux rencontres chacun, à ajuster selon leurs calendriers.
2. Ouvrir d'abord au **club A** ; faire vérifier l'onboarding, les parcours de match, les incidents et l'autonomie de son administrateur avant feu vert M00/M03/M04/M07 pour **club B**. Reproduire l'évaluation de B avant d'accueillir **club C** ; ne pas ouvrir les trois simultanément.
3. Donner uniquement un guide simple et observer : créer club, saison, équipe, invitation, match, composition, pronostics, Live, résultats, stats, réglages et support.
4. Mesurer : délai jusqu'au premier match, activation joueurs J+7, bugs, utilisateurs actifs, fréquence d'ouverture, charge de support par club, satisfaction et volonté de payer.
5. Seuils proposés à confirmer : 0 fuite/incident P0, 0 crash reproductible bloquant, 100 % des parcours cœur réalisés, >= 80 % d'admin pilotes autonomes sur les tâches essentielles, >= 2 rencontres par club sans intervention directe de l'éditeur sur leurs données. Les métriques d'engagement servent à décider, pas à masquer les incidents.
6. Classer chaque retour : défaut, demande essentielle MVP, amélioration V1.1, préférence locale à régler.
7. Établir la preuve de réussite avec une synthèse de trois administrateurs et un arbitrage GO/NO-GO.
**Sortie :** rapport pilote et plan de corrections signé avant commercialisation.

### LOT 11 — Compte développeur, boutiques et conformité mobile (M05/M06/M02 ; P1 ; décembre–avril)
1. Décider « compte individuel ou organisation » selon l'entité juridique. Chez Apple, le compte individuel affiche le nom légal de la personne comme vendeur ; l'organisation demande une entité juridique, un domaine et un D-U-N-S. Vérifier vérification et coûts avant paiement.
2. Apple : Apple Developer Program, App Store Connect, nom et bundle ID, certificats, privacy, permissions, classification d'âge, politique légale, pays/territoires, statut DSA trader et coordonnées visibles, compte de démo admin/joueur avec données fictives et instructions de review, TestFlight, App Review.
3. Google : Play Console, type de compte, identité et paiement, package name, signature AAB, classification âge, Data Safety, URL publique suppression compte, captures, contact support, politique enfant si pertinent, tests internes/fermés, production.
4. Pour compte Play personnel créé après le 13/11/2023 : au moins 12 testeurs opt-in en continu pendant 14 jours pour demander l'accès production. Planifier ce délai et la demande, distincts des pilotes métier.
5. Exigences SDK : Google cible Android 16/API 36 minimum pour nouvelles apps depuis le 31 août 2026 ; Apple prévoit l'usage des SDK iOS/iPadOS 27 à partir d'avril 2027. Revérifier juste avant la soumission.
6. Examiner les règles de paiement des boutiques et l'obligation Apple d'une app qui ne soit pas un simple site encapsulé. Si une connexion sociale tierce est proposée, vérifier l'exigence Apple d'une option de connexion équivalente ou d'une exemption.
7. Préparer captures de l'application **réelle** sur données fictives, illustrations légales, texte court/long, mots-clés, vidéo facultative, icône accessible ; aucune identité réelle AS Grinta ni média sans droits.
8. Garder 2 à 4 semaines de marge pour examen, corrections et nouvelles soumissions ; délais réels non garantis.
**Sortie :** Apple TestFlight, Google test fermé, fiches complètes et versions acceptées.

### LOT 12 — Lancement contrôlé et maintenance (M09/M06/M08/M00 ; P0 pour ouverture ; avril–mai)
1. Rédiger runbook « publier / vérifier / revenir en arrière » pour Web, Android, iOS et migrations. Contrôler cohérence des configurations, API, contrats, clés et certificat.
2. Déployer par étapes et possibilité d'arrêt : premier petit groupe puis élargissement. Les releases stores ne sont pas instantanément réversibles ; réserver des fonctions désactivables par serveur.
3. Pendant 48–72 h : vérifier crash, Auth, e-mails, push, Live, latence et coûts ; canal de support connu ; responsable incident et actions d'escalade.
4. Contrôler premier parcours client réel et aucune présence de données fictives dans les vues des clients.
5. Publier page présentation et FAQ, tutoriels admin, politique de support, facturation et coordonnées réelles.
6. Suivre chiffres de conversion, support, renouvellement et indicateurs de confiance ; décider V1.1 après observation, pas pendant le lancement.
**Sortie :** lancement contrôlé + rapport J+7, J+30 et calendrier de maintenance.

## 4. Calendrier opérationnel jusqu'à mai 2027

| Période cible | Travail impératif | Porte / preuve |
| --- | --- | --- |
| **14–30 nov. 2026** | Geler les engagements V1 Q01–Q12, reporter coupes V1.1, protection main, PR #115, audit RLS/secrets, inventaire natif et revue des contradictions maillots/réglages | Préparation G0, journal risques ; ne pas réduire Q06 pour tenir mai |
| **Déc. 2026** | Corrections du code, essais A/B, séparation environnements, lancement recette 164 fonctions, socle Android/iOS et préparation comptes développeurs | G0, progrès G1 et G2 |
| **Jan. 2027** | Saison complète isolée, corrections, tests mobiles Auth/photos/Live, premiers builds, backup et restore probants, textes légaux | G1 et G2 visés ; G3 bêta |
| **Fév. 2027** | TestFlight/Play interne, vrai push mobile, finition UX, facturation conforme, onboarding premier club adulte si portes de sécurité et droit validées | G3, ouverture G4 |
| **Mars 2027** | Pilotes B/C, deux matchs chacun si calendriers compatibles, suivi support, tarification définitive, derniers défauts majeurs | G4 et G5 visés |
| **Avr. 2027** | Gel release **seulement après** vidéo et autres QCM validés, fiches stores, 12 testeurs/14 jours Google si applicable, SDK iOS 27, revue et soumissions avec marges | G6, sinon reporter les soumissions |
| **Mai 2027 (objectif conditionnel)** | Décision G7, mise en production progressive, support intensif et observation commerciale ; **décaler la date plutôt que supprimer la vidéo ou un impératif V1** | Publication officielle seulement si GO |

Les préparatifs Apple/Google et juridiques commencent AVANT la fin du code. Ne jamais sacrifier G1/G2 pour respecter artificiellement mai.

### Chemin critique

Cadrage V1 **Q01–Q12** -> Sécurité A/B + QA saison / administration / vidéo / maillots / réglages -> Builds natifs avec vidéo et push réellement fiables -> Pilotes progressifs A→B→C -> Paiement annuel club et droits validés -> Soumissions -> GO. **Mai 2027 est un objectif subordonné à ce chemin critique.**  
En parallèle : identité, marque, structure juridique, domaine, compte développeur, formation utilisateurs, supports et fiches boutique.

## 5. Budget de décision (non engagé)

| Ligne | Nature | État |
| --- | --- | --- |
| Apple Developer | 99 USD/an, montant local éventuel | Frais officiels à autoriser |
| Google Play Console | 25 USD une fois | Frais officiels à autoriser |
| Domaine + e-mail pro | renouvellement annuel | Devis et fournisseur à choisir |
| Supabase / Cloudflare / monitoring / sauvegardes | mensuel et stockage variable | Relever la facture et simuler la charge réelle |
| CI iOS macOS / machine Mac | équipement ou service CI | Solution à décider |
| Relecture juridique / activité / assurance | ponctuel ou annuel | Budget à demander |
| Paiement et comptabilité | frais par transaction + fixes éventuels | Dépend du modèle de paiement |
| Design, support, testeurs | temps, prestataires éventuels | Réserver une marge |

Établir trois budgets : minimal maîtrisé, prudent et déploiement étendu. Aucune souscription ni achat en l'absence d'accord.

## 6. Matrice de décisions attendues du propriétaire

- **D01 — CHOISI B (DEC-V1-B), PRÉCISÉ Q01–Q12 = A** : les douze familles explicitement choisies sont obligatoires en V1 **même inachevées**, et les nouvelles fonctions non indispensables sont reportées en V1.1. Les matchs de coupe sont précisément reportés. Reste la traçabilité de chaque critère G0.
- D02 — type de société / entreprise individuelle et nom du vendeur affiché Apple.
- D03 — positionnement : clubs de foot loisirs adultes uniquement au départ ?
- **D04 — CHOISI A (DEC-OFFRE-A)** : abonnement annuel par club, aucun paiement individuel imposé au joueur. Reste à chiffrer prix, conditions, essai, facturation et renouvellement.
- D05 — mode de paiement : facture/virement, Stripe Web, achats intégrés si règles l'exigent.
- D06 — marque, domaine et adresse de contact public.
- D07 — budget maximum mensuel, sauvegardes, CI iOS/macOS et relecture juridique.
- D08 — accord d'utilisation d'un staging distinct, de comptes de test et de sauvegardes (pas de modifications irréversibles sans validation).
- **D09 — CHOISI B (DEC-PILOTE-B)** : recrutement/ouverture séquentiels, un premier club puis les deux autres progressivement ; conditions d'invitation, sécurité et dates restent à valider.
- D10 — approbation expresse des dépenses développeur et publication aux boutiques.

Une question à la fois avec choix A/B/C, recommandation, impacts coûts et délai. Une absence de réponse ne vaut pas validation.

## 7. Table de contrôle hebdomadaire M00

Renseigner tous les lundis ou à chaque jalon : semaine, branche/main SHA, version Web déployée, dernières migrations production, statut de CI, nombre de P0/P1 ouverts, couverture fonctionnelle réellement jouée, status des deux clubs de sécurité, date du dernier restore, coûts constatés, versions iOS/Android testées, validation juridique, progrès pilotes, soumissions boutique et décision bloquante.

Niveau de preuve attendu :
1. DOCUMENTÉ : scénario décrit.
2. CODÉ : code présent sur branche.
3. VALIDÉ CI : contrôles verts au SHA exact.
4. TESTÉ RÉEL : parcours et résultat prouvés.
5. DÉPLOYÉ : SHA/version correspondants effectivement en service.
6. APPROUVÉ : responsable accepte le jalon.

Une tâche n'est « terminée » que si le niveau exigé par son gate est atteint.

## 8. Première séquence d'exécution (10 jours ouvrés après approbation du plan)

| Ordre | Responsable | Tâche | Critère de sortie |
| --- | --- | --- | --- |
| 1 | M00 / propriétaire | Annoter les 164 fonctions selon **Q01–Q12=V1 impératif** et **coupes=V1.1** ; accepter explicitement que la vidéo puisse retarder mai | Backlog P0/P1/V1.1 et risques calendaires documentés |
| 2 | M02/M05 | Conclure PR #115, cadrer le menu déroulant et les ensembles maillots illimités, vérifier parité Administration et vidéo obligatoire | CI verte + contrôle smartphone + aucun conflit ; pas de migration appliquée |
| 3 | M04/M00 | Vérifier main protégée et historique Git | Ruleset actif, rapport confidentialité privé |
| 4 | M03 | Organiser recette avec jeu fictif isolé et accès autorisés | 164 tests attribués, preuves et planning |
| 5 | M04 | Campagne A/B et audit 164 SECURITY DEFINER | Verdict par fonction, aucune fuite non corrigée |
| 6 | M09 | Vérifier restore DB + Storage et alertes | Exercice et logs probants |
| 7 | M02 | Audit de faisabilité iOS/Android des plugins | Liste incompatibilités/estimations et PR de socle mobile |
| 8 | M07 | Lister mentions/consentements/données non conformes | Blocants juridiques priorisés |
| 9 | M06 | Définir 2–3 **prix annuels par club** et parcours de paiement compatibles avec les boutiques | Arbitrage du montant sans codage prématuré |
| 10 | M08 | Préparer le protocole de pilote séquentiel A → B → C | Invitations non envoyées avant G1 et garanties juridiques pertinentes ; revue obligatoire avant chaque extension |

## 9. Références de traçabilité

Sources internes : docs/HANDOFF.md, docs/CHANTIER.md, docs/qa_saison_20261113/, docs/M04_SECURITE_RESILIENCE_20261112.md, docs/PILOTE_CLUBS_UX.md, docs/JURIDIQUE_MISSION07.md, docs/COMMERCIAL_STRATEGIE_M06.md, docs/COMMERCIAL_LAUNCH_CHECKLIST.md, docs/M09_RESTORE_DRILL_LOCAL_20261113.md.

Textes officiels à revérifier avant publication :
- Apple App Review : https://developer.apple.com/app-store/review/guidelines/
- Apple iOS SDK : https://developer.apple.com/app-store/submitting/
- Apple inscription : https://developer.apple.com/fr/help/account/membership/program-enrollment/
- Apple DSA : https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
- Flutter iOS : https://docs.flutter.dev/deployment/ios
- Android target API : https://developer.android.com/google/play/requirements/target-sdk
- Google compte personnel / tests : https://support.google.com/googleplay/android-developer/answer/14151465?hl=fr
- Google suppression de compte : https://support.google.com/googleplay/android-developer/answer/13327111?hl=en
- INPI recherche marque : https://www.inpi.fr/ressources/propriete-intellectuelle/rechercher-une-marque-base-marques

**Limites :** aucune nouvelle migration, données réelles, merge ou publication réalisée pour préparer ce plan. Les statuts sont ceux observés au moment de l'enquête et doivent être rafraîchis avant chaque décision.