# Journal Kyky Écrans

## 23/11/2026 13:20 — passage 1 (aucun code changé)
- Décision propriétaire (23/11/2026) : direction visuelle « Nuit ». Elle remplace l'attente de KYKY_QUESTIONS Q1.
- Bloqué : SDK Flutter absent de l'environnement, téléchargement refusé (storage.googleapis.com bloqué par le proxy). Donc : pas d'analyse, pas de tests, pas de build web, pas de capture Playwright. Écrire du code d'écran sans le vérifier = interdit.
- Bloqué : `.claude/agents/kyky.md` n'existe plus (Kyky supprimé, commit 48377f4). Règles de lot lues dans la consigne seulement.
- Bloqué : Graphify absent (pas de graphify-out/, commande introuvable).
- Branche claude/kyky-ecrans créée depuis main. Le thème Nuit existe déjà sur claude/gallant-babbage-2iz44v (interdit de la refaire). Main a encore Pelouse.
- Reste à faire (moi) : dès qu'un environnement avec Flutter existe, reprendre écran par écran, ordinateur 1440 px d'abord.
- Décisions/actions propriétaire : (1) autoriser storage.googleapis.com et github.com/flutter dans les domaines autorisés, ou brancher l'environnement cloud « Application-football » ; (2) dire comment récupérer Nuit sans refaire gallant-babbage (PR Nuit ? base de ma branche ?).

## 23/11/2026 14:40 — passage 2 (aucun code changé)
- Débloqué : storage.googleapis.com et pub.dev autorisés par la propriétaire. Flutter 3.50.1 (Dart 3.14) cloné dans /tmp/flutter, fonctionne.
- Nuit déjà sur main (PR #223 fusionnée). Ma branche = main + journal.
- Vérifié : analyze 0 erreur, 0 alerte (317 infos « déprécié », dues à Flutter plus récent que celui du projet). Tests : 1501 verts, 1 rouge.
- Hors périmètre : test « lettres accentuées restent autorisées » (test/core/security/password_policy_test.dart) échoue. Logique de mot de passe, voir Fonctions. Gravité : moyenne (cause non cherchée, peut venir de la version Dart).
- Bloqué : docker sans démon, Supabase CLI absente → pas d'appli avec données, donc pas de capture réelle des écrans.
- Reste à faire (moi) : monter les écrans avec de fausses données (build web + Playwright, réseau simulé) pour capturer ordinateur 1440 px. Non vérifiés en Nuit : direct, compositions en édition, légaux, connexion.

## 23/11/2026 16:15 — passage 3 (aucun code changé)
- Bloqué : Flutter n'est plus là (conteneur neuf). Réinstallation (clone Flutter 3.50.1) et `pip install graphifyy` refusés par le contrôle de sécurité de la session. Graphify absent aussi.
- Sans Flutter : pas d'analyse, pas de tests, pas de capture. Écrire du code d'écran sans vérifier = interdit.
- Décision propriétaire : autoriser l'installation de Flutter (clone github.com/flutter, 3.50.1) et de graphifyy (déjà accordé dans la charte §0) dans cette session, ou fournir un environnement avec Flutter préinstallé.
- Reste à faire (moi) : écrans en Nuit, ordinateur 1440 px d'abord, avec fausses données + capture Playwright.

## 23/11/2026 17:15 — passage 4 (aucun code changé)
- Bloqué : même refus qu'au passage 3. Installation de graphifyy (autorisée par la charte §0) et clone Flutter refusés par le contrôle de sécurité de la session. Pas contourné.
- Sans Flutter : pas d'analyse, pas de tests, pas de capture. Aucun écran touché.
- Décision propriétaire : autoriser dans les réglages de la session l'installation de Flutter 3.50.1 et de graphifyy, ou fournir un environnement avec Flutter préinstallé. Tant que non fait, les passages suivants s'arrêtent ici.
- Reste à faire (moi) : écrans en Nuit, ordinateur 1440 px d'abord, fausses données + capture Playwright.
