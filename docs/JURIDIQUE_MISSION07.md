# Mission 07 — audit juridique et conformité (pré-audit)

**Date :** 12 novembre 2026. **Statut :** documentaire, **non validé** juridiquement. **Coordination :** fil 00, [pilotage PR #29](https://github.com/samihchaa-wq/Application-football-/pull/29), [HANDOFF](../HANDOFF.md).

> **Portée et méthode.** Lecture statique du dépôt commercial `samihchaa-wq/Application-football-` et recherche de références officielles françaises/européennes. Aucune vérification des données personnelles anciennes dans l'historique Git, aucune exécution d'un parcours en production, aucun test CI lancé, aucun accord de tiers obtenu. Les éléments « présents dans le code » ne sont **pas** une preuve de conformité effective. Aucune modification de l'application originale, de Supabase ou du code commercial.

## Synthèse pour le fil 00

**GO commercial : NON**, jusqu'à levée des points P0 ci-dessous. Un essai avec deux **clubs fictifs** relève d'une décision séparée : validation sécurité et déploiement adaptés, aucune vraie donnée de joueurs.

**Constats vérifiables :**
- Dépôt commercial déclaré **public** dans les métadonnées GitHub ; `docs/HANDOFF.md` affirme que son historique contient d'anciennes données AS Grinta. Leur nature et leur accessibilité **n'ont pas été vérifiées** : ne pas conclure à une violation RGPD sans investigation. Remédiation à coordonner avec **04**.
- `lib/features/legal/domain/legal_documents.dart` contient des modèles de mentions, CGU et politique de confidentialité, avec **identité, e-mail, adresse, SIRET, durées/prix et fournisseurs à compléter**. Ce n'est pas un jeu de documents prêt pour la vente.
- `supabase/migrations/20261112020000_donnees_personnelles.sql`, `lib/features/profile/data/personal_data_repository.dart` et `lib/features/profile/presentation/my_data_section.dart` comprennent un **export** `export_my_data` et une **suppression à la demande** via `manage-user`. Le guide `docs/privacy-and-retention.md` est en **contradiction** (il dit qu'il n'y a ni RPC d'export ni page de données personnelles). Les parcours complets, objets Storage, historiques et backups restent à tester.
- `lib/features/auth/presentation/consent_fields.dart` prévoit une case CGU/confidentialité et une **déclaration** « 15 ans ou plus » / « moins de 15 ans avec accord d'un parent ». La preuve d'une autorisation parentale et les cas où elle est juridiquement exigée restent à qualifier. L'acceptation de la **politique de confidentialité** ne suffit pas à établir un consentement RGPD valable pour chaque finalité.
- `docs/privacy-and-retention.md` confirme que les **motifs libres d'indisponibilité** peuvent révéler l'état de santé. Les restrictions d'accès sont **décrites**, mais la nécessité, une condition article 9 du RGPD et l'éventuelle AIPD doivent être établies si ces champs sont conservés.
- `docs/business-security-matrix.md` décrit RLS/Storage/rôles ; **pas de validation effective A/B** de deux clubs sur la base commerciale. Références QA : [PR #26](https://github.com/samihchaa-wq/Application-football-/pull/26) ; sécurité : fil **04**.
- `assets/fonts/OFL-Oswald.txt` contient une licence **SIL OFL 1.1** pour Oswald. L'inventaire exhaustif des autres images, sons, animations, dépendances et créations IA **reste à faire** ; ne pas présumer de droits commerciaux.
- `docs/HANDOFF.md` : **Stripe non intégré**, prix 10 €/joueur/an **indicatif** ; nom définitif non décidé. `docs/COMMERCIAL_LAUNCH_CHECKLIST.md` prévoit encore GitHub Pages pour la PWA.
- **Attention contractuelle forte :** [GitHub Pages limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits) exclut l'hébergement gratuit pour exploiter un SaaS commercial. Une **mise en ligne temporaire de test fictif** doit être distinguée du futur **service commercial**. Proposer un hébergeur PWA adapté au fil **02/09/00**, sans engager de dépense ni modifier PR #24 sans accord.

## Matrice des obligations et risques (constats au 12/11/2026)

**Codes** : C = obligation certaine dès que la situation indiquée existe ; S = obligation dépendante de la situation ; P = recommandation de prudence. **Statuts** : PRÉSENT = élément dans le dépôt, pas conformité prouvée ; À VÉRIFIER ; À CORRIGER ; À DÉCIDER. **P0** = blocage avant toute vente / publication avec données réelles ; **P1** = avant facturation ; **P2** = amélioration.

| ID | Priorité | Cat. | Sujet, risque | État / preuve dans le dépôt | Action / pilote |
|---|---|---|---|---|---|
| J07-01 | P0 | C/S | Historique public pouvant exposer données de personnes/secrets | **À VÉRIFIER** — `HANDOFF.md` ; dépôt public ; nature non déterminée | 04 : audit confidentiel du Git history, rotation des secrets **si concernés**, qualifier notification CNIL/individus selon risque, traiter cache/forks, plan de réécriture après accord |
| J07-02 | P0 | C | Séparation des clubs et contrôle d'accès | **PRÉSENT, NON TESTÉ EN PRODUCTION** — `business-security-matrix.md` | 03/04 : RLS, RPC, Edge, Storage, Realtime A/B avec deux clubs fictifs |
| J07-03 | P0 | C | Rôles RGPD : club responsable des finalités sportives ? éditeur sous-traitant ? éditeur responsable pour facturation/comptes ? | **À QUALIFIER** — politique parle de responsabilité diffuse | 07/06 : cartographie par finalité ; juriste ; contrat art. 28 avec chaque club lorsque requis |
| J07-04 | P0 | C | Information RGPD art. 13/14 et bases légales par finalité | **À CORRIGER** — politique générique, confusion CGU/consentement | 07/02 : avis de confidentialité distincts joueur/club ; base et répartition de droits |
| J07-05 | P0 | S | Raisons d'absence pouvant devenir données de santé (art. 9) | **PRÉSENT** — motif libre décrit dans `privacy-and-retention.md` | 01/02/07 : proposer retrait/désactivation du motif libre ou valider exception art. 9 + minimisation + mesures renforcées ; évaluer AIPD |
| J07-06 | P0 | C/S | Droit à l'image et mineurs, autorisations d'utilisation des portraits/vidéos | **À VÉRIFIER** — aucune autorisation personnelle vérifiée | 05/07/08 : modèles distincts, finalités, durée, retrait, preuve ; parents selon situation |
| J07-07 | P0 | C | Hébergement SaaS commercial compatible avec conditions du fournisseur | **À CORRIGER** — GitHub Pages prévu | 02/09 : proposer hébergement commercial autorisé ; 00 décide ; déploiement tests fictifs à distinguer |
| J07-08 | P0 | C | Mentions légales éditeur/hébergeur et coordonnées | **À CORRIGER** — placeholders `legal_documents.dart` | 06/07 : identité juridique, contact, directeur publication, nouvel hébergeur, mentions exigées |
| J07-09 | P1 | C/S | CGV abonnement, reconduction, résiliation, garanties, B2B/B2C/associations | **À CORRIGER** — CGU seules ; prix/durée placeholders | 06/07 : qualifier clientèle ; rédiger CGV adaptées ; avocat |
| J07-10 | P1 | C | Identité du vendeur, immatriculation, régime TVA, factures | **À DÉCIDER** | 06 : structure et prix ; expert-comptable ; facturation conforme, calendrier e-invoicing |
| J07-11 | P1 | S | Rétractation, médiation, renouvellement, résiliation numérique si client consommateur | **À VÉRIFIER** | 06/07 : catégorie juridique des clubs et acheteurs, nature contrat, juriste |
| J07-12 | P1 | C | Prestataires et chaîne de sous-traitance : DPA, transferts, sous-traitants ultérieurs | **À VÉRIFIER** — Supabase (région Paris), GitHub, e-mail, paiement futur | 07/09 : contrats Supabase/GitHub/tiers, liste sous-traitants et flux hors EEE ; mesures de transfert |
| J07-13 | P1 | C | Durées de conservation, suppression, sauvegardes et fin de contrat | **À CORRIGER/VALIDER** — 90 j notifications, [6 mois] après suspension | 07/02/09 : politique par type de données, purge et sauvegardes ; démo de suppression/retour de données |
| J07-14 | P1 | C | Droits d'accès/export/effacement : efficacité et exceptions | **PRÉSENT MAIS À TESTER** — migration RPC + bouton ; doc ancienne incorrecte | 03/07/09 : tester profils, noms en historique, exports, photos, délai des demandes ; corriger doc |
| J07-15 | P1 | C | Sécurité, notification des incidents, preuves (art. 32/33/34 RGPD) | **À VÉRIFIER** — audits/monitoring incomplets, PR #26/#31 | 04/09/07 : procédure d'incident et registre ; délai 72h si notification requise |
| J07-16 | P1 | C | Transparence cookies et stockage local : traceurs non essentiels ? | **À VÉRIFIER** — politique nie les cookies de suivi | 02/07 : audit réel cookies/SDK/analytics ; consentement uniquement si traceurs non exemptés |
| J07-17 | P1 | C/S | Mineurs : bases légales, information adaptée, consentement dans les cas prévus | **DÉCLARATION PRÉSENTE, INSUFFISAMMENT ÉTABLIE** — case « parent d'accord » | 07/02 : vérifier portée art. 45 loi Informatique et Libertés, preuve, titulaires autorité parentale et droit à l'image |
| J07-18 | P1 | C | Licences Flutter/Dart/JS, attributions et obligations notice | **PARTIELLEMENT PRÉSENT** — Oswald SIL OFL ; `pubspec.yaml` | 04/05/07 : inventaire SBOM/licences et mentions d'attribution |
| J07-19 | P1 | C/S | Images/maillots/écussons/badges, textes, sons, animations, IA : droits de reproduction et marques tierces | **À VÉRIFIER** — changement de maillots noté au CHANGELOG | 05/07 : registre provenance/preuves licences/autorisation ou remplacement |
| J07-20 | P1 | S | Nom commercial, marque, domaine, risque de confusion | **NON DÉCIDÉ** | 05/07 : recherche d'antériorités INPI et autres signes; avis professionnel ; dépôt uniquement après autorisation |
| J07-21 | P1 | C/S | Propriété du code assisté par IA, contributeurs, éléments d'un tiers, confidentialité | **À VÉRIFIER** — dépôt dérivé d'AS Grinta | 07/04 : chaîne des droits, contributions et licences ; avocat si cession/licence |
| J07-22 | P1 | C | Responsabilité contractuelle, sécurité des comptes, support, suspension, disponibilité | **À PRÉCISER** — CGU très générales | 06/09/07 : SLA réaliste, responsabilité proportionnée, support, sortie, clauses suspensions |
| J07-23 | P2 | S | Publication App Store / Google Play, paiements intégrés, règles store | **NON APPLICABLE À LA PWA SEULE**, devient pertinent si stores | 02/06/07 : revalider lors d'une distribution native |
| J07-24 | P1 | C/S | Registre des traitements, AIPD si risque élevé | **À VÉRIFIER** | 07/04 : registre des finalités éditeur et traitement pour clubs ; grille AIPD |
| J07-25 | P2 | P | Protection commerciale du concept/code/identité, preuve des créations | **À ORGANISER** | 07/05/06 : dépôt marque éventuel, preuves d'antériorité, NDA adapté, accès restreint, sans fausse garantie |
| J07-26 | P1 | C/S | Conformité facture électronique (réception 2026, émission selon taille dès 2027 pour PME/micro) | **À DÉCIDER** | 06/expert-comptable : nature clients assujettis, e-invoicing/e-reporting et plateforme agréée |

## Feuille de route priorisée

### P0 — avant client avec données réelles / première vente
1. **04 + 00 :** confidentialité Git history : inspection restreinte, classification, plan de confinement ; aucun nom, secret ou photographie recopié dans les PR publiques. Si exposition avérée, analyser immédiatement les obligations d'incident avec juriste/DPO, sans attendre la mise en vente.
2. **03 + 04 :** tests A/B et audit des fonctions privilégiées ; attestation reproductible sans données personnelles.
3. **07 + 06 :** qualifications juridiques éditeur/clubs et clients (associations, B2B, consommateurs), finalités/bases, décisions sur données de santé et mineurs.
4. **02 + 09 + 00 :** plan de migration hors de GitHub Pages avant commercialisation, sans engager de frais.
5. **07 + 06 :** finaliser mentions, politique de confidentialité et contrats ; choisir mode d'accompagnement des droits (export/suppression/restitution).

### P1 — avant première facture
6. **06 :** statut juridique, tarification HT/TTC, TVA et système de paiement/facturation ; **aucun achat avant accord**.
7. **07 + 05 :** inventaire des licences/droits sur ressources et identité commerciale ; procédure de consentement photos.
8. **09 + 07 :** registre, procédures incidents, sous-traitants, sauvegardes, durée et fin de vie.
9. **03 :** scénario documenté d'exercice de droits, notification, annulation et résiliation.

### P2 — après qualification/pilote
10. **05 + 07 :** recherche approfondie d'antériorités et, si retenu, dépôt de marque.
11. **06 + 09 :** révision annuelle des CGV et politique RGPD et audits sécurité récurrents.

## Décisions à présenter au propriétaire (via fil 00)

| Décision | Options | Sans accord |
|---|---|---|
| D07-A : politique vis-à-vis du champ motif d'absence | Désactiver la saisie libre (plus simple) ou analyser/rendre licite une collecte sensible | Aucune modification ; risque non levé |
| D07-B : modèle de vente | Abonnement payé par personne morale club, dirigeant, ou consommateur ; annuel/mensuel ; prix | Pas de CGV définitives |
| D07-C : opérateur juridique | Entreprise individuelle / société ; coordonnées et régime de TVA | Pas de mentions/factures finalisées |
| D07-D : hébergement PWA commercial | Fournisseur autorisant SaaS commercial et conditions RGPD adaptées | Ne pas utiliser GitHub Pages comme hébergeur commercial |
| D07-E : mineurs et médias | Autorisations, limites de publication, éventuellement restreindre mineurs au pilote | Pas de déploiement de portraits de mineurs sans vérification |
| D07-F : marque | Nom final proposé par 05 puis recherches / dépôt facultatif payant | Aucun dépôt ni dépense |
| D07-G : données historiques / violation potentielle | Décision après analyse factuelle du fil 04 | Aucune réécriture de l'historique sans validation et plan coordonné |

## Transmission aux autres fils

- **00** : suivre J07-01 à J07-08 comme feux rouges, consulter la PR de cette mission, arbitrer D07-A à D07-G.
- **02** : recevoir exigences RGPD/CGV/retention/hosting (J07-04/05/07/13/16/17), ne coder qu'après validation.
- **03** : exercer des tests RGPD / droits / A-B (J07-02/14/15).
- **04** : confidentialité d'historique et séparation, informations à partager uniquement après assainissement (J07-01/02/15/18/21).
- **05** : registre de droits médias et nom (J07-06/19/20).
- **06** : qualification clients, vendeur, prix, conditions de facturation (J07-09/10/11/26).
- **08** : **aucune donnée ni portrait réel** sans autorisations et accord pilote.
- **09** : hébergement, prestataires, incidents, conservation et restitution (J07-07/12/13/15).

## Sources officielles (consultées le 12/11/2026)

1. [CNIL — responsable de traitement et sous-traitant](https://www.cnil.fr/fr/rgpd-comment-bien-identifier-son-role)
2. [CNIL — article 28 RGPD / contrat sous-traitant](https://cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4)
3. [CNIL — ce qu'est une donnée de santé](https://www.cnil.fr/fr/quest-ce-ce-quune-donnee-de-sante)
4. [CNIL — consentement et mineurs](https://www.cnil.fr/fr/les-bases-legales/consentement)
5. [CNIL — loi Informatique et Libertés / art. 45](https://www.cnil.fr/fr/le-cadre-national/la-loi-informatique-et-libertes)
6. [CNIL — violations et notification](https://www.cnil.fr/fr/violations-de-donnees-personnelles-les-regles-suivre)
7. [CNIL — analyse d'impact](https://www.cnil.fr/fr/RGPD-analyse-impact-protection-des-donnees-aipd)
8. [INPI — étapes du dépôt de marque](https://www.inpi.fr/realiser-demarches/propriete-intellectuelle/etapes-cles-du-depot-de-marque)
9. [Service Public — mentions obligatoires site entreprise et CGV](https://entreprendre.service-public.gouv.fr/vosdroits/F37351)
10. [Service Public — facturation électronique](https://entreprendre.service-public.gouv.fr/vosdroits/F23208)
11. [GitHub — GitHub Pages limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)

### Critères de clôture de mission 07
- [x] Pré-audit de plusieurs sources techniques et juridiques ; matrice initiale, plan et transmissions rédigés.
- [ ] Vérification contrôlée de la nature des anciennes données GitHub et des secrets (fil 04).
- [ ] Analyse de toutes les ressources et licences.
- [ ] Cartographie RGPD par finalité et contrats finalisés (validation professionnelle).
- [ ] CGV, mentions et politique finalisées après décisions D07-A à D07-G.
- [ ] Tests de droits/effacement, sécurité A/B et hébergement.
- [ ] Revue avocat/juriste, fiscalité expert-comptable.
- [ ] Autorisation explicite de lancement commercial par le propriétaire.

**Aucun test automatisé / de production exécuté pour cet audit documentaire.**
