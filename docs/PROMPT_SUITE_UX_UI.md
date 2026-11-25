# Prompt de relais — suite du chantier UX/UI de Petit Filet

À coller tel quel au début d'une nouvelle session d'assistant (Claude Code ou
autre). Rédigé le 25/11/2026, après les PR #234, #239, #242, #243, #244 et #245.

---

## 1. Ton rôle et la personne

Tu reprends un chantier d'amélioration visuelle (UX/UI) de **Petit Filet**,
application mobile (PWA) de gestion d'équipe de football amateur, écrite en
Flutter, base Supabase.

La personne qui pilote **a les bases en informatique mais n'est pas
développeuse**. Réponds en français, phrases courtes, sans jargon non traduit.
Dis d'abord le problème et ce que ça change pour elle, puis la solution. Sépare
ce que tu peux faire de ce qu'elle doit faire. Ne dis jamais que quelque chose
marche sans l'avoir vérifié ; dis ce qui n'a pas été testé et pourquoi. Elle
teste sur un **iPhone** et t'envoie des captures : ce sont tes retours les plus
fiables.

Lis d'abord `CLAUDE.md` et `docs/INDEX.md`, puis `docs/HANDOFF.md` (sections
« Correctifs du 25/11/2026 » et « Session UI UX Pro Max ») et
`docs/AUDIT_UX_UI_20261124.md` (le rapport d'audit complet).

## 2. Outils à utiliser

- **Le skill `ui-ux-pro-max`** (`.claude/skills/ui-ux-pro-max`). Il faut
  réellement lancer son moteur de recherche, pas seulement le citer :
  `python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<requête>" --domain ux`
  (ou `--stack flutter`). Règles utiles : `references/quick-reference.md`
  (priorités 1 à 10) et `references/pro-rules.md` (liste de contrôle avant
  livraison). Une requête = une intention, 2 à 5 mots.
- **Flutter** (`flutter analyze`, `flutter test`), Python 3, Playwright
  (préinstallé : `require('playwright')`), Docker + Supabase CLI locale.
- **Outils GitHub MCP** (`mcp__github__*`), pas de `gh` sauf pour la recherche.
  Dépôt : `samihchaa-wq/Application-football-`.
- **Le graphe du code** : `graphify query "<question>"` avant de fouiller les
  fichiers (voir `CLAUDE.md`).
- Pour les lectures et recherches simples, l'agent `eclaireur` (moins cher).

## 3. Règles impératives (ne jamais enfreindre)

1. Branche de travail : `claude/lucid-cannon-s0z1fc` (ou celle que la session
   t'impose). **Ne jamais pousser ailleurs.**
2. **Chaque fusion sur `main` déclenche la mise en ligne automatique** (sauvegarde
   de la base, migrations, publication). Ne fusionne jamais toi-même : la
   personne le fait. Une PR de documentation déclenche aussi la mise en ligne.
3. **Aucune migration SQL, aucune écriture sur le Supabase commercial** sans
   accord explicite. Pour tester, utilise le Supabase **local** (voir §6).
4. Ne modifie jamais AS Grinta original ni Carte soirée.
5. Pas de PR sans que la personne l'ait demandée ; elle l'a demandé pour tout
   ce chantier (une PR par lot). Avant d'ouvrir une PR : `git fetch origin main`,
   fusionner `main` dans la branche, relancer analyse + tests, vérifier avec
   `git diff --name-only origin/main...HEAD` qu'il n'y a rien d'inattendu.
6. Ne mets pas le nom du modèle dans les commits ni les PR. Termine les commits
   et PR par les lignes de signature demandées par la session.
7. Ne pas « simplifier » le fond : un vrai problème est signalé même s'il est
   pénible à expliquer.

## 4. Ce qui a déjà été fait (ne pas refaire)

**PR #234 / #239 / #242 (lots 1 à 3)** : bandeau notifications raccourci,
alertes rouges lisibles, légende des abréviations des statistiques, onglets
sélectionnés d'un seul rouge, fin des fonds gris hérités du thème clair, titre
« Banc (n) », en-tête de match compact partout, direct (rappel du match,
« buteur à désigner » visible, confirmations expliquées), page Saison, Présent /
Absent (vert plein), maillot choisi (cadre + coche), boutons du formulaire
« Ajouter » lisibles, couleurs des bulles de match (championnat bleu foncé,
amical bleu clair, entre nous violet foncé, événement or ; contraste testé).

**PR #243 (lots A à E de l'audit)** : bandeau « notifications bloquées »
seulement sur le Calendrier + point jaune sur la cloche ; `PfButtonStyles`
(le thème peint un **dégradé rouge sur tout bouton plein**, il écrase
`backgroundColor` : utiliser `PfButtonStyles.solid/danger/success`) ; 19
confirmations destructives en style danger, boutons nommés d'après l'action
(plus de « Oui/Non ») ; un seul vert/jaune/rouge pour les résultats
(`AppTheme.resultWin/Draw/Loss`) ; pastilles à 11 px ; 330 icônes ramenées à la
famille `_outlined` + 32 icônes redondantes retirées ; textes raccourcis
(liste d'attente, maillots, parrainage, abonnement au calendrier, indisponibilité) ;
groupes vides de l'Effectif masqués ; date des cartes « Dim. 22 nov. 2026 » ;
indice de défilement des tableaux (dégradé + flèche) ; barre du bas icône +
texte ; navigation latérale en paysage (écran < 500 px de haut) ; couleurs du
thème dans pronostics / direct / historique.

**PR #244** : correctif du service worker (`web/sw.js`) — la **police des
icônes** ne contient que les icônes de la version qui la produit ; servie depuis
l'ancien cache après une mise en ligne, elle faisait manquer les icônes
nouvelles (Statistiques, Présent, certaines lignes de Paramètres) sur iPhone.
Maintenant : polices et manifestes d'assets passent par le réseau d'abord
(test de contrat dans `test/web/pwa_contract_test.dart`). Cloche et crayon des
cartes du calendrier en bas de carte (`CalendarCardFooter`) ; Présent / Absent
façon « ancienne version » (fond translucide + icône, choisi = aplat vert/rouge
profond, `AppTheme.availabilityInSolid/OutSolid`) ; icônes remises sur les 3
lignes légales de Paramètres.

**PR #245** : historique des notifications — corbeille visible au lieu du
glissement (il coinçait une ligne à moitié sortie) ; « Envoyer une
notification » non coupé (boutons l'un sous l'autre) ; tableaux : titres de
colonnes en blanc, colonne triée en rouge (`primaryBright`) au lieu de l'orange,
onglets secondaires non choisis en blanc.

**Lot en cours de PR (typographie)** : espace insécable (` `) avant « ? »
en fin de phrase dans les textes affichés (69 textes) — évite le « ? » seul en
début de ligne.

## 5. Ce qui reste à faire (par ordre recommandé)

Une PR par lot, petite et vérifiable. Pour chaque lot : lancer la recherche du
skill, coder, `flutter analyze`, `flutter test`, **capturer l'écran avant /
après**, enregistrer, PR.

- **F — Légende du classement Prono.** Sur la carte de pronostic, les trois
  nombres « 1 124 / N 933 / 2 1120 » sont des points ×100 (`AppFormats.odds`).
  **Confirme le sens avec la personne avant d'ajouter la légende.**
- **G — Texte agrandi.** Un balayage a été préparé mais jamais terminé (la
  machine a redémarré) : `flutter test --dart-define=PF_TEXT_SCALE=2 --no-pub`
  (mode défini dans `test/flutter_test_config.dart`, hors CI). Compter les
  échecs, corriger les vrais débordements (pas les tests qui comparent des
  tailles). Durée ≈ 10 min : le lancer en arrière-plan. Règle du skill :
  `dynamic-type`, éviter la troncature.
- **H — Cibles tactiles.** 9 endroits à moins de 44 px (cloche, trophée, roue
  crantée, +/- de score du pronostic, avatars de l'effectif…) :
  `grep -rn "minWidth: 40\|minHeight: 40" lib`. Agrandir la zone, pas
  forcément le dessin.
- **I — Statistiques en paysage.** Une seule ligne de tableau tient encore
  (en-têtes + deux rangées d'onglets + légende). Idée : replier la légende et
  la rangée « Actuelle / Précédente / Toutes » en paysage.
- **J — Marges de page.** 8, 12, 14, 16, 18, 20 ou 24 px selon l'écran. Un essai
  global à 16 px a **fait déborder la fiche joueur** (annulé). À faire écran
  par écran, avec test de largeur 320 px.
- **K — Formulaires.** Sur 99 champs : 27 ont `keyboardType`, 9 `autofillHints`,
  19 `textInputAction`. Compléter (identifiant, e-mail, téléphone, mot de
  passe, nombres), traversée du focus avec « Suivant », libération des
  `TextEditingController`. Skill Flutter `forms-and-input`.
- **L — Mouvement réduit.** 19 mentions de `disableAnimations` pour 6
  `AnimationController` : vérifier que chaque animation décorative respecte le
  réglage système.
- **M — Libellés de réglages en double** (« Notification : match annulé ou
  déplacé » / « … annulation ») : ils viennent de la base
  (`supabase/migrations/20261119000000_comprehensive_club_settings.sql`).
  **Demande une migration : ne rien faire sans accord explicite.**
- **N — À trancher avec la personne** : deux rangées d'onglets des
  statistiques (Joueurs/Équipe/Prono puis Actuelle/Précédente/Toutes) ; garder
  ou non des icônes sur les 10 sections des Réglages du club (retirées pour
  l'instant) ; boutons principaux qui gardent une icône à cause du spinner de
  chargement (composant commun à créer).

Hors périmètre : le texte « from Petit Filet » des notifications iPhone est
ajouté par iOS pour toute appli web, aucun réglage ne le retire.

## 6. Comment tester (copier-coller)

```bash
# Base locale (le démon Docker s'arrête entre deux échanges : relancer)
dockerd >/tmp/dockerd.log 2>&1 &
npx supabase start -x studio,imgproxy,edge-runtime,logflare,vector,supavisor
# Club de démo (comptes demoadmin / demojoueur, mot de passe de ton choix, 12+ car.)
docker exec -i <conteneur supabase_db> psql -U postgres --single-transaction \
  -v ON_ERROR_STOP=1 -v demo_password='...' -v username_domain=comptes.club-app.local \
  -f - < supabase/demo/club_demo.sql
# Construction web contre la base locale (JSON de config avec SUPABASE_URL
# http://127.0.0.1:54321 et la clé anon locale, voir `npx supabase status`)
flutter build web --release --no-web-resources-cdn \
  --dart-define-from-file=<config locale>.json --dart-define=APP_VERSION=dev -o <dossier>
# Adapter la politique de sécurité de index.html : remplacer
# https://a-remplacer.supabase.co par http://127.0.0.1:54321 (et wss:// par ws://)
# Servir le dossier sur http://127.0.0.1:8081 avec un petit serveur qui renvoie
# index.html pour les routes inconnues, puis capturer avec Playwright
# (viewport 375×812, 320, 1280×800, 812×375 paysage).
```

- Les champs Flutter web sont dans l'arbre d'accessibilité : cliquer
  `flt-semantics-placeholder`, puis remplir `input` (utiliser `fill`, pas des
  frappes lentes : un caractère se perd).
- Le navigateur **ne simule pas** le texte agrandi : utiliser le mode de test
  `PF_TEXT_SCALE`.
- Données de démo : club « FC Démo », match du 29/11 et du 02/12 à venir ; pour
  voir le direct, décaler `kickoff_at` **dans la base locale uniquement** et
  rendre le compte démo coach (`season_players.is_coach`).
- Piège connu : un `rm` sur un dossier avec joker est refusé par la sécurité de
  l'outil ; ne supprime rien, écrase les fichiers.

## 7. Pièges techniques déjà rencontrés

- Le dégradé rouge du thème sur `FilledButton` : voir `PfButtonStyles`.
- Les fichiers `part of 'xxx.dart'` n'acceptent **aucun** `import` : l'ajouter
  dans le fichier parent (`admin_page.dart`, `pronos_hub_page.dart`,
  `admin_squad_plan_page.dart`).
- `double.fromEnvironment` n'existe pas : utiliser `String.fromEnvironment` +
  `double.tryParse`.
- Les tests qui lisent le **code source** (`readAsStringSync`) comparent du
  texte brut : un ` ` y est la suite de caractères ` `, pas une espace
  insécable ; utiliser une chaîne brute `r'...'`.
- Un script de remplacement en masse doit être **restreint** (le premier
  remplacement des « ? » a cassé des opérateurs conditionnels dans des textes) :
  toujours lancer `flutter analyze` + `flutter test` juste après, et annuler
  avec `git checkout -- lib test` si besoin.
- Après une fusion, `main` avance vite (autres sessions) : toujours
  `git fetch` + fusion avant la PR ; en cas de conflit sur un fichier que
  l'autre session a aussi corrigé, garder la version de `main` si elle fait la
  même chose.
- Limite d'images par conversation : assembler plusieurs captures en une
  planche (Pillow) avant de les lire.

## 8. Format de la réponse attendu

Trois lignes maximum quand c'est possible : ce qui change pour l'utilisateur,
ce qui a été vérifié (ou pas), ce que la personne doit faire (en général :
fusionner la PR). Le détail va dans la PR, pas dans la conversation.
