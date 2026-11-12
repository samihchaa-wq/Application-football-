# Relais entre assistants — Lucarne (version commerciale)

**Mis à jour le 12/11/2026, vers 16 h 14 (heure de Paris).** Ce document résume les règles stables et l'état **GitHub vérifié**. Recontrôler les PR, les checks et le registre Supabase à chaque reprise. Ne jamais déduire d'une fusion de code qu'une migration ou un déploiement distant a eu lieu.

## Règles impératives

1. **Seul dépôt modifiable :** `samihchaa-wq/Application-football-`. Les dépôts, bases, secrets, sites et données d'**AS Grinta original** et de **Carte soirée** sont hors périmètre absolu.
2. **Décision propriétaire B : dépôt commercial PUBLIC maintenu.** Poursuivre l'audit de confidentialité, ne pas changer la visibilité et ne jamais publier de noms, e-mails privés ou secrets dans les PR/issues publiques.
3. **Supabase commercial :** projet `jvxkhgdopslctpcjrhzw`, organisation commerciale Pro, Paris. **Lecture seule par défaut.** Migration, écriture, comptes réels, configuration distante, secret, Edge Function, publication et tests écrivant en ligne nécessitent l'accord explicite du propriétaire.
4. Tout nouveau **coût** (hébergement, domaine, API ou service tiers) doit être indiqué et approuvé **avant** l'action. Aucun contact client, contrat, tarification ou engagement commercial sans décision.
5. Les migrations **déjà appliquées** ne se réécrivent jamais. Les nouvelles ont un identifiant unique cohérent avec l'ordre des migrations présentes **et du registre SQL distant**. **Ne jamais exécuter `DROP SCHEMA install_tmp CASCADE` : instruction obsolète et dangereuse.** Le nettoyage prudent est porté par la PR #46, fusionnée en migration `20261112210000_nettoyage_securite.sql`.
6. Une PR ne peut être fusionnée qu'après examen de ses risques et **vérification de tous les contrôles pertinents sur le HEAD exact**, sans conflit restant. Une CI verte ne garantit pas les scénarios qu'elle ne couvre pas. Aucune publication automatique du site de test.
7. Échanges en français, directs, avec distinctions : « prévu », « documenté », « code intégré », « tests automatisés réussis », « testé en situation réelle ».

## Produit et décisions

Nom : **Lucarne**, application **multiclub** de foot **à 11 seulement**, issue de l'ergonomie AS Grinta mais indépendante. Chaque club configure son identité, son logo, ses couleurs, ses maillots, son stade et ses règles. Conserver les emojis des badges ; libellé validé **« Étoile du match »**.

**Cible mai 2027** : essai fictif à deux clubs, un club pilote, abonnement payant, 10 puis ~100 clubs. Les propositions de 10 €/joueur/an et 50 €/club/mois **ne constituent pas un tarif validé** ; Stripe non intégré.

## État GitHub vérifié le 12/11

- **Fusionnées** : #23 (notifications, agenda), #24 (site de test, publication manuelle), #25 (audit fonctionnel), #46 (nettoyage et audit sécurité), **#47 (réglages multiclubs)**, #48 (liste d'attente et historique), #49 (textes juridiques), #51 (marque/stade), **#52 (logo Lucarne, licence Oswald OFL incluse)**, ainsi que #1–#22.
- **PR #47** fusionnée après cinq workflows réussis sur le HEAD contrôlé. Corrige les notifications de modules coupés et le figement de l'effectif. Fusion du code ≠ application des migrations en ligne.
- **PR #52** fusionnée vers 16 h 10, squash `a77dfb6cd3cd7d62ec51cfdcf7a3b14471563665` après trois checks réussis ; licence officielle Oswald ajoutée. Essais PWA Android/iOS et disponibilité de marque INPI **non démontrés**.
- **PR #50** ouverte, **conflit de fusion avec main** à résoudre après #47/#52. Deux correctifs M00 dans sa branche : conservation du UID historique des événements iCalendar (éviter doublons) et neutralisation des maillots/identité lors du changement de compte, avec test de reset. Le HEAD modifié n'avait pas de checks PR au dernier contrôle du fait du conflit. **Rebaser sur main, préserver les correctifs #47 et relancer CI complète avant toute fusion.**
- **PR #40** terrain à domicile et **#43** quota de convoqués (brouillons empilés). La migration `20261112060000` de #40 est antérieure aux SQL `130000`/`200000`/`210000` déjà dans main : vérifier l'ordre et le registre avant fusion. #43 n'avait pas de CI propre confirmée.
- **PR #44** garde immutabilité des migrations / modèle qualité / consignes commerciales ; CI verte mais revue croisée nécessaire.
- **PR #29** contient le tableau des missions et le [relais complet daté](https://github.com/samihchaa-wq/Application-football-/blob/pilotage/tableau-chantier-20261112/docs/RELAIS_CLAUDE_20261112.md) ; à consulter avant chaque passage.
- PR #26, #30–#36, #41 : audits, maintenance et corrections en revue, sans validation de lancement.

**État technique distant :** le répertoire des migrations GitHub sur `main` allait jusqu'à `20261112210000` lors du contrôle. Le dernier état appliqué sur **Supabase commercial** n'a pas été relu directement à l'occasion de ce relais ; le propriétaire mentionne trois exécutions autorisées réussies de mise en route et des fonctions Edge configurées. **Vérifier en lecture seule les faits distants avant de conclure ou de planifier un SQL.**

**Site de test :** https://samihchaa-wq.github.io/Application-football-/ — workflow manuel ; pas une solution de SaaS commercial payant. Aucun déploiement depuis les fusions #47/#52 n'a été déclenché par M00.

## Risques et prérequis restants

**P0 sécurité :** cloisonnement réel A/B non démontré sur la base commerciale, journal d'incidents potentiellement global, autorisations d'admins de clubs suspendus ; voir [issue #37](https://github.com/samihchaa-wq/Application-football-/issues/37). Les ~157 avertissements concernant les fonctions serveur ne sont pas 157 failles démontrées. Ne pas exposer de données historiques personnelles en public.

**P0 sauvegardes :** restauration non démontrée ; dumps SQL séparés pouvant ne pas correspondre au même instant ; Supabase Storage non couvert ; vérifier les accès et secrets avant activation. [PR #32](https://github.com/samihchaa-wq/Application-football-/pull/32), [#31](https://github.com/samihchaa-wq/Application-football-/pull/31).

**P1 QA :** PR [#33](https://github.com/samihchaa-wq/Application-football-/pull/33) (tests de charge non-faux-verts), suites de tests #47/#50, vérification de transition compte A→B, UID calendrier, sessions de vrais mobiles ; aucune recette terrain exhaustive prouvée. [PR #26](https://github.com/samihchaa-wq/Application-football-/pull/26).

**Juridique** : cinq textes et accord de création de club en #49, mais identité éditoriale/SIRET, droits des médias, politique de rétention des notifications, motifs d'absence, hébergement SaaS, contrats et recherche de marque restent à valider avec un juriste. [Issue #39](https://github.com/samihchaa-wq/Application-football-/issues/39).

**Configuration du propriétaire :** 2FA GitHub/Supabase, secret Supabase à durée réduite et permissions vérifiées, configuration Auth et e-mail d'envoi, protection de main [issue #45](https://github.com/samihchaa-wq/Application-football-/issues/45), essais Club A/Club B avec son autorisation, choix de la règle des rappels de pronostics, décision de prix plus tard. **Aucun nouveau coût sans accord préalable.**

## Coordination

Les 9 missions sont réparties entre 5 automatisations horaires ; elles rédigent des preuves dans les PR/issues GitHub et n'activent pas directement les anciennes conversations. Le chef M00 centralise les priorités et les décisions. Le document [RELAIS_CLAUDE_20261112.md](https://github.com/samihchaa-wq/Application-football-/blob/pilotage/tableau-chantier-20261112/docs/RELAIS_CLAUDE_20261112.md) est le relais détaillé et cordial à reprendre, en vérifiant qu'aucune nouvelle fusion ou migration n'a eu lieu entre-temps.
