# Relais complet pour Claude — Lucarne
_Mise au point du 12 novembre 2026, vers 16 h 10 (Europe/Paris). À vérifier de nouveau avant toute action, car les PR et les contrôles CI évoluent._

Bonjour à l'équipe Claude,

Merci de reprendre la suite du chantier **Lucarne**, version commerciale et multiclub d'AS Grinta. Voici les décisions du propriétaire, les faits contrôlés sur GitHub et les actions les plus utiles à enchaîner. Les vérifications ci-dessous sont datées ; **ne pas présenter un commentaire, une CI verte ancienne ou une analyse statique comme une recette réelle.**

## 1. Périmètre et décisions non négociables

- **Seul dépôt autorisé en écriture :** [samihchaa-wq/Application-football-](https://github.com/samihchaa-wq/Application-football-) ; **dépôt PUBLIC**, décision explicite B du propriétaire. Ne jamais le rendre privé sans nouvelle autorisation. Continuer l'audit de confidentialité et ne jamais publier de données personnelles dans les commentaires.
- **Interdiction absolue de toucher** à AS Grinta original, Carte soirée, leurs dépôts, leurs bases Supabase et leurs sites.
- **Supabase commercial :** `jvxkhgdopslctpcjrhzw` (organisation commerciale Pro, Paris). Lecture seule pour l'audit courant. **Aucune** migration, modification de données, création de compte, déploiement de fonction ou manipulation de secret sans consentement exprès.
- Aucun coût nouveau, achat de domaine, engagement commercial, mise en production, publicité ou publication sans accord préalable. Ne jamais écrire de secrets dans GitHub/ChatGPT.
- Les migrations déjà appliquées sont immuables ; les nouvelles doivent être datées de manière unique et ordonnées après l'état effectivement appliqué. Ne pas exécuter de SQL destructif `DROP ... CASCADE` depuis l'ancien `HANDOFF.md`.
- Garder la DA et l'ergonomie AS Grinta autant que possible. Produit **foot à 11** seulement, maillots et stade réglables par club, badges avec emojis conservés, terme **« Étoile du match »** validé, marque **Lucarne** choisie.
- Objectif de lancement : **mai 2027**. D'abord deux clubs fictifs, puis un club pilote, abonnement payant, 10 clubs et ensuite ~100. Prix et formule **non décidés** : ne pas prendre comme tarif officiel le 10 €/joueur/an codé ni le 50 €/club/mois évoqué.
- Fusions seulement après relecture des risques et **CI réussie sur le HEAD exact**. Les fusions de code et les migrations/publi­cations réelles sont des opérations différentes.

## 2. Infrastructure, sans interprétation abusive

- Dépôt GitHub public, branche principale `main`, workflow de publication **manuelle seulement** vers le site d'essai : https://samihchaa-wq.github.io/Application-football-/ . Ne pas publier automatiquement.
- GitHub Pages sert aux tests fictifs ; **pas d'hébergement d'abonnement SaaS commercial**. Choisir un hébergement adapté avant vente et prévenir de son coût.
- Selon le dernier relais utilisateur, l'organisation Supabase commerciale est Pro, les fonctions Edge et certains secrets du Vault ont été configurés, et des migrations ont été appliquées par workflow autorisé. **Le dernier horodatage SQL distant réellement appliqué doit être revérifié en lecture seule** avant toute opération : `docs/HANDOFF.md` sur main est ancien et comporte des consignes désormais périmées.
- L'inventaire du répertoire `main/supabase/migrations/` consulté le 12/11 comporte des fichiers jusqu'à `20261112210000_nettoyage_securite.sql`. **La présence sur main n'établit PAS l'application distante.**
- Les 5 automatisations des missions M00, M01/02, M03/09, M04/07 et M05/06/08 ont été réactivées et leurs exécutions précédentes vérifiées. Elles ne réveillent pas automatiquement les 9 conversations spécialisées.

## 3. Pull requests fusionnées vérifiées

- [#24](https://github.com/samihchaa-wq/Application-football-/pull/24) : publication GitHub Pages manuelle de test.
- [#25](https://github.com/samihchaa-wq/Application-football-/pull/25) : audit fonctionnel, référentiel de 164 fonctions, cahier des charges.
- [#46](https://github.com/samihchaa-wq/Application-football-/pull/46) : assainissement de certains noms réels des fichiers courants, migration prudente de nettoyage, audit. **L'historique Git public n'est pas purgé.**
- [#47](https://github.com/samihchaa-wq/Application-football-/pull/47) : **fusion M00 à 14 h 18 Paris**, commit de merge-squash `a80ac7d25e379a8a06dbbffa23c269f85ba5f9d1`, après cinq contrôles verts sur la version exacte : modules désactivés, notifications, frontières d'effectif. Ce n'est **pas** une preuve de recette réelle multiclub distante.
- [#48](https://github.com/samihchaa-wq/Application-football-/pull/48) : trois modes de liste d'attente, saisie des matchs historiques.
- [#49](https://github.com/samihchaa-wq/Application-football-/pull/49) : textes juridiques et consentement du club, à personnaliser et faire relire.
- [#51](https://github.com/samihchaa-wq/Application-football-/pull/51) : nom Lucarne et couleurs du stade. Les PR #23 et antérieures ont aussi été intégrées.
- **Aucune publication ni migration distante causée par la fusion #47.**

## 4. PR ouvertes — travail immédiat

### [#50 — maillots, « Étoile du match », identifiants](https://github.com/samihchaa-wq/Application-football-/pull/50)
- **Statut contrôlé : ouverte, non fusionnable (`mergeable=false`) après #47**. Les cinq contrôles verts de l'ancien HEAD ne valident plus la combinaison. Après les modifications du 12/11 vers 16 h, il faut relancer la CI sur le HEAD neuf.
- **Deux corrections complémentaires M00 déjà commitées dans sa branche `claude/project-thread-ruh5sn` :**
  1. `supabase/functions/calendar-feed/index.ts` : restauration de l'UID d'événement historique `<id>@sporteasy-grinta` au lieu de `<id>@calendrier-club`. Le préfixe est purement technique et stable : le modifier créerait des doublons pour les abonnés existants.
  2. `lib/features/club/presentation/club_identity_sync.dart` : synchronisation à chaque changement d'identifiant de profil (et pas seulement du booléen connecté), neutralisation précoce du nom, thème et maillots avant récupération ; `test/core/club/club_kits_test.dart` : test local du reset des maillots A avant affichage B.
- **À faire en premier pour Claude :** rebaser/merger `main` dans cette branche, résoudre avec soin les écrans et fonctions SQL chevauchant #47, ne pas écraser ses protections, puis exécuter Flutter CI, tests Supabase business/RLS, charge et diagnostic sur le nouveau HEAD.
- **Risques à tester :** transition compte A → B sans maillots A visibles, échec réseau, administrateur de club suspendu, vote renommé et notifications positives/négatives par club ; calendrier iCalendar conservant les UID (report, annulation, ancien abonné), exécution Edge sans secret réel.
- La PR #50 peut comporter des migrations à horodatage **antérieur** aux SQL déjà présents sur main ; vérifier et réordonner en fonction de l'état du registre, sans réécrire les migrations appliquées.

### [#52 — logo/icônes Lucarne](https://github.com/samihchaa-wq/Application-football-/pull/52)
- **Statut contrôlé : ouverte et `mergeable=true` après #47.** Dernier HEAD après correction documentaire : `50644c068e0eef5874a086e08f8fadf1b3a30fd8`. CI Flutter était encore en cours au dernier contrôle ; ne pas fusionner avant verdict.
- **Correction M00 déjà commitée** dans `claude/project-thread-2ha3zk` : ajout du fichier `docs/branding/lucarne/OFL-Oswald.txt` (licence officielle du dépôt Google Fonts, copyright Oswald Project Authors 2016) et ajout de la notice de provenance/redistribution dans `docs/branding/lucarne/README.md`.
- Avant fusion : vérifier les contrôles du HEAD exact, la licence, l'origine du logo fourni par le propriétaire, et noter que les tests PWA réels (mise à jour d'application installée, icônes, cache, Android/iOS) **ne sont pas réalisés**. La disponibilité du nom « Lucarne » comme marque n'est pas vérifiée.
- Cette correction documentaire ne change pas les logos ni les binaires de police ; elle ne vaut pas avis juridique complet.

### Autres PR
- [#40](https://github.com/samihchaa-wq/Application-football-/pull/40) : terrain à domicile, brouillon ; migration `20261112060000` maintenant antérieure aux `130000`/`200000`/`210000` de main. **Ne pas fusionner en l'état** ; recaler horodatage après contrôle des SQL déjà appliqués et reprendre main. Consigne [GitHub](https://github.com/samihchaa-wq/Application-football-/pull/40#issuecomment-6827320907).
- [#43](https://github.com/samihchaa-wq/Application-football-/pull/43) : quota convoqués, brouillon **empilé sur #40**, pas de CI trouvée sur son propre HEAD ; traiter seulement après #40, retargeter vers main et vérifier la concurrence de deux admins.
- [#44](https://github.com/samihchaa-wq/Application-football-/pull/44) : garde automatique des migrations historiques, modèle de PR, corrections `AGENTS.md`, CI verte, mais brouillon et revue croisée requise.
- [#32](https://github.com/samihchaa-wq/Application-football-/pull/32), [#33](https://github.com/samihchaa-wq/Application-football-/pull/33) : surveillance et charge, correctifs anti-faux-verts, revue des sauvegardes à achever.
- [#29](https://github.com/samihchaa-wq/Application-football-/pull/29) : tableau central, documents de coordination non encore fusionnés ; autres audits documentaires [#26](https://github.com/samihchaa-wq/Application-football-/pull/26), [#30](https://github.com/samihchaa-wq/Application-football-/pull/30), [#31](https://github.com/samihchaa-wq/Application-football-/pull/31), [#34](https://github.com/samihchaa-wq/Application-football-/pull/34), [#35](https://github.com/samihchaa-wq/Application-football-/pull/35), [#36](https://github.com/samihchaa-wq/Application-football-/pull/36), [#41](https://github.com/samihchaa-wq/Application-football-/pull/41).

## 5. Sécurité, qualité et juridique : ce qui n'est pas validé

- [Issue #37](https://github.com/samihchaa-wq/Application-football-/issues/37) : revue des RPC d'administration, des clubs suspendus et d'un journal d'incident potentiellement global ; le chiffre de 157 fonctions `SECURITY DEFINER` est **un inventaire de surface**, pas 157 failles démontrées. Tests négatifs à deux clubs (A/B) nécessaires.
- Dépôt public : certaines anciennes références personnelles peuvent être encore dans l'historique ; éviter toute publication de noms ou d'informations sensibles. Demander une autorisation distincte pour une réécriture d'historique.
- [Issue #39](https://github.com/samihchaa-wq/Application-football-/issues/39) : conservation des notifications annoncée 90 jours mais purge possiblement conditionnée aux envois ; données de santé dans les motifs libres, droits aux médias, contrats et hébergement à finaliser.
- Sauvegardes : incohérence possible entre exports SQL séparés ; **restauration non démontrée**, objets Supabase Storage non couverts par le dump PostgreSQL. Chiffrement/artefacts GitHub à étudier avant activation.
- [Issue #45](https://github.com/samihchaa-wq/Application-football-/issues/45) : branche `main` à protéger via règles GitHub, état effectif non confirmé par l'intégration. Ne pas supposer protection active.
- Tests réels sur iPhone, Android, deux vrais comptes A/B et processus d'inscription encore à effectuer ; CI Flutter ~1 180 tests selon le suivi de PR, mais aucune validation commerciale de bout en bout.

## 6. Actions que seul le propriétaire peut autoriser ou effectuer

1. Tester les parcours « Club Test A » et « Club Test B » avec deux comptes distincts, puis transmettre les résultats. Les essais qui écrivent dans la base commerciale doivent être explicitement acceptés.
2. Vérifier Supabase Auth (inscription, URLs, e-mails), 2FA GitHub et Supabase, permissions des jetons, alertes et protection de `main`.
3. Trancher la règle des rappels de pronostics : heure configurable par club ou temps avant match.
4. Fournir la forme juridique/SIRET et coordonnées d'éditeur, puis faire relire les contrats ; recherche de marque INPI Lucarne.
5. Valider ultérieurement le prix, le système de paiement, l'hébergeur, le domaine et leurs coûts **avant** toute dépense ou service activé.

## 7. Ordre de reprise recommandé

**P0 sécurité et fiabilité** : vérifier registre des migrations et absence de fuite interclubs ; ne pas exécuter d'anciens SQL destructifs ; résoudre les risques de RPC/admin/backup.

**P1 intégration produit** : reprendre #50 sur main après #47, résoudre les conflits et CI, corriger si nécessaire les cas A→B ; finir la revue #52 et fusionner seulement si les contrôles actuels sont au vert ; préparer #40 puis #43 dans le bon ordre.

**P2 lancement** : essais pilotes A/B, configuration Auth, documents juridiques, hébergeur de vente, paiement, support, contrôle du cache PWA et notifications Android/iOS.

Merci pour la reprise et la continuité du travail. La règle commune reste simple : **protéger AS Grinta original, ne pas dépenser ni modifier la base commerciale sans accord, produire des preuves, et ne considérer une fonction comme terminée qu'après tests adaptés.**

— Transmission de coordination M00 (ChatGPT)
