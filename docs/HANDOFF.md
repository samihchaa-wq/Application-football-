# Relais entre assistants — Petit Filet (application commerciale)

**Actualisé le 17 novembre 2026 (correctif de gouvernance publication).** Source de vérité opérationnelle : branche `main`, PR ouvertes et contrôles GitHub sur le dernier SHA ; les états ci-dessous peuvent évoluer.

## Session Kyky du 22/11/2026 (branche claude/gallant-babbage-2iz44v)

- Fait : flash au lancement corrigé (copie locale de l'habillage du club relue avant le 1er rendu ; test ajouté). Console gestionnaire : plus de second renouvellement de session concurrent (test ajouté). 3 maquettes dans docs/maquettes/.
- Vérifié : analyze propre, 1497 tests verts. Non vérifié : rendu réel (pas de Supabase local), déconnexion gestionnaire non reproduite.
- Décisions à prendre : docs/KYKY_QUESTIONS.md. Hors lot : docs/KYKY_A_TRAITER.md.
- Outils : Supabase CLI absente, docker sans démon.

## Session Kyky du 23/11/2026 (branche claude/gallant-babbage-2iz44v)

- Fait : habillage Pelouse sur toute l'appli (thème central clair, titres Lora, coque ordinateur avec rail + largeur 1080, bandeaux), captures dans docs/captures/ (téléphone + ordinateur), docs/PR_PELOUSE.md. Palette unique (pas de choix de couleur par club : autre session).
- Serveur local : docker + `supabase start -x studio,imgproxy,edge-runtime,logflare,vector,supavisor` (realtime inclus), données : supabase/demo/club_demo.sql (demoadmin / demojoueur, mot de passe choisi à l'exécution). Build web local : CSP à adapter (voir script de build), Playwright /opt/node-tools.
- Vérifié : analyze propre, tous les tests Flutter verts ; 198 tests SQL rejoués en local (sans écart réel ; écarts = version pgTAP locale et données de démo) ; aucun accès anonyme aux tables/fonctions, RLS partout.
- Non résolu : déconnexion gestionnaire (non reproduite), « Gestion sportive indisponible » sur lien direct quand le temps réel est coupé (docs/KYKY_A_TRAITER.md), remboursement total (Q5).
- Non fait : Edge Functions Stripe non exécutées (edge-runtime non démarré), compositions/live en édition non capturés, migration Riverpod 3, nettoyage poussé (aucun fichier orphelin trouvé).

## Règles impératives

1. **Écriture uniquement dans `samihchaa-wq/Application-football-`.** Ne jamais modifier les dépôts, données, sites ni bases Supabase d'AS Grinta original ou de Carte soirée. Le dépôt AS Grinta peut être consulté en lecture seule pour comparer ses fonctionnalités et son interface.
2. **Dépôt commercial PUBLIC maintenu** (choix explicite B). Ne pas modifier sa visibilité ni republier de données personnelles / secrets dans les PR et issues.
3. **Supabase commercial `jvxkhgdopslctpcjrhzw` : lecture seule par défaut.** Aucune migration, écriture, déploiement de fonctions, création de comptes tests distants, changement de secret, publication ou paiement sans accord distinct du propriétaire. Ne jamais lancer de commandes de suppression de schéma à l'aveugle, en particulier **`DROP SCHEMA install_tmp CASCADE`**, instruction obsolète et dangereuse.
4. Migrations déjà appliquées **immuables** ; chaque correction SQL doit être une nouvelle migration à identifiant unique, compatible avec le registre des migrations de la base commerciale.
5. Fusion de PR uniquement après revue des risques, absence de conflit et contrôles GitHub **verts sur le SHA exact**. Toute CI incomplète, échouée ou en cours bloque la fusion. **Attention : chaque push sur `main` (dont une fusion) déclenche `.github/workflows/auto_release_commercial.yml`, qui, après gardes et CI, peut lancer sauvegarde commerciale, migrations Supabase et publication Cloudflare.** Cela vaut aussi pour une PR de documentation ; l'autorisation d'intégrer ne doit pas être confondue avec l'autorisation d'intervenir sur la production. Sans validation explicite du lot et de ses conséquences, conserver les PR ouvertes.
6. Aucune dépense ou souscription sans annonce du prix et accord préalable. Réponses françaises, directes ; distinguer : documenté, développé, CI validée, testé réellement, déployé.

## Produit — décisions validées

Nom commercial **Petit Filet** (précédemment « Lucarne », changement intégré par PR #65). Application multiclub de football **à 11**, avec identité et maillots indépendants pour chaque club, « Homme du match » et emojis de badges préservés, objectif mai 2027. Tarif décidé le 18/11/2026 : **forfait de 79 € par club et par an**. Les paiements et les opérations commerciales restent à arbitrer.

**Décisions prioritaires nouvelles du 13/11 :**

- Issue [#66](https://github.com/samihchaa-wq/Application-football-/issues/66) : rendre les fonctions optionnelles héritées d'AS Grinta réellement réglables/désactivables par club, avec application côté serveur et conservation de l'historique.
- Issue [#67](https://github.com/samihchaa-wq/Application-football-/issues/67) : choisir des couleurs distinctes **joueurs et gardiens** pour chaque tenue, et afficher correctement ces couleurs avant, pendant et après chaque match, y compris en vidéo et historique.
- Issue [#68](https://github.com/samihchaa-wq/Application-football-/issues/68), PR [#105](https://github.com/samihchaa-wq/Application-football-/pull/105) : **aucun +1 automatique en liste d'attente** ; seuls les administrateurs utilisent +/−. La migration `20261116000000` avait réactivé les crédits au coup d'envoi. La PR #105 prépare une **nouvelle migration corrective**, sans remise à zéro des compteurs. **Le cron reste actif sur Supabase commercial tant que la nouvelle migration n'est pas appliquée avec autorisation distincte**. Voir [le diagnostic](changes/waitlist-admin-only-correctif-20261113.md).
- Issue [#70](https://github.com/samihchaa-wq/Application-football-/issues/70), PR [#72](https://github.com/samihchaa-wq/Application-football-/pull/72) : retrouver **exactement** l'Administration récente d'AS Grinta sur Petit Filet, hors adaptations obligatoires de sécurité multiclub. La PR est en validation Flutter/QA.
- Issue [#71](https://github.com/samihchaa-wq/Application-football-/issues/71) : **supprimer toute inscription « AS Grinta » des tribunes/public** de la vidéo de composition, sans ajouter de texte remplaçant ; traiter `stade.mp4`, `stade-720.mp4` et le poster `stade.jpg`. Pas encore traité dans les médias.

## Intégrations vérifiées pendant le 13/11

Fusionnées : #65 (nom Petit Filet), #33 (tests de charge fiables), #44 (garde migrations et conventions), #62/#64 (journal et indicateurs agents), #26 (registre QA), #29 (tableau de pilotage), #34 (identité), #35 (stratégie). Elles rejoignent les PR métier #23–#25, #46–#52 et #55–#60 précédemment fusionnées. **Les noms/références présents dans des documents datés sont historiques et non un état de production.**

Restent à vérifier sur GitHub avant intégration : PR #69 (+1 manuel), #72 (écran Administration), #36 (juridique) ainsi que les documents historiques #30/#31/#41/#53. **Ne pas considérer cette liste exhaustive après cette date : interroger GitHub.**

## GO/NO-GO et coordination

- **P0** : séparation réelle des clubs A/B avec permissions admin/RPC/RLS/Storage/Edge, contrôle d'un admin suspendu, sécurité des sauvegardes, restauration DB + objets Storage, RGPD/consentement.
- **P1** : tests smartphone/PWA, fiabilité des notifications et des e-mails, cohérence maillots, compositions et gestion des saisons ; vérifier la désactivation serveur des modules.
- **P2** : pilote volontaires, documents juridiques relus (SIRET, identité de l'éditeur), disponibilité de la marque et du domaine, paiement, hébergement adapté sans dépenses non autorisées.
- Site de test GitHub Pages existant ; la publication Cloudflare peut être déclenchée manuellement ou **automatiquement par le workflow de sortie sur chaque push `main`**, après contrôles. Vérifier les conséquences avant toute fusion, même documentaire.
- Les cinq automatisations de coordination couvrent les neuf missions M01–M09 ; utiliser `docs/CHANTIER.md` et les PR/issues pour communiquer. Ne pas déclarer « fait » sans résultat vérifiable.

**Ce document ne vaut ni autorisation de déploiement ni certification du lancement.**

## Outils Claude (session du 21/11/2026)

- Fusionné (PR #215) : Graphify (carte du code), caveman (style concis), Chrome DevTools MCP, compétences Supabase, grill-me, web-design-guidelines, ui-ux-pro-max. Publication automatique qui a suivi : verte.
- En attente de fusion (PR #216) : VibeSec, agent `eclaireur` (Haiku), sommaire `docs/INDEX.md`, cette section.
- Environnement cloud « Application-football » : installe Graphify et construit la carte au démarrage. À choisir à l'ouverture d'une session.
- Écartés après examen : Vercel (appli sur Cloudflare), Oh My Claude Code (trop lourd), claude-mem et Olmind (mémoire perdue dans le cloud, ou source invérifiable), Find Skills (installe sans relecture), anti-ai-slop/hallmark (sites web neufs, pas Flutter).
- **À faire ensuite, à la demande de la personne qui pilote** : chercher d'autres compétences utiles à Petit Filet (Flutter, direction artistique, accessibilité, fonctionnalités d'appli sportive). Les lire avant installation, en recommander peu, éviter les doublons avec l'existant.

## 23/11/2026 — Habillage « Nuit » (sombre) — état
- Pelouse (PR #221) est en ligne mais jugé décevant. Kyky supprimé (agent retiré).
- Branche `claude/gallant-babbage-2iz44v` : thème sombre « Nuit » (fond nuit, rouge/ambre, titres Oswald fins), cartes en billets (liseré + dégradé selon le type de match), relief, bouton en volume, barre du bas flottante, bandeaux fins, cartes Effectif/Composition compactées.
- Captures : `docs/captures_nuit/`. Maquettes : `docs/maquettes_v2/`.
- Vérifié : 1501 tests, analyse, formatage, rendu web local (téléphone + ordinateur) pour Calendrier, Prochain match, Match terminé, Statistiques, Effectif, Profil, Paramètres, Notifications, Liste d'attente, Armoire.
- Pas vérifié : vrai téléphone ; direct, compositions en édition, écrans légaux et connexion en style sombre.
- Pas fait : halo/bandes de fond (risque de page « fantôme » aux transitions), PR du thème Nuit (à demander par la propriétaire), Riverpod 3, test réseau/charge, bug déconnexion gestionnaire non reproduit.

## 23/11/2026 (soir) — Audit de préparation + correctif (branche `claude/festive-tesla-mluqsd`)
- Audit : analyse propre, tests verts, base en ligne à jour (81/81), cloisonnement vérifié en lecture seule (règle restrictive par club sur les tables, fonctions privilégiées toutes sous rôle cloisonné ou relues). Le garde-fou automatique existe déjà (test club_isolation + security_definer_exposure) : rien à ajouter.
- Corrigé : « Gestion sportive indisponible » pendant chaque relecture des réglages (reprise, notification, actualisation). Test ajouté, 1 504 tests verts. Non vérifié sur vrai téléphone.
- Réglé le 23/11 au soir : petitfilet.fr et www.petitfilet.fr (http et https) renvoient en 301 vers https://app.petitfilet.fr/ (règle de redirection Cloudflare « petitfilet.fr vers l'appli », vérifiée). L'appli reste sur app.petitfilet.fr.
- Constats non traités : balise de statistiques Cloudflare bloquée par la CSP ; robots.txt renvoie la page de l'appli ; ~4 Mo au premier chargement.
- Bloquants vente inchangés : identité éditeur/SIRET vides dans les textes légaux, aucun paiement ni événement Stripe jamais reçu en production, aucun essai sur vrai téléphone, restauration des photos jamais prouvée (#91), protection de main (#45) non vérifiée.

## 24/11/2026 — Audit, 2e passe (hors légal, paiement test, téléphone)
- Production (lecture seule) : seul club = **FC Démo** (aucun club client). 16 tâches planifiées, 0 échec sur 7 j. Aucun accès anonyme (tables, fonctions, fichiers). Aucun secret dans l'historique du dépôt public (838 commits). Fonctions sans connexion relues (account-email, calendar-feed) : limites de fréquence, jetons comparés en temps constant, pas de fuite d'existence de compte.
- Local (copie + club démo, appli construite) : 33 écrans admin + 18 joueur, 0 erreur appli/serveur ; 320 px correct. 1 bouton sans nom (Profil), boutons « Afficher le menu » indiscernables au lecteur d'écran.
- Corrigé sur cette branche : exercice de restauration (échouait car un seul club ; la restauration elle-même est bonne : 130 tables, 3 822 lignes, 6 s) ; surveillance horaire du site et du service de connexion (avant : base seulement).
- Ouvert : remise à zéro de la démo échoue chaque nuit (secret GitHub `DEMO_PASSWORD` absent) ; iPhones abonnés avec l'ancienne clé push → échec 400 « VapidPkHashMismatch » à chaque envoi tant qu'ils n'ont pas rouvert l'appli (classé « permanent », abonnement gardé) ; 1re ouverture 8 s en bonne 4G, 22 s en réseau faible (2-3 s ensuite) ; rapports d'erreur perdus pour un compte sans club (club_isolation sur client_incident_log) ; get_club_rules ~90 ms à chaque ouverture.
- Corrigé ensuite sur la même branche : abonnement push refusé pour mauvaise clé → retiré (le téléphone se réabonne à l'ouverture) ; compte sans club → incident ignoré sans erreur (migration 20261205000000, test pgTAP) ; get_club_rules en une requête (31 ms → 1 ms en local, résultat identique ; migration 20261205010000) ; accessibilité (date de naissance, « Actions pour <nom> ») ; robots.txt ; balise mobile-web-app-capable ; préchargement de main.dart.js et flutter_bootstrap.js (gain local 0,6 s, à mesurer en production) ; message de chargement lent rassurant à 15 s, « Recharger » seulement à 45 s.
- Écarté après mesure : découper le code (Flutter + Dart = 2/3 du poids, gain ~1 s sur 19 en réseau faible).
- Suite pgTAP complète rejouée en local : écarts = version pgTAP locale (codes d'erreur corrects, texte attendu différent) et données de démo ; aucun fichier en échec ne touche aux fonctions modifiées. La CI fait foi.
- Reste à la propriétaire : secret GitHub DEMO_PASSWORD ; Web Analytics Cloudflare (couper, ou l'autoriser dans la CSP) ; Riverpod 3 et mises à jour majeures (go_router, share_plus, connectivity_plus) = chantier séparé.

## 24/11/2026 — Audit, 3e passe (parcours complets en local, PR #231)
- Testé de bout en bout sur copie locale (fonctions lancées avec Deno, e-mails capturés par un faux service) : inscription (cas d'erreur clairs ; e-mail obligatoire ; limites de fréquence ; code d'invitation non devinable), confirmation d'e-mail (2e compte même adresse refusé), mot de passe oublié (seulement compte validé), validation par l'admin, 1re connexion, photo (« Autre » ; « Type joueur » exige un PNG détouré), export « mes données » (rien d'un autre membre), suppression de compte, réponse Présent/Absent vue par l'admin, version ordinateur 1280/1920 px.
- Corrigé : fuite par le temps de réponse de « mot de passe oublié » (envoi après la réponse) ; inscription sans preuve de consentement possible si profil hors du club annoncé (échoue et supprime) ; noms complets dans « En attente » ; écran admin d'un match rafraîchi en direct sur signal sportif ; en-têtes de statistiques nommés ; « Cet appareil » dans le bandeau ; Permissions-Policy ; versions épinglées des types Edge Runtime.
- Non testé de bout en bout : le direct (exige réponses, convocations, compo publiée) ; e-mails réels via Brevo ; vrai téléphone.
- Base locale : `private.local_default_club` capte les inscriptions (normal en local, absent en production — vérifié).
