# PETIT FILET — PLAN DIRECTEUR DE LANCEMENT 2026–2027

**Édition : 14 novembre 2026 — document de pilotage proposé, non encore approuvé.**  
**Cible : première publication officielle iOS / Android et lancement progressif en mai 2027.**  
**Dépôt concerné :** samihchaa-wq/Application-football-  
**Application d'origine : AS Grinta — consultation en lecture seule ; modification interdite.**

## Mode d'emploi

Ce document est une feuille de route d'exécution, pas un certificat de conformité ni l'ordre de publier. Toute tâche a un responsable, un livrable, des preuves et une porte de validation. L'état « code présent » ne vaut jamais « testé réellement ». Les décisions sensibles (migration, création de compte, dépenses, premiers clients, publication) demandent l'autorisation explicite du propriétaire. Les dates sont des objectifs révisables, pas des garanties.

Statuts : **NON COMMENCÉ / EN COURS / À TESTER / VALIDÉ / BLOQUÉ**. Priorités : **P0** empêche d'accueillir de vrais clients, **P1** indispensable avant boutique ou paiement, **P2** après lancement si sans risque.

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

Le MVP garde les fonctions qui font la différence : création d'un club, invitation et validation des joueurs, effectif, saisons et matchs, indisponibilités/convocations, compositions, Live, pronostics, badges/statistiques, réglages individuels par club, profil et photos, notifications (ou alternative fiable), administration et historique. Les fonctions optionnelles doivent pouvoir être désactivées sans casser la navigation ni exposer leurs API.

À décider et figer : football à 11 en première version, rôle du coach, nombre de clubs par utilisateur, gratuit/payant, nombre de tenues et modèle visuel, suppression des +1 automatiques, comportement sans réseau, fonctionnalités accessibles aux clubs en essai.

**Hors périmètre de la première publication sauf nécessité établie :** nouveaux sports, nouvelles catégories complexes, nouvelles animations non essentielles, marketplace, réseau social, personnalisation infinie. La liste des reports entre dans une section backlog V1.1. Le gel ne supprime pas les corrections de bugs P0/P1.

### Portes GO/NO-GO

| Porte | Feu vert exigé | Preuve à joindre |
| --- | --- | --- |
| G0 — Cadrage figé | Périmètre V1 et tarifs/paiements arbitrés ; exigences M01-M02 signées | Matrice 164 fonctionnalités, décisions et backlog |
| G1 — Sécurité du socle | Aucun accès interclub non autorisé ; rôles et comptes suspendus testés ; sauvegarde/restauration DB + fichiers démontrée | Campagne A/B, rapports RLS/RPC/Storage/Edge/Realtime, exercice de restauration |
| G2 — Recette métier | Aucun P0 ni P1 ouvert ; parcours critiques réellement exécutés ; saison complète simulée sur environnement isolé | Journal QA horodaté, captures, assertions et anomalies clôturées |
| G3 — Version mobile | iOS et Android installables ; identité, photo, push, liens et reprises fonctionnels ; performances acceptables | Builds signés, essais appareils réels, rapport TestFlight / Google interne |
| G4 — Réel pilote | Trois clubs adultes volontaires, au moins deux matchs chacun, fonctionnement autonome raisonnable et remontées traitées | Comptes rendus de séances, consentements, indicateurs et GO utilisateur |
| G5 — Juridique / commerce | Éditeur identifié, marque et ressources revues, CGU/CGV/RGPD, suppression, paiement conforme et support prêts | Validation M07/M06, liens publics, preuves de test facturation |
| G6 — Boutiques | Fiches et déclarations complètes, certificats valides, testeurs/Apple Review, zéro défaut bloquant | Liens des builds, résolutions App Review et Play Console |
| G7 — Ouverture | G1–G6 verts, pilotage de publication, monitoring et procédure retour arrière approuvés | PV de décision GO signé, commit/tag et plan de lancement |

Les seuils métier proposés ci-dessous ne sont pas des résultats mesurés ; ils devront être confirmés par le propriétaire.

## 3. Lots de travail — responsables, tâches et preuves

### LOT 00 — Chef de projet / gouvernance (M00 ; P0 ; dès maintenant)
1. Désigner le document comme feuille de route de référence après approbation, articulé avec docs/HANDOFF.md et docs/CHANTIER.md.
2. Centraliser les demandes dans une seule liste : ticket, priorité, responsable, PR, CI, statut en production, test réel et décision requise. Fermer les tickets résolus avec preuve, sans fermer ceux dont seul le code est fusionné.
3. Figer le scope MVP et la définition de « terminé ». Pas de nouveau module après G0 sans arbitrage d'impact et de risque.
4. Chaque semaine : vérification du SHA réellement déployé, écarts GitHub/Supabase, risques, coût, planning, trois décisions maximum demandées au propriétaire.
5. Chaque GO requiert les rapports croisés M02/M03/M04/M07/M08/M09 ; pas d'approbation automatique par une seule CI verte.
**Livrables :** tableau consolidé P0/P1/P2, calendrier dépendances, registre risques, PV de chaque gate.

### LOT 01 — Finir et figer le produit (M01/M02/M05 ; P0/P1 ; novembre–décembre)
1. Réconcilier les demandes #66 réglages, #67 tenues, #68 crédits d'attente manuels, #70 administration, #71 vidéo neutre, #101 type de match « coupe », PR #115 rendu maillot. Réaliser une revue de parité avec AS Grinta uniquement en lecture.
2. Inventorier toutes les options : clé, valeur par défaut, dépendances, emplacement Réglages, UI masquée, RPC/Edge/DB bloquées, persistance, historique préservé, comportement après réactivation ; tester A et B avec valeurs différentes.
3. Approuver les visuels joueurs : visage non déformé, détourage transparent, couronne identique à la composition, maillot réaliste dans patron/profil/effectif/compo/Live/vidéo selon le contrat final, gardien et tenue du match.
4. Faire apparaître le résultat choisi partout où il doit l'être, puis figer les composants centraux pour éviter des corrections indépendantes d'un écran à l'autre.
5. Tester un nouveau club vide et un club riche en données, sans dépendance à un identifiant de l'ancien AS Grinta.
6. Vérifier l'historique et la cohérence de la décision « +1 de liste d'attente exclusivement manuel » dans la base réellement utilisée.
7. Soumettre une version V1-RC et reporter tout ajout non essentiel.
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
2. Exécuter la campagne d'une saison : au moins 30 rencontres dont matches amicaux, championnat et annulation ; jouer à travers les étapes de création, disponibilité, attente manuelle, compositions, Live, score, finalisation, pronostics, statistiques et révision.
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
2. Faire l'inventaire des dépendances spécifiques Web (imports conditionnels, service worker, Web Push, authentification navigateur, sélecteur photo, lecture vidéo, partage, téléchargement). Introduire des adaptateurs mobiles plutôt que dupliquer le métier.
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
2. Contrôler ouverture des disponibilités, rappels, pronostics, Live, résultats, classement, badges ; ne jamais compter un envoi serveur comme « reçu ».
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
1. Segment cible : premier lancement clubs loisirs adultes de football à 11, un tarif par club ou par joueur, décideur admin/association. Valider qu'aucun joueur ne doit payer séparément par défaut.
2. Arbitrer période d'essai, accès à la fin de l'essai, compte propriétaire, limites de stockage, club suspendu, données à récupérer, changement de saison.
3. Tester 3 grilles tarifaires sur coûts et enquêtes pilotes (prix dans le code = hypothèse, pas prix officiel). Évaluer simplification à forfait club pour faciliter la vente et la gestion des licenciés.
4. Choisir parcours de facturation : virement + facture pour très peu de clubs si conforme au marché et aux règles stores, ou Stripe côté Web avec webhooks signés et état d'accès côté serveur. Les achats de services numériques dans les apps sont soumis aux politiques Apple 3.1 et Google Play Payments, variables selon canal, pays et clientèle : faire valider le parcours avant de coder des liens d'achat externes.
5. Tester échec de paiement, remboursement, prolongation, changement d'effectif, annulation et réactivation, expiration et maintien de l'accès aux données conformément au contrat.
6. Calculer marge nette à 5, 10, 25, 50 clubs en incluant services cloud, commissions, comptabilité, support, taxes et temps de travail. Aucun tarif final sans décision.
7. Rédiger offre pilote gratuite séparée de l'offre payante et éviter toute promesse commerciale non démontrée.
**Sortie :** offre compréhensible, facturation testée, conformité boutiques validée, coûts suivis.

### LOT 10 — Pilotes indépendants (M08/M03/M06 ; P0 avant vente ; février–avril)
1. N'inviter de vrais clubs qu'après G1 sécurité et droit conforme. Proposition : trois clubs adultes de 15–30 joueurs avec consentement et administrateur volontaire, au moins deux rencontres chacun.
2. Club A en premier, puis B et C progressivement ; ne pas appeler les 3 en même temps si onboarding A n'est pas maîtrisé.
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
| **14–30 nov. 2026** | Figement MVP, tri P0/P1, protection main, PR #115, audit RLS/secret, inventaire natif, décision juridique éditeur et marque | Préparation G0, journal risques |
| **Déc. 2026** | Corrections du code, essais A/B, séparation environnements, lancement recette 164 fonctions, socle Android/iOS et préparation comptes développeurs | G0, progrès G1 et G2 |
| **Jan. 2027** | Saison complète isolée, corrections, tests mobiles Auth/photos/Live, premiers builds, backup et restore probants, textes légaux | G1 et G2 visés ; G3 bêta |
| **Fév. 2027** | TestFlight/Play interne, vrai push mobile, finition UX, facturation conforme, onboarding premier club adulte si portes de sécurité et droit validées | G3, ouverture G4 |
| **Mars 2027** | Pilotes B/C, deux matchs chacun si calendriers compatibles, suivi support, tarification définitive, derniers défauts majeurs | G4 et G5 visés |
| **Avr. 2027** | Gel release, fiches stores, 12/14 jours Google si applicable, SDK iOS 27, revue et soumissions avec marges | G6 |
| **Mai 2027** | Décision G7, mise en production progressive, support intensif et observation commerciale | Publication officielle si GO |

Les préparatifs Apple/Google et juridiques commencent AVANT la fin du code. Ne jamais sacrifier G1/G2 pour respecter artificiellement mai.

### Chemin critique

Cadrage V1 -> Sécurité A/B + QA saison -> Builds natifs fiables -> Tests vrais utilisateurs -> Paiement et droits validés -> Soumissions -> GO.  
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

- D01 — périmètre V1 : fonctionnalités indispensables et celles reportées.
- D02 — type de société / entreprise individuelle et nom du vendeur affiché Apple.
- D03 — positionnement : clubs de foot loisirs adultes uniquement au départ ?
- D04 — modèle économique : abonnement club fixe, par joueur ou hybride ; essai.
- D05 — mode de paiement : facture/virement, Stripe Web, achats intégrés si règles l'exigent.
- D06 — marque, domaine et adresse de contact public.
- D07 — budget maximum mensuel, sauvegardes, CI iOS/macOS et relecture juridique.
- D08 — accord d'utilisation d'un staging distinct, de comptes de test et de sauvegardes (pas de modifications irréversibles sans validation).
- D09 — conditions de recrutement de trois clubs pilotes adultes.
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
| 1 | M00 / propriétaire | Arbitrer scope V1 et marge mai | Backlog P0/P1 figé |
| 2 | M02/M05 | Conclure PR #115 et finir les défauts visibles priorisés | CI verte + contrôle smartphone + aucun conflit |
| 3 | M04/M00 | Vérifier main protégée et historique Git | Ruleset actif, rapport confidentialité privé |
| 4 | M03 | Organiser recette avec jeu fictif isolé et accès autorisés | 164 tests attribués, preuves et planning |
| 5 | M04 | Campagne A/B et audit 164 SECURITY DEFINER | Verdict par fonction, aucune fuite non corrigée |
| 6 | M09 | Vérifier restore DB + Storage et alertes | Exercice et logs probants |
| 7 | M02 | Audit de faisabilité iOS/Android des plugins | Liste incompatibilités/estimations et PR de socle mobile |
| 8 | M07 | Lister mentions/consentements/données non conformes | Blocants juridiques priorisés |
| 9 | M06 | Définir 2–3 tarifs et parcours de paiement possibles | Arbitrage sans codage prématuré |
| 10 | M08 | Préparer protocole et recrutement conditionnel des pilotes | Invitations non envoyées avant G1/G5 pertinents |

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