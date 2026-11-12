# Mission 06 — Stratégie commerciale, tarification et lancement

> **Statut : analyse documentée, prix et lancement NON VALIDÉS — 12/11/2026.** 
> Fil responsable : 06. Coordination : fil 00 / `docs/CHANTIER.md` (PR #29) et `docs/HANDOFF.md`.
> **Aucune dépense, souscription, sollicitation commerciale, écriture Supabase, modification Flutter ou intervention sur AS Grinta original.**

## 1. Synthèse / hypothèse à éprouver

**Cible principale** : une équipe adulte de football loisir, vétérans ou entreprise, avec environ 15 à 30 joueurs et un responsable capable de décider d'une dépense commune. La vente se fait par **équipe** et non par association multisport entière.

**Promesse à tester** : « une appli qui prolonge la vie de l'équipe entre les matchs » (disponibilités, composition animée, pronostics, classements, badges, statistiques, bilans), plutôt que « un autre calendrier / outil administratif ».

**Validation manquante** : aucune preuve ici que des équipes extérieures convertissent ou renouvellent. Ne pas confondre intérêt des proches, disponibilité dans le code et intention de payer.

**Contraintes produit vérifiées dans l'audit #25 (non fusionné au moment de cette lecture)** :
- un espace = une équipe ; ni multi-équipes au sein d'un espace ni gestion d'un club entier garanties ;
- compositions officielles de football à 11 ; formats 5/7/8 à développer avant ciblage élargi ;
- identité de marque, maillots, inscriptions/homonymes, règles et termes neutres encore à finaliser ;
- essai 30 jours et calcul annuel `10 € × nombre de joueurs + forfait facultatif` présents en SQL/UI ; tarifs et Stripe non validés ;
- mode de paiement manuel déjà envisagé ; mise en service commerciale et tests de bout en bout absents.

Conséquence : **ne pas viser en premier** les académies de jeunes, les gros clubs multisections, les établissements scolaires ou le foot à 5/7/8 sans validation produit/juridique adaptée.

## 2. Recherche concurrentielle et sources (consultées le 12/11/2026)

| Offre | Prix public affiché | Lecture commerciale |
| --- | --- | --- |
| SportEasy Équipe Standard | Gratuit, jusqu'à 30 membres | Alternative réelle aux fonctions de gestion de base |
| SportEasy Équipe Premium, annuel | **69 €/équipe/an** (5,75 €/mois si annuel) | Concurrent de référence direct ; fonctions comparables : calendrier, compos, votes, stats |
| SportEasy Club Classic, annuel | **3,96 €/membre/an** | Périmètre club multi-équipes, non directement comparable à un espace-équipe AS Grinta |

Sources primaires : [SportEasy Équipe](https://www.sporteasy.net/fr/teams/plans/), [SportEasy Club](https://www.sporteasy.net/fr/clubs/plans/). Prix constatés à date, pas garantis.

**Conséquence** : à 149 € l'année, le produit serait plus du double du SportEasy Équipe Premium (69 €). Il faut démontrer une différence *perçue et utilisée* (gamification, vie collective, contenu de présentation), pas seulement l'affirmer. La gratuité de concurrents crée un risque de conversion fort.

Autres concurrents et leurs prix : **à compléter par sources primaires et dates**, sans inventer de grille tarifaire. Ne pas présenter la taille totale des licenciés français comme marché réellement adressable.

## 3. Modèle tarifaire : proposition, pas décision

**Hypothèse A (référence à tester)** : **149 €/équipe/an** pour un espace équipe, fonctions incluses, essai 30 jours (déjà prévu dans le code), paiement à la charge d'un seul administrateur. À 25 joueurs : 5,96 €/joueur/an.

**Hypothèse B (tarif « premiers pilotes » à tester)** : 119 € pour la première année, limitée à un petit nombre d'équipes explicitement informées que le prix de renouvellement serait 149 €, sous réserve du droit applicable et de l'accord propriétaire. Ce rabais ne doit pas devenir automatique.

**Hypothèse C (test de volonté de payer)** : poser aux responsables trois niveaux indicatifs 69 / 119 / 149 € et la question « accepteriez-vous de payer aujourd'hui ? » ; mesurer paiement réel, objections et renouvellement. Les réponses à un questionnaire ne sont pas des achats.

**Attention** : le code calcule aujourd'hui un prix par joueur, et affiche le nombre facturable. Le passage à un forfait fixe demande une modification du schéma de présentation et des tests serveur ; **ne pas changer le tarif dans le code avant arbitrage propriétaire**.

**À faire valider par fil 07** : modèle B2B/association, possibilité de souscription par particulier, prix affiché TTC ou régime de franchise, conditions d'essai, reconduction, résiliation, remboursement, informations précontractuelles, mentions factures. Aucun prix « définitif » à afficher au public à ce stade.

## 4. Coûts : vérifié vs estimé

| Poste | Montant / contrainte | Qualification |
| --- | --- | --- |
| Supabase Pro pour un projet Micro | **25 USD/mois** dès lors qu'aucun dépassement/add-on ; projet déjà dans organisation Pro | **Tarif public vérifié**, facture réelle non auditée ; [Supabase pricing](https://supabase.com/pricing) |
| Capacité incluse Pro | 100 000 MAU ; 8 Go DB ; 100 Go fichiers ; 250 Go egress ; 2 M invocations Edge | **Tarifs/quotas publics** ; [Supabase pricing](https://supabase.com/pricing), [usage](https://supabase.com/docs/guides/platform/billing-on-supabase) |
| GitHub Pages comme SaaS commercial | **À ne pas utiliser comme hébergement SaaS commercial** d'après restrictions GitHub | **Contrainte vérifiée** ; [limites GitHub Pages](https://docs.github.com/fr/pages/getting-started-with-github-pages/github-pages-limits) |
| Netlify Free (piste à évaluer par fils 02/04/09) | 0 USD/mois, limite **300 crédits/mois** ; pause du site si crédit épuisé | **Tarif/risque vérifiés**, compatibilité et limites commerciales à valider ; [Netlify plans](https://www.netlify.com/pricing/), [FAQ](https://docs.netlify.com/manage/accounts-and-billing/billing/billing-for-credit-based-plans/billing-faq-for-credit-based-plans/) |
| Stripe Payments, carte EEE standard | **1,5 % + 0,25 €** par paiement réussi | **Tarif public vérifié** ; [Stripe](https://stripe.com/fr/pricing) |
| Stripe Billing à l'utilisation | **+0,7 %** sur volume Billing si retenu | **Tarif public vérifié** ; [Stripe Billing](https://stripe.com/pricing), à éviter au tout début si gestion manuelle suffisante |
| Domaine, SMTP, trafic, sauvegardes fichiers, support | Variable selon fournisseur et usage | **Non chiffré réellement** ; obtenir devis/mesure avant engagement |

**Budget de modélisation** : 600 €/an de charges techniques fixes **hypothétiques** (incluant une provision pour Supabase, domaine et imprévus d'hébergement), non une facture vérifiée. Tous les calculs sont en euros et **hors taxes, cotisations sociales, dépenses juridiques/comptables, développements, incidents et dépassements cloud**. Taux de change USD/EUR non fixé.

**Risque technique majeur transmis** : les contrôles de sécurité, Auth/PWA, surveillance effective et restauration (y compris objets Storage) ne sont pas tous validés ; voir fils 03/04/09. Ne pas se reposer sur les seuls résultats d'un test de charge simulé.

## 5. Scénarios financiers (année 1, 149 € par équipe)

Hypothèses identiques dans chaque scénario :
- les N équipes souscrivent et paient 149 € pour une année entière, **pas de rabais, impayé, remboursement, churn, TVA ni saison partielle** ;
- Stripe carte EEE standard + Billing = **2,2 % × 149 € + 0,25 € = 3,53 €** par paiement (arrondi) ; si virement manuel, frais Stripe nuls mais gestion plus lourde ;
- 600 € de technique fixe annuelle (provision) ;
- temps d'acquisition = 4 h/nouveau client et support année 1 = 2 h/équipe, tous deux valorisés **20 €/h** ; donc **120 €/nouvelle équipe** ;
- ces heures ne sont pas forcément décaissées, mais sont un coût d'opportunité ; charge fiscale/sociale du propriétaire **non incluse**.

| Équipes payantes | CA/an | Solde après technique et Stripe | Solde économique après acquisition et support |
| ---: | ---: | ---: | ---: |
| 5 | 745 € | 127 € | -473 € |
| 10 | 1 490 € | 855 € | -345 € |
| 25 | 3 725 € | 3037 € | 37 € |
| 50 | 7 450 € | 6674 € | 674 € |
| 100 | 14 900 € | 13947 € | 1947 € |

**Seuil théorique année 1** avec ces hypothèses : ~24 nouvelles équipes (600 / [149 - 3,53 - 120] = 23,56), avant fiscalité et imprévus. À 119 €, la marge d'une première année devient négative en intégrant 6 h de travail valorisées à 20 €/h (119 - 2,87 - 120 = -3,87 € par équipe avant même les frais fixes).

**Année de renouvellement** (toutes les équipes renouvellent au prix normal, pas de nouvelle acquisition, support 2 h par club) : pour 100 équipes, 100 × (149 - 3,53 - 40) - 600 = **9 947 €** de marge économique théorique avant charges non modélisées.

**Test de sensibilité** : coût technique doublé (1 200 €/an), taux de conversion bas, frais comptables/assurances, modification TVA, pics de trafic, remboursements et support > 2 h peuvent retarder fortement la rentabilité. Ne jamais promettre ces soldes comme bénéfices nets.

## 6. Acquisition : petit entonnoir mesurable

**Aucune prospection lancée sans accord propriétaire.** Sélection initiale : équipes loisirs/vétérans adultes, 15 à 30 membres, terrain et matchs réguliers, interlocuteur administrateur identifié. Pas de collecte nominative dans GitHub.

Objectifs *expérimentaux*, non prévisions observées :
1. 30 équipes **volontairement contactées** après autorisation et conformité démarchage.
2. 10 échanges/démonstrations de 10-15 minutes.
3. 3 clubs pilotes réels (après 2 clubs fictifs A/B, portes G0/G1 du fil 08).
4. 5 équipes payantes en objectif de première commercialisation, sans supposer qu'elles proviendront uniquement des 3 pilotes.

**Démo** : produit aux couleurs d'un club fictif, sans images/noms/données AS Grinta ; montrer un match, une composition, un pronostic et un bilan de saison, en distinguant fonctionnalités actives de contenu de démonstration. Prévoir 60 à 120 secondes de vidéo, pas d'affirmation non testée.

**Suivi commercial agrégé** : canal, équipe sous code, date de première prise de contact, démo effectuée, essai démarré, premier match, activations, retour qualitatif, proposition de prix, accord/refus de payer, paiement effectif, motif de perte. Le fil 07 valide données personnelles et conservation ; fil 08 fournit les métriques produit.

**Indicateurs de décision** : taux contact→démo, démo→pilote, pilote→payant, délai jusqu'au premier match, taux de joueurs activés J+7, niveau d'utilisation entre matchs, minutes de support par club, taux de renouvellement à 12 mois. Les seuils du fil 08 (≥80 % d'activation des invités volontaires, ≥75 % de réponses aux dispos, P0/P1 ouverts=0) restent **proposés, non mesurés**.

## 7. Parcours essai → paiement

**Phase 1 (0 à 5 clients, si validée)** : essai 30 jours existant → décision commerciale → facture conforme → paiement virement → vérification manuelle → activation dans console éditeur ; journaliser date, période, montant, justificatif et responsable sans divulguer les données sur dépôt public.

**Phase 2 (si demande confirmée)** : Stripe Checkout/Payment Links via compte propriétaire séparé, puis webhooks signés côté serveur pour `paid`, `failed`, `refunded`, `canceled` et réconciliation idempotente. **Jamais** activer sur le retour navigateur seul, ni confondre création d'un lien avec paiement confirmé. Tests d'isolement des clubs, panne fournisseur, renouvellement, taxe et annulation impératifs.

**Services à concevoir avec fil 02** : état de l'abonnement depuis serveur, forfait fixe annualisé, intervalle d'abonnement, montant facturé et date de validité, relances, factures, accès après échec paiement, portail client futur ; ne pas exposer de clés Stripe dans Flutter.

**Fil 04** : vérification des événements et de leur origine, verrouillage des opérations privilégiées, protections anti-duplication, rôles opérateur/club ; **fil 03** : scénarios de test facture/activation/suspension/renewal ; **fil 07** : cadre juridique et fiscal.

## 8. Portes de lancement avec fil 08

- **G0** : infra commerciale isolée opérationnelle, Auth testé, conformité pilote, sécurité approuvée ; code déployé ≠ validé.
- **G1** : deux clubs fictifs A/B testés réellement, aucune fuite, inscription, match, stockage, notifications, récupération du compte et facturation fictive contrôlés ; autorisation propriétaire requise avant vrais utilisateurs.
- **G2** : 3 clubs adultes volontaires, onboarding, 2 matchs réels minimum par club, retours documentés, soutien de l'admin mesuré.
- **G3** : validation métier/sécurité/juridique, prix approuvé, facture/process de paiement opérationnels, hébergement compatible SaaS, support et sauvegardes vérifiés. **Seulement alors** ouvrir des paiements réels.

## 9. Décisions à soumettre au propriétaire par le fil 00

| ID | Arbitrage / impact | Recommandation | Statut |
| --- | --- | --- | --- |
| M06-D01 | Cible commerciale initiale | Équipes adultes loisirs/vétérans, 15–30 membres | **À valider** |
| M06-D02 | Modèle et prix public | Un forfait par équipe ; benchmark 69 € SportEasy ; tester 119 € vs 149 € et ne pas fixer avant pilote | **À valider** |
| M06-D03 | Essai et conditions | Conserver 30 jours, préciser modalités juridiques | **À valider fil 07 + propriétaire** |
| M06-D04 | Paiement premier lancement | Virement manuel + facture, puis Stripe après stabilisation | **À valider** |
| M06-D05 | Hébergement commercial | Demander fil 02/04/09 une alternative à GitHub Pages et sa vérification | **Bloquant avant vente SaaS** |
| M06-D06 | Prospection pilote | Autoriser 3 pilotes externes seulement après portes G0/G1, avec fil 08 | **Bloqué sécurité et accord** |
| M06-D07 | Statut et documents juridiques | Fil 07 : statut, assurance, facturation, CGV/CGU/RGPD, TVA, facturation électronique | **Bloquant vente** |

**Droit français / facturation** : la facture électronique entre entreprises est soumise à un calendrier et à des cas d'application différents : réception dès 01/09/2026, émission PME/micro dès 01/09/2027 pour opérations B2B concernées, e-reporting selon B2C/international ; validation du fil 07 requise. Source : [Service Public, facturation](https://entreprendre.service-public.gouv.fr/vosdroits/F23208), [obligations micro-entrepreneur](https://www.economie.gouv.fr/entreprises/gerer-sa-micro-entreprise/micro-entrepreneur-auto-entrepreneur-quelles-sont-vos-obligations).

## 10. Transmission fil 00 et état de preuve

**Terminé** : cadrage cible, prix concurrents primaires datés, modèle à trois hypothèses, budgets prévisionnels distingués des tarifs, scénarios 5/10/25/50/100, entonnoir de vente, dépendances 02/03/04/07/08/09, décisions M06-D01..D07.

**Testé** : arithmétique du tableau calculée à partir des hypothèses ; lecture des fichiers et de la PR #29. **Non testé** : conversion payante, hébergement alternatif, paiement réel, coût cloud observé, usage et satisfaction réels. Pas de tests applicatifs exécutés par ce fil (changement uniquement documentaire).

**Bloqué** : choix tarifaire, conformité et création éventuelle de structure, mise en paiement, choix hébergement commercial, sécurité du lancement, accord pour les contacts externes.

**Règles absolues** : aucune modification ou accès au dépôt original AS Grinta ; aucune modification des bases; aucune dépense / abonnement / prospection sans accord ; pas de fusion de PR par le fil 06 sans contrôles et revue.

Lien de coordination : [tableau du fil 00 — PR #29](https://github.com/samihchaa-wq/Application-football-/pull/29). Toute évolution future de M06-D01..D07 doit être datée et enregistrée ici, puis signalée au fil 00.
