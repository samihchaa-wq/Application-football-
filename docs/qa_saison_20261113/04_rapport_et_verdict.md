# Rapport de recette intégrale — Petit Filet
_Date des constats : 13 novembre 2026 — branche `main` (SHA `2dc59830baf986e6a7d4b6fa93aabcf9869b17b9`) — **rapport partiel, sans faux tests**._

## 1. Verdict en cinq lignes

1. **NON VALIDÉ pour un vrai club** : aucune saison complète n'a été jouée avec un compte réel dans cette mission.
2. Le projet commercial est accessible via GitHub et Supabase en lecture seule : deux clubs de test sont présents, mais les données sont insuffisantes pour 300 + 30 matchs.
3. Les 164 éléments de la grille métier et les fonctions SQL sont inventoriés, pas validés à l'écran.
4. Les tests CI historiques existent ; ils ne prouvent ni le parcours réel à deux clubs, ni le bon fonctionnement d'un téléphone et de ses notifications.
5. La sécurité de session, le Live, la cohérence de fin de saison, les droits et les performances demandent encore une recette bout en bout avant lancement.

## 2. Périmètre et état constaté dans la base (SELECT uniquement)

| Élément | Club Test A | Club Test B | Mode de vérification |
|---|---:|---:|---|
| Clubs présents | oui | oui | DB (lecture) |
| Comptes/profils | 21 | 21 | DB (lecture) |
| Joueurs inscrits à la saison 2026-2027 | 21 | 21 | DB (lecture) |
| Matchs programmés | 2 | 2 | DB (lecture) |
| Matchs historiques détaillés | 1 | 1 | DB (lecture) |
| Invités | 1 | 1 | DB (lecture) |
| Sessions Live enregistrées | 0 | 0 | DB (lecture) |
| Pronostics enregistrés (lignes) | 42 | 42 | DB (lecture) |
| Saison ouverte | oui | oui | DB (lecture) |
| Badges définis | 67 | 67 | DB (lecture) |
| Comptes en attente/archivés | aucun parmi les 42 profils, selon `profiles.status` | idem | DB (lecture) |
| Effectif cible de 25 joueurs | **non atteint** | hors scénario | DB (lecture) |
| Historique cible de 300 matchs | **non atteint** | hors scénario | DB (lecture) |
| Saison simulée de 30 matchs | **non exécutée** | hors scénario | NON VÉRIFIÉ |

Identité constatée : Club Test A (nom court `CTA2`, couleurs `#7CB518` et `#FFFFFF`, logo absent, maillots JSON présents) ; Club Test B (`CTB2`, couleur `#1A4AC0` pour les deux couleurs, logo présent, maillots JSON présents). Les deux sont dans le fuseau `Europe/Paris`. Les deux saisons sont `2026-2027` et ouvertes.

**État laissé : strictement inchangé par cette mission.** Aucun compte, match, profil, badge ou réglage créé ou modifié ; aucun horaire avancé ; aucune clôture ; aucune suppression ; aucune écriture SQL ; aucune migration. Ces nombres sont un instantané : d'autres intervenants peuvent agir entre-temps.

## 3. Grilles détaillées

- [01_grille_metier.md](01_grille_metier.md) : 164 fonctionnalités métier, 30 cycles de rencontre, statuts individualisés.
- [02_serveur_badges_reglages.md](02_serveur_badges_reglages.md) : 257 signatures SQL publiques, 8 fonctions Edge, 67 badges A, modules, règles, notifications et 8 profils de permission.
- [03_ecrans_routes.md](03_ecrans_routes.md) : 42 fichiers d'écran et 48 déclarations de routes.
- [ui_lots/](ui_lots/) : repérage statique des widgets interactifs disponible par lots lorsqu'un fichier a été effectivement lu. **Ce repérage ne remplace pas le recensement des boutons réellement affichés**.

**Méthode obligatoire pour chaque entrée :** `OK` si écran et résultat DB/serveur contrôlés, `KO` si anomalie reproduite et documentée, sinon `NON VÉRIFIÉ`. Les grilles initiales utilisent donc `NON VÉRIFIÉ` : aucune validation E2E ne peut être honnêtement revendiquée.

## 4. Défauts, écarts et blocages — gravité distincte de la preuve

### Bloquant pour certifier la recette (pas un bug de l'application démontré)

**QA-B01 — Impossible d'exécuter la saison demandée depuis cet environnement.**
- Reproduction : tentative de lecture publique de `https://petit-filet.pages.dev/` sans restitution exploitable ; pas d'outil de navigateur interactif connecté ; dans le conteneur, pas d'accès réseau à GitHub/Cloudflare et pas d'exécutable `flutter`/`dart`.
- Attendu : ouvrir l'application, se connecter comme `alphat`, jouer matchs et variations d'identité.
- Obtenu : accès au code et à la DB en lecture seule, **pas d'accès à une session UI utilisable**, et impossibilité de lancer le projet localement avec ce runtime.
- Capture : **aucune** ; la restitution d'erreur n'est pas une capture applicative.
- Cause probable : limites d'accès/outillage de cette session, **pas une défaillance du produit prouvée**.
- Suite : exécuter la campagne via navigateur contrôlable, session de test autorisée et Flutter disponible ; réserver les écritures à l'application. Aucun correctif applicatif ne peut être justifié sur ce constat seul.

**QA-B02 — Données de campagne insuffisantes.**
- Reproduction : SELECT en lecture sur profils, effectifs, historique et matchs de A.
- Attendu : au moins 25 joueurs, 300 matchs d'historique et 30 matchs de saison prêts.
- Obtenu : 21 profils, 1 historique détaillé, 2 matchs programmés ; aucun déroulé de saison exécuté.
- Capture : **non applicable (contrôle SQL)** ; les nombres figurent au §2.
- Cause probable : préparation de campagne non encore effectuée ; **aucun bug déduit**.
- Suite : compléter uniquement via formulaires/RPC normaux après accès admin, mesurer chaque phase. Ne pas remplir la base avec des INSERT administrateur.

### Gênant / couverture à clarifier (constat de code ou de dépôt, pas KO écran)

**QA-G01 — Rencontre « coupe » demandée mais type absent dans le modèle courant.**
- Reproduction : lire `lib/features/matches/domain/match_model.dart` sur `main`, les variantes trouvées sont `championnat`, `amical`, `entre_nous` ; la documentation d'audit D01 fait la même distinction.
- Attendu (scénario de recette) : créer une rencontre de coupe.
- Obtenu dans le code : **pas de type `coupe` défini**. Le comportement de l'interface reste **NON VÉRIFIÉ**.
- Capture : **aucune capture écran**.
- Cause probable : type de compétition non implémenté à ce jour.
- Correction proposée : décision explicite sur l'ajout d'un type `coupe`, puis modèle, formulaire, stockage, classements et tests ; ne pas forcer une rencontre coupe à travers une valeur incompatible.
- Statut : lacune de périmètre, **pas bug observé à l'écran**.

**QA-G02 — Chemin de rapport de cloisonnement cité mais absent.**
- Reproduction : demander le fichier `tests/cloisonnement/rapport.md` sur `main` → GitHub répond 404. Le dépôt contient des tests dans `test/` et `supabase/tests/`, et le document `docs/M04_TEST_HTTP_DEUX_CLUBS_20261113.md` décrit une campagne locale.
- Attendu : pouvoir consulter le rapport de comptes fictifs à utiliser comme scénario.
- Obtenu : fichier à ce chemin **introuvable** ; aucune identité ni aucun mot de passe copié dans ce rapport.
- Capture : **aucune capture écran** (404 côté GitHub).
- Cause probable : chemin déplacé, jamais créé ou documentation non synchronisée.
- Correction proposée : créer un index non secret vers les comptes/tests d'intégration ; ne jamais publier les identifiants confidentiels dans un dépôt public.
- Statut : défaut de documentation / prérequis, pas panne prouvée de l'application.

### Cosmétique

Aucun défaut cosmétique **reproduit et capturé dans cette mission**. Les contrastes, photos maillots, compositions et vidéo de stade restent **NON VÉRIFIÉS**.

### Surveillance sécurité (aucune vulnérabilité affirmée)

L'analyse Supabase remonte **164 avertissements** de fonctions `SECURITY DEFINER` exécutables par utilisateurs authentifiés ; cela ne démontre pas une fuite. Ces signatures doivent être éprouvées avec les droits réels A/B, y compris fonctions historiques. Une CI locale verte n'établit pas la sécurité de la configuration distante. Voir [documentation officielle du linter](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

## 5. Travail pratique non réalisé, prérequis et tests de charge

| Parcours souhaité | État | Prérequis/protocole |
|---|---|---|
| 25 joueurs, coach, invité, archivé, en attente, numéros, photos | NON VÉRIFIÉ | Session admin A, créer exclusivement par écran |
| 300 historiques : scores, buteurs, compositions, temps de saisie | NON VÉRIFIÉ | Formulaire d'archives, jeu fictif, chronométrage, DB SELECT |
| 30 journées : présence, attente, convocations, compositions, pronos | NON VÉRIFIÉ | Comptes joueurs A, calendrier complet, créneaux test |
| Live complet piloté coach puis admin | NON VÉRIFIÉ | Deux sessions authentifiées simultanées, capture événements |
| Corrections hors fenêtre et fuseau horaire | NON VÉRIFIÉ | Dates pilotées par UI si possible ; horloge de copie isolée sinon |
| Badges, stats, classement recalculés de façon indépendante | NON VÉRIFIÉ | Export des résultats par match et calcul séparé |
| Notification reçue puis coupée pour tous les types | NON VÉRIFIÉ | iOS PWA installé, Android Chrome, navigateur desktop, permission push |
| E-mail de création et récupération de compte | NON VÉRIFIÉ | Boîtes mail de test accessibles et environnement authentifié |
| Cloisonnement REST/RPC/Storage/Realtimes A ↔ B | NON VÉRIFIÉ sur production | JWT fictifs authentifiés A/B + capture réponses |
| Erreurs réseau/double clic/deux admins simultanés | NON VÉRIFIÉ | Navigateurs à états séparés, réseau dégradé |
| Téléphone étroit, contraste sombre/clair/bleu, mode sombre | NON VÉRIFIÉ | iPhone/Android réels, captures de chaque écran |
| Temps calendrier/statistiques/classement à 330 matchs | NON VÉRIFIÉ | Jeu de données effectif, chronométrage répétable |
| Parité écran par écran avec AS Grinta | NON VÉRIFIÉ | Référence AS Grinta en **lecture seule**, inventaire de captures |
| Clôture sur copie jetable + Wrapped pour chaque joueur | NON VÉRIFIÉ | Copie isolée autorisée ; **ne jamais clôturer A** |

Une campagne de charge simulée de 200 clubs, 6000 comptes et 50 clients est **documentée dans le dépôt** ; elle n'est ni une mesure de ces écrans, ni une preuve de 6000 utilisateurs simultanés sur la production. Aucun chiffre de performance du site Petit Filet réel n'est présenté ici.

## 6. Fin de saison à vérifier avant toute action sur A

Le code et le schéma font apparaître le mécanisme d'archivage, la fonction `award_season_titles`, les données `season_awards` et `season_wrapped`, la page de bilan partageable, des badges/titres de saison et une option de musique. **Ordre réel, déclenchement, musique disponible, génération complète, absence de doublon et résultats individuels : NON VÉRIFIÉS.** Une liste d'éléments présents n'est pas une garantie de ce qui arrivera à la clôture.

Procédure attendue : jouer les 30 matchs, vérifier toutes les lignes de la grille et laisser A à l'état « prêt à clôturer » ; cloner uniquement sur une infrastructure jetable autorisée ; vérifier clôture unique, titres, bilans, médias, verrou et retour d'erreur ; laisser au propriétaire l'action de clôture réelle du Club Test A.

## 7. Conditions de passage à « prêt pour vrai club »

Aucune permission indue A/B ; aucun compte suspendu/archivé actif ; chaque module stoppé en UI et au serveur ; statistiques reproductibles ; cohérence composition–Live–résultat ; notifications et e-mails réellement reçus ; clôture saine sur copie ; 30 matchs parcourus et 300 historiques chargés via l'application ; iOS/Android/PWA et charge mesurés. Chaque preuve sera jointe à la grille avec une capture et un résultat de base anonymisé.

**Aucune PR de correction de défaut applicatif n'est ouverte sur la seule base d'une suspicion.** Une petite PR et son test automatique ne seront justifiés qu'après reproduction réelle ou démonstration contrôlée du défaut. Les documents de recette sont isolés sur une branche non fusionnée.

## 8. Journal des actions de cette mission

- Consultation de `main`, `docs/AUDIT_FONCTIONNALITES_DETAILLE.md`, de la matrice 164, du routeur, des widgets et de la logique des règles/notifications.
- Exécution de SELECT uniquement sur le projet Supabase commercial `jvxkhgdopslctpcjrhzw`.
- Consultation du statut des fonctions Edge, de l'advisor sécurité, des workflows GitHub et des documents de tests HTTP existants.
- Création d'une branche GitHub dédiée aux **seuls documents de recette** et préparation d'une PR non fusionnée.
- **Aucune modification du dépôt ou de la base AS Grinta, aucune action sur Carte soirée.**
