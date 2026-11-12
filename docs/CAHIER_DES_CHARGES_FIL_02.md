# Cahier des charges exécutable pour le fil 02

**Établi le 12/11/2026.** Sous pilotage du fil 00 ([PR #29 — tableau commun](https://github.com/samihchaa-wq/Application-football-/pull/29)). Dérivé de `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` (164 fonctions inventoriées), de la PR #25 existante, du code commercial et d'une inspection Supabase **strictement en lecture seule**.

## Règles de gouvernance

- **Périmètre :** `samihchaa-wq/Application-football-` seulement. **Interdiction** de modifier le dépôt AS Grinta original, ses données, ses environnements et Carte soirée.
- **Aucun travail du fil 01 sur le code.** Ce fichier est destiné au fil 02. Les migrations commerciales, écritures DB ou déploiements supposent **accord préalable et explicite** du propriétaire. Ne jamais rejouer `supabase/seed.sql` en ligne.
- **Ne pas reconstruire l'app.** Garder l'ergonomie, les animations, les fiches, les jeux, la composition et les parcours qui fonctionnent; transformer en paramètres ce qui est particulier à AS Grinta.
- **Concurrence entre fils :** le fil 2 ne doit pas écraser la branche de refonte liste d'attente, l'historique ou les évolutions de marques réalisées ailleurs. Consigner le propriétaire et la PR de chaque chantier avant modification.
- **Référence serveur :** un bouton masqué n'est pas un contrôle d'autorisation. Les RPC et policies doivent définir la vérité; les données sont isolées par `club_id`.
- **Niveaux de preuve :** `codé`, `schéma présent`, `déployé`, `test unitaire vert`, `test DB vert`, `E2E réel vert` sont différents. Ne déclarer un élément terminé qu'au stade convenu.
- **Aucun effacement arbitraire :** conserver compatibilité clients/routes/API et anciennes migrations jusqu'à preuve de non-utilisation et stratégie de retrait.

## 1. Décisions encore réservées au responsable produit

1. **Identifiant :** pseudo lisible unique globalement, pseudo scoped par club avec contexte de connexion, ou e-mail facultatif/obligatoire. Ne pas imposer un e-mail sans décision; maintenir les comptes existants.
2. **Foot :** lancement initial foot à 11 seulement ou prise en charge 5/7/8 avant démarchage de ces équipes; liste de formations à valider.
3. **Libellé du vote :** nom neutre universel ou champ d'appellation par club (accord DA et juridique).
4. **Maillots :** couleurs + modèles neutres au pilote, ou import d'images par club; limites et formats médias à fixer.
5. **Cible :** une équipe par espace au démarrage; multiéquipes plus tard uniquement si besoin client vérifié.
6. **Offre payante :** prix, période d'essai, taxes, facturation, suspension, gestion abonnement (fil 6 et fil 7).
7. **Internationalisation :** hors timezone Europe/Paris et hors Français en phase ultérieure sauf décision contraire.

## 2. Backlog ordonné

Les tâches **F2-xx** sont des lots livrables indépendants autant que possible. Leur priorité est liée au périmètre de lancement; les P0 vente ne bloquent pas un pilote gratuit **validé**.

| Tâche | Priorité | Phase | Fonctions sources | Livraison à prévoir |
|---|---|---|---|---|
| F2-00 | P0 | Avant tout | A01-N15 | Recaler l'état des branches et preuves |
| F2-01 | P0 | Pilote | B05,D03,D12 | Adresse domicile paramétrable |
| F2-02 | P0 | Pilote | B06,E06 | Quota convoqués par défaut |
| F2-03 | P1 | Pilote | B01,B04,D08,K06 | Neutralisation identité et marques visibles |
| F2-04 | P1 | Pilote | F11,F12,C09 | Maillots propres à chaque club |
| F2-05 | P1 | Pilote | G11,G12,J07 | Nom neutre du joueur du match et badges |
| F2-06 | P0 | Pilote | E07,E08,E09,E10,E11 | Liste d'attente : trois modes cohérents |
| F2-07 | P0 | Pilote | E08,E09,E12 | Passages en attente transactionnels |
| F2-08 | P1 | Pilote | D10,D11,I07 | Saisie d'anciens matchs sans pollution du présent |
| F2-09 | P0 | Pilote | A05,A06,A08 | Identifiants multi-clubs robustes |
| F2-10 | P0 | Pilote | B07,E02,H03,G02,G09 | Source de vérité du cycle de match |
| F2-11 | P0 | Pilote | B08,G01,H08,I08,J01,K01 | Interrupteurs sans perte de données |
| F2-12 | P1 | Pilote | C03,C04,C07,C08 | Cohérence membres, joueurs et invités |
| F2-13 | P1 | Pilote | F01,F04,F05,F06 | Composition 11 : fiabilisation et UX |
| F2-14 | P1 (présentation) / P2 (clips sous décision DEC-06) | Pilote puis option | F08,F09,F10 | Présentation existante ; clips joueurs conditionnels |
| F2-15 | P0 | Pilote | G03-G10 | Intégrité live et récapitulatif |
| F2-16 | P1 | Pilote | H01-H07,I01-I07 | Pronostics et statistiques sans historique initial |
| F2-17 | P1 | Pilote | J01-J09,K01-K05 | Badges et bilan de saison |
| F2-18 | P0 | Pilote | L01-L12 | Push, webhooks, préférences et PWA |
| F2-19 | P0 | Pilote | N01-N05,N15 | Tests A/B et barrières serveur |
| F2-20 | P1 | Pilote | B02,B03,D05,K02,L11 | Polissage et accessibilité multi-écran |
| F2-21 | P0 | Exploitation | M05,M08,M12 | Abonnements et suspension sécurisés |
| F2-22 | P0 | Exploitation | N06,N07,N09 | Contrat infrastructure commerciale |
| F2-23 | P0 | Exploitation | M10,M11,N10,N11 | Préparer ouverture commerciale sûre |
| F2-24 | P1 | Plusieurs clubs | F02,F03 | Formats de jeu 11, 8, 7, 5 |
| F2-25 | P1 | Plusieurs clubs | B09,B12,N14 | Qualité de propagation et charge |
| F2-26 | P2 | Expansion | B10,B11,C02 | Fuseau et durée de saison par club |
| F2-27 | P2 | Expansion | B12 | Plusieurs équipes dans le même club |
| F2-28 | P2 | Expansion | J08,H05,E15 | Barèmes et rôles intermédiaires facultatifs |
| F2-29 | P0 | Vente | M06,M07 | Paiement effectif et facturation |

## 3. Tickets détaillés et critères d'acceptation

Chaque ligne de critères doit être validée par test démontrable. **Une lecture du code ne valide aucun critère d'acceptation de fonctionnement.**

### F2-00 — Recaler l'état des branches et preuves (P0, Avant tout)

- **Source de l'audit :** A01-N15.
- **Changements attendus :** Ne pas doubler les développements en cours; croiser PR, branches, migrations et livraison Edge.
- **Critères d'acceptation :** Le développeur indique commit de départ, branches concurrentes et PR concernées; les tâches déjà livrées sont marquées 'à vérifier' et jamais refaites sans preuve.
- **Dépendance / coordination :** Fil 1 + responsable coordination.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-01 — Adresse domicile paramétrable (P0, Pilote)

- **Source de l'audit :** B05,D03,D12.
- **Changements attendus :** Ajouter une adresse de terrain dans Réglages du club, utilisée en préremplissage avec possibilité d'exception par adversaire/match.
- **Critères d'acceptation :** Admin A configure adresse A et admin B adresse B; match A réutilise A, match B réutilise B; une modification de match n'altère pas le réglage du club; météo reste fonctionnelle sans adresse.
- **Dépendance / coordination :** F2-00.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-02 — Quota convoqués par défaut (P0, Pilote)

- **Source de l'audit :** B06,E06.
- **Changements attendus :** Exposer valeur déjà prévue usual_squad_size avec validations et exceptions par match.
- **Critères d'acceptation :** Admin règle le quota à 8; un nouveau match A propose 8; le club B conserve son propre quota; un match existant ne change pas rétroactivement sans action explicite.
- **Dépendance / coordination :** F2-00.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-03 — Neutralisation identité et marques visibles (P1, Pilote)

- **Source de l'audit :** B01,B04,D08,K06.
- **Changements attendus :** Traquer Pibrac, AS Grinta, 'sportEasy-grinta', Wrapped visible et placeholders UI; garder noms techniques indispensables.
- **Critères d'acceptation :** Aucun parcours joueur/admin, notification, fichier exporté ou flux ICS ne présente le nom d'AS Grinta ou d'un tiers en dehors des contenus saisis par le club; les migrations ne sont pas renommées.
- **Dépendance / coordination :** Fil 5 + Fil 7.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-04 — Maillots propres à chaque club (P1, Pilote)

- **Source de l'audit :** F11,F12,C09.
- **Changements attendus :** Remplacer les 3 maillots fixes du sélecteur par un catalogue minimal du club; garder compatibilité données anciennes.
- **Critères d'acceptation :** A crée 1 ou plusieurs kits et les choisit; B ne voit jamais ceux de A; les anciens jersey_note restent lisibles; images par joueur/saison s'affichent ou fallback sans cassure.
- **Dépendance / coordination :** F2-00 + Fil 5.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-05 — Nom neutre du joueur du match et badges (P1, Pilote)

- **Source de l'audit :** G11,G12,J07.
- **Changements attendus :** Libellé inclusif par défaut, sans changer tables/RPC historiques; option de personnalisation si besoin.
- **Critères d'acceptation :** Tous les écrans, titres, push, badges et bilans montrent le nouveau terme convenu; aucune erreur de contrat API; résultats et anonymat du vote inchangés.
- **Dépendance / coordination :** Fil 5 + Fil 7.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-06 — Liste d'attente : trois modes cohérents (P0, Pilote)

- **Source de l'audit :** E07,E08,E09,E10,E11.
- **Changements attendus :** Intégrer le travail parallèle; algorithme unique pour priorité, ordre d'arrivée et sélection admin.
- **Critères d'acceptation :** Pour chacun des 3 modes : ajout/suppression, désistement, retour, quota modifié et égalités ont un ordre déterministe; même état visible client et base; aucune rétroaction injustifiée.
- **Dépendance / coordination :** Branche en cours liste d'attente.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-07 — Passages en attente transactionnels (P0, Pilote)

- **Source de l'audit :** E08,E09,E12.
- **Changements attendus :** Règle +1 au coup d'envoi, idempotence, non-rétroactivité et verrou T-15.
- **Critères d'acceptation :** Deux exécutions du cron n'ajoutent pas 2 points; annulation/report annule le gain selon contrat; les convocations déjà gelées ne bougent pas; journal d'audit cohérent.
- **Dépendance / coordination :** F2-06.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-08 — Saisie d'anciens matchs sans pollution du présent (P1, Pilote)

- **Source de l'audit :** D10,D11,I07.
- **Changements attendus :** Réconcilier le développement en cours, valider résultat/saison/joueurs/score.
- **Critères d'acceptation :** L'admin saisit un match antérieur et peut corriger la saisie selon droits; stats et adversaire sont actualisés sans créer de pronostic, push ou Live fictifs; deux clubs ne se croisent pas.
- **Dépendance / coordination :** Branche en cours historique.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-09 — Identifiants multi-clubs robustes (P0, Pilote)

- **Source de l'audit :** A05,A06,A08.
- **Changements attendus :** Étudier et choisir format d'identifiants garantissant disponibilité sans rupture des comptes historiques.
- **Critères d'acceptation :** Créer plusieurs utilisateurs homonymes dans clubs différents fonctionne; comptes anciens se connectent; mot de passe oublié fonctionne; aucune exposition du club d'autrui lors du choix.
- **Dépendance / coordination :** Décision produit fil 1 / fil 2.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-10 — Source de vérité du cycle de match (P0, Pilote)

- **Source de l'audit :** B07,E02,H03,G02,G09.
- **Changements attendus :** Conserver heure Paris par défaut, régler ouvertures, gel, Live, correction indépendamment selon contrat.
- **Critères d'acceptation :** Simulation horloges J-6, J-1, T-15, T, T+24h : serveur, UI, push donnent mêmes droits; changements admin ne déverrouillent pas un match déjà clos sans autorisation.
- **Dépendance / coordination :** F2-00.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-11 — Interrupteurs sans perte de données (P0, Pilote)

- **Source de l'audit :** B08,G01,H08,I08,J01,K01.
- **Changements attendus :** Auditer les 7 modules; bloquer les écritures serveur interdites, masquer accès UI et conserver historique.
- **Critères d'acceptation :** Admin B coupe les pronos; aucun joueur B ne peut enregistrer via REST/RPC direct; ses anciennes données demeurent après réactivation; A est inchangé.
- **Dépendance / coordination :** Fil 4 pour tests droits.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-12 — Cohérence membres, joueurs et invités (P1, Pilote)

- **Source de l'audit :** C03,C04,C07,C08.
- **Changements attendus :** Dédupliquer identités et invitations; tester les liens au fil des saisons.
- **Critères d'acceptation :** Un membre ajouté automatiquement ne crée pas deux joueurs; invité archivé reste dans les matchs passés; homonyme historique n'est pas fusionné sans preuve.
- **Dépendance / coordination :** F2-00.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-13 — Composition 11 : fiabilisation et UX (P1, Pilote)

- **Source de l'audit :** F01,F04,F05,F06.
- **Changements attendus :** Conserver simulation, positionnements, banc et publication même si formats réduits viennent plus tard.
- **Critères d'acceptation :** Composition sauvegardée après glisser-déposer reste identique après rechargement; simulation ne remplit pas des joueurs imaginaires; correction soumise au verrou serveur.
- **Dépendance / coordination :** F2-00.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-14 — Présentation de composition et clips joueurs (P1 existant ; P2 clips conditionnels)

- **Source de l'audit :** F08,F09,F10 ; **décision propriétaire DEC-06**.
- **Changements attendus :** Conserver et vérifier immédiatement la présentation de composition animée avec photos et stade. Les **clips individuels détourés** sont un besoin différent : aucun écran d'import ou pipeline de stockage de ces clips n'a été vérifié. Spécifier format, transparence, quotas et droits avant développement **seulement si DEC-06 est validée**.
- **Critères d'acceptation phase P1 :** Une composition publiée se présente avec portraits fixes, les joueurs apparaissent par groupes sans sortir du cadre, puis sont placés ; vidéo de stade absente/échec réseau n'empêche jamais l'affichage du terrain.
- **Critères d'acceptation phase conditionnelle P2 :** Si import de clips validé, un joueur avec clip valide est animé dans son groupe pendant 3–5 secondes, les autres conservent la photo ; import réservé à l'admin du club, contenu et stockage isolés par club ; aucune dégradation lourde du chargement ; droits à l'image vérifiés.
- **Dépendance / coordination :** Fil 5 + Fil 7.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-15 — Intégrité live et récapitulatif (P0, Pilote)

- **Source de l'audit :** G03-G10.
- **Changements attendus :** Vérifier événements, concurrence et finalisation; corriger seulement écart démontré.
- **Critères d'acceptation :** Deux pilotes concurrents ne peuvent diverger; score, passeurs, temps de jeu et bilan correspondent au compte rendu validé; seconde finalisation n'ajoute pas des stats.
- **Dépendance / coordination :** Fil 3 + Fil 4.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-16 — Pronostics et statistiques sans historique initial (P1, Pilote)

- **Source de l'audit :** H01-H07,I01-I07.
- **Changements attendus :** Cas d'un club neuf, matchs annulés, nombre variable de participants et corrections.
- **Critères d'acceptation :** Un club sans historique voit cotes neutres sans crash; score exact donne le barème documenté; classement reste déterministe après correction d'un résultat.
- **Dépendance / coordination :** Fil 3.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-17 — Badges et bilan de saison (P1, Pilote)

- **Source de l'audit :** J01-J09,K01-K05.
- **Changements attendus :** Vérifier catalogue propre au club, fin de saison, fallback musique et confidentialité.
- **Critères d'acceptation :** Club nouvellement créé dispose des modèles autorisés; attribution manuelle auditée; bilan d'un joueur sans match masqué; aucune musique ou image non licenciée livrée.
- **Dépendance / coordination :** Fil 5 + Fil 7.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-18 — Push, webhooks, préférences et PWA (P0, Pilote)

- **Source de l'audit :** L01-L12.
- **Changements attendus :** Validation appareil + e-mail + cron + deep links sur infrastructure commerciale.
- **Critères d'acceptation :** Un joueur A reçoit une notification A et jamais B; opt-out stoppe tout push concerné; aucun doublon après retry; PWA installée ouvre exactement l'écran notifié.
- **Dépendance / coordination :** Fil 3 + Fil 9.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-19 — Tests A/B et barrières serveur (P0, Pilote)

- **Source de l'audit :** N01-N05,N15.
- **Changements attendus :** Corriger les défaillances remontées par fil 4, pas de confiance dans masquage UI.
- **Critères d'acceptation :** Accès A vers B refusé pour tables, RPC, Storage, caches et notifications; anon/pending/suspended refusés; tests anti-IDOR et régression conservés.
- **Dépendance / coordination :** Fil 4, accord DB si migration.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-20 — Polissage et accessibilité multi-écran (P1, Pilote)

- **Source de l'audit :** B02,B03,D05,K02,L11.
- **Changements attendus :** Préserver ADN AS Grinta sur mobile/desktop PWA, thèmes club et animation.
- **Critères d'acceptation :** Rendu lisible avec couleurs extrêmes, écran étroit, clavier et accessibilité; bouton retour, reprise session et chargement cache ne bloquent pas la navigation.
- **Dépendance / coordination :** Fil 5 + Fil 8.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-21 — Abonnements et suspension sécurisés (P0, Exploitation)

- **Source de l'audit :** M05,M08,M12.
- **Changements attendus :** Préserver essai et contrôle de l'éditeur, sans présumer d'un paiement opérationnel.
- **Critères d'acceptation :** Un club expiré voit écran dédié, ne conserve pas d'écriture via RPC et peut exporter selon politique validée; un autre club actif continue; aucun opérateur non désigné n'accède à la console.
- **Dépendance / coordination :** Fil 6/7/9.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-22 — Contrat infrastructure commerciale (P0, Exploitation)

- **Source de l'audit :** N06,N07,N09.
- **Changements attendus :** Refuser bases originales, versionner les exigences des Edge Functions et vérifier synchronisation.
- **Critères d'acceptation :** L'app commerciale utilise uniquement le projet jvxkhgdopslctpcjrhzw; config prod cohérente; 19 migrations vérifiées; aucune mise en ligne avant checklist; état secrets vérifié sans les divulguer.
- **Dépendance / coordination :** Fil 4 + Fil 9.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-23 — Préparer ouverture commerciale sûre (P0, Exploitation)

- **Source de l'audit :** M10,M11,N10,N11.
- **Changements attendus :** Préparer sans faire payer : textes, historique public, sauvegardes, procédures incidents.
- **Critères d'acceptation :** Pas de placeholder légal visible; historique Git audité par responsables; restauration testée; alertes configurées; approbation finale explicite avant lancement.
- **Dépendance / coordination :** Fil 7 + Fil 9.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-24 — Formats de jeu 11, 8, 7, 5 (P1, Plusieurs clubs)

- **Source de l'audit :** F02,F03.
- **Changements attendus :** Concevoir variantes et dispositifs sans dégrader compo 11 existante.
- **Critères d'acceptation :** Paramètre du club détermine joueurs sur terrain, formations autorisées et gardien; changement de format ne réécrit pas les matchs archivés; simuler/valider respecte le format.
- **Dépendance / coordination :** Décision cible clubs + Fil 5.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-25 — Qualité de propagation et charge (P1, Plusieurs clubs)

- **Source de l'audit :** B09,B12,N14.
- **Changements attendus :** Synchroniser réglages sur appareils et contrôler coûts en usage simulé.
- **Critères d'acceptation :** Sur 2, 20, 200 clubs simulés: latence et coût mesurés, pas de fuite, pas de doublon de cron; états hors réseau reviennent au serveur.
- **Dépendance / coordination :** Fil 3 + Fil 9.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-26 — Fuseau et durée de saison par club (P2, Expansion)

- **Source de l'audit :** B10,B11,C02.
- **Changements attendus :** Prévoir timezone IANA, calcul local serveur, devise/langue à décider.
- **Critères d'acceptation :** Match Paris et Guadeloupe n'ouvrent pas aux mêmes instants UTC pour même heure locale; DST couvert; archives et calendrier restent stables.
- **Dépendance / coordination :** Marché hors France établi.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-27 — Plusieurs équipes dans le même club (P2, Expansion)

- **Source de l'audit :** B12.
- **Changements attendus :** Chantier de modèle d'autorisation et facturation conditionnel, à ne pas démarrer sans besoin.
- **Critères d'acceptation :** Chaque joueur a autorisations d'équipe explicites; données privées entre équipes; abonnement et transferts documentés; migration sans perte.
- **Dépendance / coordination :** Fil 6 + décision produit.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-28 — Barèmes et rôles intermédiaires facultatifs (P2, Expansion)

- **Source de l'audit :** J08,H05,E15.
- **Changements attendus :** Rendre les seuils/règles/permissions personnalisables seulement sur demande.
- **Critères d'acceptation :** Règles publiées, versionnées et rétroactivité explicite; rôles n'accordent jamais plus que leurs droits; défaut AS Grinta inchangé.
- **Dépendance / coordination :** Retour pilotes.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

### F2-29 — Paiement effectif et facturation (P0, Vente)

- **Source de l'audit :** M06,M07.
- **Changements attendus :** Choisir modèle commercial et prestataire avant développer intégration.
- **Critères d'acceptation :** Activation uniquement après confirmation de paiement signée; webhook idempotent; renouvellement, remboursements, échecs et facture gérés; tarifs approuvés.
- **Dépendance / coordination :** Fil 6 + Fil 7, avant vente payante.
- **Preuves à fournir :** chemins et PR modifiés, tests Dart/SQL pertinents, captures ou traces redigées si tests E2E, compte rendu des cas limites. Aucun log contenant jeton, e-mail privé ou identité réelle.

## 4. Matrice d'acceptation transversale — pour le fil 03

| Scénario | État initial | Action | Résultat indispensable |
|---|---|---|---|
| T01 — Nouveau club A | Base de test vide | Créer club et administrateur | Club et abonnement d'essai propres à A, paramètres par défaut conservés |
| T02 — Nouveau club B | A existe | Créer B, même nom de joueur qu'A | Identifiants valides, données distinctes, aucun accès croisé |
| T03 — Invitation périmée | Code A régénéré | Ouvrir ancien lien | Rejet explicite sans création de membre |
| T04 — Compte en attente | Joueur B pas validé | Appeler RPC de match et stockage | Refus serveur, aucun contenu de B ni de A révélé |
| T05 — Permissions | Joueur B actif | Appeler RPC admin sur A et B | Refus des deux actions |
| T06 — Match futur | J-6 avec réglages d'ouverture | Déclarer présent puis se retirer | Publication et convocations identiques sur deux appareils, notifications cohérentes |
| T07 — Attente | Quota plein, 2 joueurs à égalité | Retrait + retour + lancement répété | Ordre déterministe, aucun double +1 |
| T08 — Gel | Match à T-15 | Tenter modifier prono/effectif/compo | Refus serveur, sauf exception admin explicitement prévue |
| T09 — Live | Match commencé, deux clients | But puis remplacement concurrent | État idempotent, temps de jeu et score cohérents |
| T10 — Finalisation | Live terminé | Valider 2 fois puis corriger compte rendu | Une seule version active et stats/badges réconciliés |
| T11 — Vote | HDM coupé sur B, actif sur A | Voter sur les deux via API | B refusé, A anonyme et une voix autorisée |
| T12 — Archives | Saisir un match ancien | Recalculer stats et cotes | Aucun prono, Live ou notification fictif |
| T13 — Désactivation | B a pronos existants | Couper puis rallumer | A inchangé, anciennes données B conservées |
| T14 — Thème/kit | A et B personnalisés | Ouvrir la même page et composer | Bonne couleur, logo et maillot par club, accessible |
| T15 — Push | iPhone PWA + Android PWA | Activer puis désactiver notif | Préférences respectées, lien correct, pas de cible interclub |
| T16 — Suspendu | Club B suspendu | Naviguer et écrire RPC | Accès suspendu selon politique; A intact; parcours de retour documenté |
| T17 — Coupure réseau | Compte A en cours d'édition | Perte/reprise internet | Message explicite; pas de double enregistrement; serveur fait foi |
| T18 — Deux saisons | Fin de saison A, B active | Archiver A et accéder aux bilans | Stats archives intactes, données B inchangées |

Exécution de ces tests sur **base de test dédiée ou commerciale seulement après autorisation explicite d'y créer des données**. Jamais sur AS Grinta original. Les résultats seront inscrits dans un tableau preuves OK/KO/non testé avec date, build, environnement.

## 5. Ordre de livraison recommandé et gates

- **Lot 0 :** F2-00 puis inventaire des PR concurrentes, fixation des contrats, états des Edge et migrations.
- **Lot 1 :** F2-01/02/03/04/05 (paramètres et identité) et F2-09 (auth) avec tests isolés.
- **Lot 2 :** F2-06/07/08/10/11/12 (moteur métier, historiques, modules).
- **Lot 3 :** F2-13/14/15/16/17/18/20 (expérience, sports, gamification, push).
- **Gate pilote gratuit :** F2-19/21/22/23 et validation sécurité fil 4 + fonctionnelle fil 3, légale fil 7, pilote fil 8; déploiement toujours sous contrôle.
- **Gate vente payante :** F2-29, décision tarifs fil 6, consentements/contrats fil 7, sauvegardes fil 9 et facturation.
- **Extension :** F2-24/25/26/27/28, décidée selon les besoins réels sans retarder artificiellement le pilote.

## 6. Définition de 'terminé'

Pour chaque PR du fil 02 : (1) fonction documentée avec référence de tâche; (2) code limité au dépôt commercial; (3) migrations nouvelles et immuables après autorisation; (4) tests d'unités, widget et SQL pertinents; (5) invariants du cycle match préservés; (6) droits joueur/admin/club A-B testés; (7) changements de période, saison, réseau et erreurs testés; (8) UX validée fil 5/8; (9) documentation et `docs/HANDOFF.md` mis à jour; (10) aucune fusion si CI requise rouge.

**Commandes de vérification proposées** (à exécuter par le fil responsable; non exécutées par le présent audit) :

```bash
python3 -m unittest discover -s tool/tests -p 'test_commercial_*.py' -v
python3 tool/check_commercial_deploy.py
flutter pub get --enforce-lockfile
flutter analyze --fatal-warnings --fatal-infos
flutter test
```

Tester aussi PostgreSQL/RLS dans le workflow `supabase_business_tests.yml`; un contrôle vert local ne remplace ni E2E de l'app commerciale ni les avis de sécurité. **Pour toute opération payante ou sur la base commerciale, demander l'autorisation au préalable.**
