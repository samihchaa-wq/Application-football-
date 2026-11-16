# Mission 06 — Offre, économie et lancement été 2027

Date : **16 novembre 2026, Europe/Paris**. Statut : **proposition documentée, non approuvée et non déployée**.
Référence auditée : main `5f404e70f70b4e99d754f7064b567d027d66fe03`.
Plan lu sur la branche de [PR #147](https://github.com/samihchaa-wq/Application-football-/pull/147), SHA `dd26ace17dc42c1af8bd9773f578f20e5a29067d`.
Périmètre : uniquement dépôt commercial. Aucun accès ni changement AS Grinta original ou Carte soirée.

## 1. Arbitrage actuel : les décisions ont évolué

Le prompt initial demandait un an gratuit puis un prix par club. Les décisions suivantes, consignées dans la conversation de pilotage, le remplacent :
- [Décision paiement immédiat](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903374695).
- [Exception pilotes gratuits](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903395441).
- **[Correction impérative de l'unité commerciale](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903574947) : 100 € PAR ÉQUIPE ET PAR AN**, dès la souscription. Un club physique avec 5 équipes souscrites = 500 €/an ; aucune remise volume décidée.

Ainsi : pas de première année gratuite généralisée ; 2–3 pilotes gratuits au printemps 2027, périmètre/durée à contractualiser. Aucun prélèvement automatique autorisé. HT/TTC et situation fiscale non déterminés ; ne pas annoncer « 100 € HT » ou « 100 € TTC » comme décision acquise.
M00 doit réconcilier le plan et les documents historiques ; M06 ne modifie pas ses fichiers centraux.

## 2. Offre proposée, à faire approuver avant diffusion

**Promesse à éprouver :** « Organisez votre football à 11 et faites vivre votre vestiaire entre les matchs. »
Cible initiale : équipes adultes loisirs, seniors, vétérans, entreprise, avec référent disponible ; pas de présomption de prise en charge du foot à 5/8 ou de toutes les catégories de jeunes.
Acheteur proposé : association ou structure du club, représentée par une personne habilitée ; trésorier/payeur distinct possible. Le coach peut être prescripteur sans pouvoir engager l'association. M07 qualifie chaque catégorie de client ; un bénévole n'est pas automatiquement un professionnel.

| Élément | Proposition de contrat, conditionnée à la recette |
| --- | --- |
| Unité | 1 licence annuelle = 1 équipe identifiée ; facturation groupée possible pour le club après validation technique |
| Périmètre | Disponibilités, effectif, compositions, Live, statistiques, pronostics sans mises/argent, badges et personnalisation ; seulement fonctions M01/M03 validées |
| Limites de travail | 50 comptes/équipe, 2 Go de médias stockés ; quotas proposés, non implantés ni acceptés |
| Vidéos | Distinguer animation de composition et hébergement de vidéos longues ; aucun stockage/streaming illimité promis |
| Support | Référent dirigeant, FAQ et canal privé ; cible de première réponse 2 jours ouvrés à valider M09, aucune astreinte ni délai de résolution garanti |
| Durée | 12 mois à compter de l'activation effective du service après paiement confirmé ; dates visibles avant commande |
| Renouvellement | Proposition : nouvel accord explicite annuel ; aucune reconduction automatique au lancement |
| Gratuité pilote | Proposition : 3 mois à compter de l'activation, dans la fenêtre mars/avril–juin/juillet ; pas une année offerte |
| Fin pilote | Offre payante explicite, refus possible ; pas de débit ni dette par silence |

**Architecture à trancher M01/M02/M04 :** un espace indépendant par équipe ou plusieurs équipes rattachées à un club. Ne pas promettre un compte unique pour 10 équipes, une gestion transverse des joueurs ou des calendriers consolidés avant preuve. Le commentaire de pilotage signale une structure `clubs/club_id`, pas une prise en charge multiéquipes démontrée.

### Écart présent dans le code commercial

Lecture directe :
- `lib/features/club/data/club_subscription.dart` : champs `billable_players`, `price_per_player_cents`, `base_price_cents`, états trial/to_pay/active/past_due/canceled.
- `lib/features/admin/presentation/club_subscription_section.dart` affiche encore « joueurs × prix par an », un essai, et un accès maintenu après essai.
- Ces observations sont **statiques** : aucune preuve d'une activation/paiement effectif.
- `.github/workflows/auto_release_commercial.yml` déclenche sur push main sauvegarde, migrations et publication. Cette livraison reste en branche, sans fusion.

Demandes M02 : tarif versionné fixe par équipe, nombre de licences, période, montant/taxes, preuve d'acceptation et confirmation serveur ; suppression de l'ancien calcul par joueur dans le parcours actif après décision ; conservation des données et contrats historiques. Migration nouvelle si nécessaire, jamais réécriture d'une migration appliquée.

## 3. Repères de marché vérifiés

Tarifs publics consultés les 15–16/11/2026, à vérifier de nouveau avant lancement ; périmètres différents.

| Offre | Prix affiché | Implication |
| --- | --- | --- |
| SportEasy équipe Premium | 69 €/équipe/an ; Standard gratuit | À 100 €, Petit Filet demande 31 € de plus ; prouver une valeur d'usage |
| SportEasy Club Classic annuel | 3,96 €/membre/an | 118,80 € pour 30 membres ; formule club différente |
| Spond | Application gratuite, frais pour collecte d'argent | La gestion seule ne suffit pas à justifier l'achat |

Sources : [SportEasy équipe](https://www.sporteasy.net/fr/teams/plans/), [SportEasy club](https://www.sporteasy.net/fr/clubs/plans/), [Spond](https://www.spond.com/fr/contact/).
Ces offres ont aussi des votes/statistiques/animations communautaires selon leurs périmètres ; aucune exclusivité des pronostics ou badges revendiquée.
Aucune enquête terrain ni volonté de payer prouvée dans ce rapport. Ne pas convertir automatiquement les catégories d'âge d'un club en licences vendables.

## 4. Modèle de coûts reproductible

**Estimations de planification, pas factures ni capacité prouvée.** Les anciens relevés M09 et M06 sont réutilisés comme historiques, pas comme état actuel. Factures, consommation mensuelle et répartition de l'organisation Pro non inspectées dans cette session. Le coût complet de Petit Filet est provisionné ; ne pas compter sur une subvention par l'application originale.

### Sources fournisseurs

| Poste | Tarif public observé | Utilisation dans le modèle |
| --- | --- | --- |
| Supabase Pro | 25 USD/mois, crédit compute 10 USD ; compute Micro ~10, Small ~15, Medium ~60, Large ~110 USD/mois | 1 projet production + provision 10 USD/mois projet de préproduction Micro, sans création |
| DB / fichiers | 8 Go disque inclus puis 0,125 USD/Go ; 100 Go fichiers puis 0,0213 USD/Go/mois | Fichiers 2 Go/équipe ; disque supplémentaire dans réserve, à mesurer |
| Egress | 250 Go/mois non cachés puis 0,09 USD/Go ; cache distinct 250 Go puis 0,03 USD/Go | Hypothèse prudente : 10 Go/équipe/mois entièrement non cachés, API comprise |
| Auth | 100 000 MAU inclus Pro | Hypothèse 30 comptes actifs/équipe : 15 000 pour 500 équipes ; ne prouve pas la tenue des pics |
| SMTP Resend Pro, piste | 20 USD/mois, 50 000 e-mails ; supplément 0,90 USD/1 000 | 2 messages/compte/mois = 30 000 pour 500 équipes ; pics et délivrabilité à vérifier |
| Cloudflare Pages statique | Requêtes statiques gratuites/illimitées ; Functions facturées à part | 0 prévu pour PWA statique ; limites builds/fichiers/conditions et fonctions à contrôler M09 |
| Carte EEE standard Stripe | 1,5 % + 0,25 €/paiement | À 100 €, 1,75 € par paiement ; sans Billing, change, litige ni remboursement |

Sources primaires : [Supabase prix](https://supabase.com/pricing), [compute](https://supabase.com/docs/guides/platform/compute-and-disk), [egress](https://supabase.com/docs/guides/platform/manage-your-usage/egress), [Resend](https://resend.com/pricing), [Cloudflare](https://developers.cloudflare.com/pages/functions/pricing/), [Stripe France](https://stripe.com/fr/pricing).

**Hypothèses financières :**
- Conversion budgétaire **1 USD = 1 EUR**, convention prudente et non cours de marché ; réserve 30 % supplémentaire. Taxes fournisseurs/TVA non récupérable à confirmer dans la réserve.
- N = équipes/espaces autonomes, pas clubs physiques. Pour 100 clubs à 5 équipes, utiliser N=500. Les scénarios demandés 10/100/300/500 clubs ne se traduisent par les lignes ci-dessous que si chacun souscrit une seule équipe.
- Compute sélectionné Micro/Small/Medium/Large respectivement : **enveloppes d'essai**, pas dimensionnement validé.
- Technique annuelle = 12 × [25 + compute + 20 SMTP + 0,0213 × max(2N−100,0) + 0,09 × max(10N−250,0)]. Les 10 USD de préproduction compensent ici le crédit compute de 10 USD.
- Sauvegardes privées : provision 120 + 0,50N €/an ; domaine, boîte support, CI/monitoring : 240 €/an. Aucun fournisseur choisi ou payé.
- Juridique/comptabilité de démarrage : **2 000 €** ; revue sécurité indépendante **2 000 €**, provisions sans devis. À remplacer par devis ; s'ils sont supérieurs, nouveau budget requis.
- Acquisition cash : **20 €/équipe** ; temps commercial 2 h/équipe + onboarding/support 2 h/équipe ; exploitation commune 48 h/an. Temps valorisé 25 €/h, distinct des sorties bancaires.
- Aucun développement initial, salaire, cotisations, IR, CFE, assurance ou sinistre inclus. Un devis de développement/prestation ajoute une ligne au budget.

| Équipes (1 équipe/club ici) | Technique/an | Backup/an | Cash lancement/an* | Plafond proposé +30 % arrondi | Travail/an | Coût avec temps valorisé |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 660 € | 125 € | 5225 € | 6800 € | 88 h | 7425 € |
| 100 | 1556 € | 170 € | 7966 € | 10400 € | 448 h | 19166 € |
| 300 | 4358 € | 270 € | 14868 € | 19400 € | 1248 h | 46068 € |
| 500 | 7220 € | 370 € | 21830 € | 28400 € | 2048 h | 73030 € |

*Cash = technique + backup + 240 + 4 000 + 20N ; frais d'encaissement à ajouter si paiement. Plafond = réserve de planification, **pas autorisation de dépense ni garantie de maximum fournisseur**.
À 500 équipes, 2 048 h/an dépassent la disponibilité raisonnable d'une personne ayant un emploi : admission par vagues et support autonome indispensables.

### Financement et sensibilité

L'ancien scénario de 12 mois offerts aurait exigé le cash entier de la colonne lancement avant toute recette ; il est conservé ici uniquement comme **sensibilité historique demandée**, pas comme offre.
Modèle actuel : 2–3 pilotes gratuits seulement, puis paiement annuel à la souscription. Budget prépilote proposé : **5 000 € à financer avant ouverture**, revue juridique/sécurité incluse ; aucun montant engagé. Ouvrir au plus 10 équipes initiales, puis palier 25, puis 100 selon GO M09/M00 et financement ; 300/500 restent des scénarios.
Pour 100 équipes payantes à 100 €, CA théorique 10 000 €, cash modèle 7 966 € + 175 € d'encaissement = 8 141 €, solde 1 859 € avant temps et prélèvements. Si le plafond de réserve est consommé, cette marge disparaît.
Les recettes sont encaissées par vagues ; des abonnements annuels encaissés aujourd'hui financent 12 mois de service. Réserver la part de service à rendre et les éventuels remboursements plutôt que la distribuer.

À 500 équipes, +10 Go/équipe/mois de trafic non caché ajoute **5 400 €/an**. +1 h support/équipe ajoute 12 500 € de temps valorisé. Passage compute Medium→Large : ~600 €/an supplémentaires. Les Realtime/messages, Edge, transformations images, disque, journaux, branches, TVA et sauvegardes au-delà de la provision demandent mesure et devis M09.
Alertes proposées : 70 % du plafond = revue ; 90 % = gel nouvelles admissions ; toute extension payante attend accord propriétaire. Un spend cap fournisseur peut dégrader le service et ne plafonne pas tous les postes : M09 vérifie son périmètre.

## 5. Prix et rentabilité future

**100 €/équipe/an est l'arbitrage de travail reçu, pas un test de prix arbitraire.** À 30 membres : 3,33 €/membre/an, simple équivalence sans facturation individuelle.
Proposition : conserver ce prix pour le périmètre initial ; revoir coût/support après pilotes avant tout contrat externe si intenable, plutôt que promettre stockage ou accompagnement illimités.
Les options 149/199 € demanderaient une nouvelle décision ; elles ne sont pas des tarifs publics approuvés.

Marge de renouvellement simulée : toutes les équipes renouvellent, pas d'acquisition ni de devis initiaux 4 000 €, provision conformité récurrente 1 000 €/an, support 1 h/équipe + 48 h exploitation valorisés 25 €/h ; carte 1,75 €/équipe. Prix considéré comme revenu hors TVA pour l'illustration uniquement.

| Équipes payantes | CA annuel à 100 € | Solde économique récurrent simulé avant fiscalité |
| ---: | ---: | ---: |
| 10 | 1000 € | -2492 € |
| 100 | 10000 € | 3159 € |
| 300 | 30000 € | 14907 € |
| 500 | 50000 € | 26595 € |

Ce solde n'est ni salaire ni net personnel. Une TVA comprise dans les 100 € réduirait le revenu disponible : à titre arithmétique si taux 20 % applicable, 100 € TTC = 83,33 € HT, soit 16,67N € de CA en moins par rapport au modèle. Régime/taux à confirmer M07/comptable.
À 200 licences, 20 000 €/an de CA avant charges représentent au plus 1 667 €/mois avant toutes charges : cela ne permet pas 2 500 € nets/mois. Les cotisations micro éventuelles portent sur le CA selon la qualification réelle ; elles ne sont pas calculées sur cette marge. BIC/BNC, TVA, CFP, CFE, IR, statut et situation familiale restent à valider professionnellement. Aucun conseil de démission fondé sur cette projection.
Conversion et renouvellement non observés : si 50 % de 100 équipes seulement renouvellent, CA 5 000 € ; ne pas garder artificiellement toute la recette du scénario 100. Acquisition et support de l'année précédente ont déjà été engagés.

## 6. Parcours souscription et sortie à spécifier M02/M07/M03

1. Présenter équipe(s), prix final, taxes applicables, période, fonctions, limites, identité vendeur, support et conditions ; vérifier pouvoir du signataire.
2. Pilote : accord gratuit distinct et dates convenues. Proposition 3 mois, rappels J−30 et J−7 ; ne pas compter une inscription de démonstration comme activation.
3. Vente : acceptation explicite et paiement confirmé côté serveur ; aucun accès payant sur simple retour navigateur ou capture de virement.
4. Première méthode proposée : facture conforme + virement contrôlé manuellement pour faibles volumes ; Stripe Checkout après recette. Aucune intégration/compte marchand créé par M06.
5. Paiement échoué/doublon/événement retardé : réconciliation idempotente par équipe et période, pas de double prolongation, pas de fuite interéquipe ; notification à un responsable habilité.
6. Renouvellement : rappels J−60/J−30/J−7, nouvelle acceptation ; si absence de paiement, proposition mode consultation/export 30 jours puis fermeture des opérations selon contrat validé. Aucun effacement immédiat.
7. Résiliation : accès jusqu'à l'échéance si payé, confirmation conservée ; rétractation/remboursement et exceptions selon catégorie juridique déterminée par M07, jamais présumer « aucun remboursement ».
8. Restitution : export club et droits individuels vérifiés ; conservation et purge distinctes de la fermeture commerciale, sauvegardes incluses selon M07/M09.

Recette demandée : changement équipe/payeur, année bissextile, échéance et fuseau, webhooks rejoués/inversés, paiement sans retour navigateur, échec/reprise, remboursement partiel/total, avoir/facture, refus de payer, export et réouverture. Aucune de ces recettes n'a été exécutée ici.

## 7. Kit prêt à adapter avant autorisation de prospection

### Fiche de présentation (brouillon interne)

Petit Filet accompagne les équipes de football à 11 avant, pendant et entre les matchs : disponibilités, composition, Live, pronostics, badges et statistiques selon le périmètre validé. Un dirigeant pilote l'espace ; les joueurs participent depuis leur téléphone.
Tarif décidé : 100 € par équipe et par an, paiement dès souscription ; mention fiscale à finaliser. Pour plusieurs équipes, chaque licence est identifiée ; parcours multiéquipes à valider avant promesse. Test gratuit réservé aux 2–3 pilotes sélectionnés, conditions écrites.
Une démonstration se fait sur données fictives. Pas de promesse de fiabilité absolue ou de remplacement des outils fédéraux.

### Démonstration de 10 minutes, propriétaire M05/M08

- 0–2 min : invitation/connexion dirigeant et joueur, interface téléphone.
- 2–4 min : disponibilités, sélection et composition.
- 4–6 min : Live et validation du compte rendu.
- 6–8 min : pronostic, badge, statistiques ; vérifier que les droits et horaires de démonstration sont cohérents.
- 8–10 min : paramétrage, aide, prix annuel et export/sortie.
M03 doit valider ce scénario sur le SHA montré ; prévoir captures de secours signalées comme telles. Aucune image réelle AS Grinta ni témoignage sans autorisation.

### FAQ commerciale

- « Gratuit ? » Seulement le test des pilotes convenus ; offre générale 100 €/équipe/an.
- « 5 équipes ? » 500 €/an, sans remise décidée ; parcours et formats à confirmer.
- « Mes joueurs paient ? » Un responsable règle la licence pour l'équipe ; aucune facturation par joueur prévue.
- « U7/foot à 8 ? » Pas d'engagement tant que le format et le cadre mineurs ne sont pas validés.
- « Obligé de renouveler ? » Proposition initiale : accord annuel explicite ; sortie et export prévus au contrat.
- « Mes données et vidéos ? » Droits, accès, quotas et conservation sont annoncés avant signature ; pas de médias illimités.

### Canaux et calendrier juillet–septembre 2027

| Période | Travail préparé | Objectif expérimental et condition |
| --- | --- | --- |
| Mars–juin | 2–3 pilotes, observation 2–3 mois chacun, corrections au fil de l'eau | Bilan M08 et GO M03/M04/M07/M09 ; pas de témoignage publié sans accord |
| Juin | Fiche, vidéo courte fictive, FAQ, tarif/taxes, contrats, suivi privé | Liste qualifiée et méthode de contact validées ; aucune sollicitation avant autorisation |
| Juillet | Recommandations dirigeant→dirigeant, réseaux loisir/vétérans, présentations locales autorisées | 40 équipes qualifiées → 12 démos → 4 souscriptions visées |
| Août | Relances autorisées et préparation de saison ; pas de relance après opposition | 40 → 12 → 4, ajuster aux congés |
| Septembre | Retours premiers matchs et recommandations consenties | 40 → 12 → 4 ; arrêter l'acquisition si support/sécurité dépassés |

Total cible : 120 équipes qualifiées, 36 démos, 12 ventes ; **aucun contact ni résultat effectué**. Distinguer clubs physiques uniques, équipes, licences payantes, revenus encaissés. Une démo de 5 équipes d'un club ne devient pas 5 ventes.
Canaux prioritaires : recommandation des pilotes, associations de foot loisir/entreprise, réseaux locaux et districts/ligues seulement avec accord d'accès ; contenus démonstratifs et demandes entrantes. Pas d'achat de fichier, scraping de coordonnées personnelles, publicité payante ni sponsoring budgété sans accord.
Tester 15–20 entretiens extérieurs après autorisation : outil actuel, problème concret, coût du changement, décisionnaire, budget, intention d'achat à 100 €. L'intérêt verbal ne vaut pas paiement.

**Suivi privé à préparer, aucun CRM nominatif dans GitHub public :** identifiant prospect, club physique, nombre d'équipes éligibles et format, canal/source/date, base de contact validée M07, consentement/opposition le cas échéant, décideur, étape, prochaine action, démo/SHA, souscription/licences, montant encaissé, motif de refus, temps et coût.
Étapes : qualifié → contact autorisé → échange → démo → décision → payé/activation → actif → renouvelé ou perdu. Export public uniquement agrégé.
Mesures hebdomadaires : contacts/démos/ventes, CA réellement encaissé, CAC cash et heures séparés, premier match réalisé, joueurs actifs, minutes support, refus et oppositions. Revue à 10 démos sans vente ou CAC cash >30 € ; ne pas élargir un canal sans apprentissage.

Prospection : M07 vérifie le régime selon destinataire et canal, notamment les bénévoles et adresses nominatives. La CNIL distingue consentement pour particuliers et règles professionnelles ; chaque message doit identifier l'émetteur et permettre le refus. Source : [CNIL prospection électronique](https://www.cnil.fr/fr/la-prospection-commerciale-par-courrier-electronique). Une offre gratuite reste une démarche commerciale selon sa finalité. Aucun envoi préparé ou réalisé.

## 8. Dépendances et décisions A/B/C pour M00

| ID / destinataire | Demande et preuve attendue | Proposition |
| --- | --- | --- |
| M06-01 / M00 | Réconcilier plan initial et dernier arbitrage 100 €/équipe, non club | Tarif reçu appliqué au dossier ; pas de nouvelle hausse décidée |
| M06-02 / M07 + M08 | Durée gratuite pilotes et portée équipe/club ; accord avant activation | A : 3 mois par équipe pilote (recommandé) ; B : 2 mois ; C : autre durée écrite |
| M06-03 / M02 + M04 | Architecture plusieurs équipes, comptes/rôles/factures ; tests de cloisonnement | A : espaces autonomes (à évaluer) ; B : multiéquipes natif ; C : limiter commercialisation à une équipe par club temporairement |
| M06-04 / M09 | Coût réel dédié/mutualisé, pics Auth/Realtime/Edge, médias, SMTP, restore, alertes et limites | A : 10 puis 25 puis 100 (recommandé) ; B : 300 après preuve ; C : 500 après preuve et renfort support |
| M06-05 / M07 | Signataire, catégorie client, HT/TTC, TVA, statut, facturation électronique, remboursement, prospection | Bloquant offre externe ; [issue #39](https://github.com/samihchaa-wq/Application-football-/issues/39) |
| M06-06 / M09 + M00 | Devis et financement des 5 000 € prépilotes ; cash protégé de service futur | A : enveloppe proposée après devis (recommandé) ; B : différer pour réduire périmètre/coût validé ; C : autre plafond |
| M06-07 / M02 + M03 | Remplacer affichage par joueur et états essai, tests paiement/périodes/sortie | Développement/recette séparés ; aucune modification M06 |
| M06-08 / M09 + M07 | Destination privée backup, coût et restauration complète | [issue #91](https://github.com/samihchaa-wq/Application-football-/issues/91), preuve requise |
| M06-09 / M05 + M08 | Démo réelle téléphone, guide et validation des supports | Aucune démonstration externe avant GO |

Les demandes sont consignées sur GitHub pour lecture par les missions ; cela ne les relance pas automatiquement.
Aucun contact ni dépense autorisé par ces propositions.

## 9. Compte rendu vérifiable

**Livré :** offre adaptée au dernier arbitrage, modèle chiffré 10/100/300/500 unités, sensibilité ancienne année offerte, prix et limites, kit de présentation/démo/FAQ, entonnoir été 2027, dépendances M02/M07/M09/M08.
**Vérifié :** lecture du plan, AGENTS, HANDOFF, CHANTIER et anciens rapports M06/M07/M09 ; lecture code abonnement et workflow effectif ; sources publiques fournisseurs et concurrence ; calculs exécutés en JavaScript, arrondis à l'euro, plafond arrondi aux 100 € supérieurs.
**Non vérifié :** factures et usage cloud réels, capacité des paliers, délivrabilité, parcours paiement/export, statut fiscal, devis professionnels, intérêt et conversion terrain.
**Tests applicatifs exécutés : aucun. CI de cette livraison : à relever sur son SHA. Déployé : non. Accepté : non.**
Blocages : architecture équipe/club, régime fiscal/prix final, conditions pilotes, budget et GO sécurité/recette/restauration.
Prochaine action : relecture M00/M07/M09 puis spécifications M02 et recette M03 ; pas de fusion automatique.
Fin de mission globale : **non atteinte** tant que coûts mesurés, financement, conditions approuvées et validation terrain ne sont pas établis.
