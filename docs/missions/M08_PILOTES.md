# M08 — Accueil et retours des clubs pilotes, printemps 2027

**16 novembre 2026 — DOCUMENTÉ, non testé sur le terrain, non déployé.**
Référence commerciale lue : `5f404e70f70b4e99d754f7064b567d027d66fe03`.
Environnement : clone local commercial, lecture GitHub, aucune connexion Supabase ni écriture de données.

## 1. Mandat, sources et décisions

Préparer **2–3 clubs physiques** en mars/avril 2027, chacun pendant **2–3 mois**. Les dates sont individuelles et restent à arrêter avant accord. Aucun contact, invitation, création de compte distant, dépense, fusion ou déploiement réalisé. AS Grinta original et Carte soirée exclus.

Sources lues : AGENTS.md, HANDOFF.md, CHANTIER.md ; [plan et Fil 08, PR #147](https://github.com/samihchaa-wq/Application-football-/pull/147), `docs/PLAN_DIRECTEUR_2027_2028.md` sur `docs/pilotage-mars-ete-2027` ; [issue #146](https://github.com/samihchaa-wq/Application-football-/issues/146) ; [plan historique](../PILOTE_CLUBS_UX.md) et [fiches historiques T01–T18](../PILOTE_FICHES_EXECUTION.md). Les fiches d'observation restent réutilisables ; leurs dates, seuils, tarifs et statuts ne sont pas des faits actuels.

**Décision commerciale la plus récente :** [correction du 16/11 sur #147](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903574947) : 100 € **par équipe et par an**, exception gratuite pour les pilotes. Pas de première année gratuite généralisée. La portée de l'exception (équipes couvertes, durée, sortie) reste à arrêter avec M06/M07 et le propriétaire. Le corps du plan #147 est antérieur à cette correction. M00 doit le réconcilier ; M08 ne réécrit pas les fichiers centraux.

L'issue #146 reste **le registre commun GO/NO-GO**, avec ses prérequis ; remplacer sa proposition 3–5 clubs / 2–4 semaines par 2–3 clubs / 2–3 mois. Aucun second programme. Son NO-GO n'est pas levé par ce dossier.

## 2. Cohorte proposée, sans recrutement effectué

| Code fictif | Profil recherché | Ce que l'on veut observer |
| --- | --- | --- |
| PIL-A / EQ-A1 | Football loisir adulte à 11, responsable disponible | Adoption simple, disponibilités, animation entre matchs |
| PIL-B / EQ-B1 | Seniors amateurs à 11, faible aisance numérique | Autonomie dirigeant/joueurs, téléphone et récupération de compte |
| PIL-C / EQ-C1 | Club avec plusieurs équipes, une seule équipe pilote initiale | Compréhension club/équipe, rôles et limites du périmètre |

Recommandation **à valider** : une équipe adulte par club au départ ; pas de promesse multisélection, multiéquipes native ou foot à 5/8. M01/M02/M04 doivent qualifier l'espace technique et le cloisonnement avant toute extension. Les mineurs sont hors périmètre proposé jusqu'à cadrage M07 et décision propriétaire ; ce n'est pas une interdiction juridique générale.

Pour chaque club, prévoir un référent et un suppléant autorisé, sans compte partagé ; coordonnées et correspondance codes↔identités dans un espace privé approuvé M07/M09, jamais dans ce dépôt public. Sélection par disponibilité sur la période, vrais matchs programmés, volonté de signaler les problèmes, diversité iPhone/Android/ordinateur et absence de dépendance quotidienne au développeur. Le club fondateur ne remplace pas deux observations externes.

Fiche d'admission à remplir en privé : club physique, équipe exacte et format, référent/suppléant, effectif volontaire, modules souhaités, outils actuels, dates de match, appareils disponibles, début/fin exacts, gratuité autorisée, version des conditions acceptées, canal support et autorisation d'ouverture. Aucun paiement ni carte bancaire à demander pour préparer le pilote.

## 3. Portes d'entrée et calendrier

Toutes les lignes suivantes sont **à obtenir**, aucune n'est déclarée satisfaite ici.

| Porte | Responsable | Preuve attendue avant vraie collecte / ouverture |
| --- | --- | --- |
| Contrat fonctionnel et recette | M01/M03 | Scénarios essentiels réussis sur SHA candidat et environnement visé ; invitations, récupération, saison, match, Live et clôture, PWA ; zéro P0/P1 ouvert |
| Séparation et sécurité | M04 | Tests négatifs entre espaces, rôles, fichiers et comptes suspendus ; pas de risque critique/élevé non traité |
| Cadre pilote | M07/M06 | Conditions, information et droits, données/médias/mineurs, périmètre gratuit, dates et sortie validés ; revue professionnelle selon dossier M07 |
| Exploitation | M09 | Support privé utilisable, restauration DB/Auth/Storage prouvée isolément, incident/rollback, capacité de la cohorte et budget validés |
| Décision d'admission | M00 + propriétaire | Tableau de preuves daté et GO explicite ; le calendrier seul ne donne aucun GO |

- **Novembre–janvier :** préparer les supports et critères ; aucun recrutement implicite.
- **Février :** répétition avec données fictives dans un environnement autorisé ; M03 confronte les guides à la version candidate ; tests d'accès au support et de restitution/export.
- **Mars/avril :** après GO, ouvrir PIL-A, observer son premier match, puis PIL-B/C seulement si aucune anomalie majeure ne rend l'ouverture dangereuse. Ne pas attendre la fin de A pour lancer B/C, sauf incident.
- **Pour chaque équipe :** J0 accueil ; J+2 accès ; J+7 activation ; point sous deux jours après le premier match ; point hebdomadaire court ; bilan médian ; bilan final à la date convenue (deux ou trois mois).
- **Mai/juin puis été :** corrections et retests continus ; bilan consolidé, GO d'élargissement distinct. Exemple de planning, non engagement : début 15 mars → fin 15 mai ou 15 juin ; début 1er avril → fin 1er juin ou 1er juillet. Ne pas annoncer un bilan complet en juin si une cohorte finit en juillet.

## 4. Kit d'accueil — brouillon à valider sur la version candidate

### Fiche remise au référent après autorisation

« Votre équipe teste Petit Filet du [début] au [fin], sans frais sur le périmètre [équipe et modules convenus]. Votre interlocuteur est [contact privé validé] aux horaires [horaires convenus]. En cas de problème, décrivez l'action et ce qui s'affiche ; ne transmettez aucun mot de passe ni lien de connexion. Le test ne déclenche pas de paiement automatique. Avant la fin, nous faisons ensemble le bilan et vous choisissez la suite selon les conditions communiquées. »

Tous les champs doivent être remplis et validés avant remise ; ce texte n'est pas un contrat. Pas de garantie de disponibilité permanente, de délai de correction ou de compatibilité non vérifiée.

### Guide dirigeant — premier match

1. Ouvrir l'adresse commerciale fournie après GO. Créer son propre compte, conserver son identifiant et vérifier la procédure de récupération. Ne pas utiliser le compte d'un autre responsable.
2. Créer ou rejoindre **l'espace exact de l'équipe convenu** ; vérifier son nom avant toute saisie. Si plusieurs équipes apparaissent ou si le mauvais club s'affiche, arrêter et prévenir le support.
3. Vérifier identité, tenues et modules retenus ; créer la saison et vérifier les dates. Ajouter uniquement les informations nécessaires ; aucun import des données d'AS Grinta original.
4. Partager l'invitation uniquement aux joueurs concernés, après autorisation d'ouverture. Vérifier les inscriptions et leurs rôles. Ne pas publier les liens ou codes sur GitHub.
5. Programmer le premier match : adversaire, date, heure, lieu. Vérifier la fiche sur téléphone et l'ouverture des disponibilités. Si le match est trop éloigné, une section peut rester fermée : ne pas recréer le match pour la débloquer.
6. Vérifier disponibilités, effectif et composition avant le gel prévu ; si Live activé, le responsable suit le match puis valide le récapitulatif avant de contrôler résultats et statistiques.
7. Après le match, demander à un joueur de retrouver le résultat ; noter les difficultés et les transmettre avec le formulaire ci-dessous.

Repères hérités à **confirmer par M03 sur la version utilisée** : disponibilités par défaut J-6 à midi Europe/Paris ; pronostics fermés, effectif/composition gelés et Live ouvert à T-15 ; un match Live doit être validé ; vote Homme du match après validation jusqu'à 24 h après le coup d'envoi. Les réglages peuvent modifier certaines ouvertures. L'existence du code ne prouve pas ces comportements en production.

### Guide joueur — cinq actions

1. Utiliser le lien privé reçu du référent, créer son compte et vérifier l'équipe affichée. Attendre l'activation si elle est demandée.
2. Ouvrir le prochain match et répondre à sa disponibilité quand la période est ouverte. Vérifier que la réponse est enregistrée.
3. Consulter les informations du match et les modules activés ; les pronostics sont facultatifs et limités dans le temps.
4. Après le match, retrouver résultat et statistiques ; voter si le vote est ouvert et proposé.
5. En cas de blocage, noter l'heure, le téléphone et l'action ; contacter le référent ou le support privé. Ne jamais communiquer son mot de passe.

### Installation et compte perdu

Le navigateur reste une solution si l'installation n'est pas disponible. Sur iPhone : ouvrir dans Safari, chercher le menu de partage puis l'ajout à l'écran d'accueil. Sur Android : chercher « Installer » ou « Ajouter à l'écran d'accueil » dans le navigateur. Les intitulés et disponibilités varient ; M03 doit vérifier ces étapes sur les appareils ciblés, sans promettre les notifications tant qu'elles ne sont pas testées.

Compte perdu : utiliser la récupération proposée sur l'écran de connexion ; si l'e-mail n'est pas associé au compte ou si le lien ne fonctionne pas, contacter le support privé. Aucun partage de mot de passe temporaire dans un groupe. La récupération autonome est un prérequis de GO, pas un problème à masquer par une formation.

## 5. Accompagnement et traitement des retours

Prévoir une séance initiale de 30–45 min pour le référent et une fiche de 5 min pour les joueurs. Pendant une observation d'autonomie, donner l'objectif sans dicter les menus ; noter toute aide. Une séance accompagnée réussie ne compte pas comme réussite autonome.

Canal proposé : adresse support privée déjà contrôlée par M09, centralisée par le référent ; voie directe privée pour confidentialité ou compte compromis. Adresse, responsable et remplaçant, horaires et procédure d'urgence à arrêter avant ouverture ; aucun service payant créé ici. Cible de fonctionnement à valider : tri quotidien les jours convenus, accusé sous un jour ouvré, sans promesse contractuelle. P0 : alerter immédiatement M00/M04/M07/M09 ; suspendre le parcours touché, préserver les preuves en privé et ne pas retenter une action destructrice. M09 coordonne la reprise, M07 qualifie les notifications nécessaires.

Formulaire court utilisable en texte, sans outil externe créé :

```text
Retour M08-____ / code équipe : ____ / rôle : dirigeant ou joueur
Date et heure + fuseau : ____ / version : ____ / appareil et navigateur : ____
Action souhaitée : ____
Étapes suivies : 1. ____ 2. ____ 3. ____
Résultat attendu : ____ / résultat constaté : ____
Une fois ou à chaque essai ? ____ / empêche de faire quoi ? ____
Contournement possible : ____
Capture facultative expurgée, via canal privé uniquement : ____
```

Pas de nom réel, adresse, code d'invitation, jeton, mot de passe, photo de joueur ni capture brute sur GitHub. Même un code équipe peut rester une donnée pseudonymisée : publier uniquement un résumé effectivement anonymisé ; détails et correspondance en privé. M07 fixe information, accès, conservation, effacement et base légale avant collecte ; ne pas déployer de télémétrie pour obtenir les métriques.

| Qualification | Destination | Traitement |
| --- | --- | --- |
| BUG : attendu non respecté | M02/M03 | Reproduction, ticket, correctif, retest |
| INCOMPRÉHENSION : action possible mais non comprise | M05/M03 | Observer, adapter message ou guide, réessayer sans aide |
| PARAMÉTRAGE : règle ou module mal réglé | Référent + M02 si défaut | Expliquer le réglage autorisé, ne pas modifier les données sans droit |
| IDÉE : nouveau comportement souhaité | M01/M00 | Motif, équipes concernées, arbitrage ; aucune promesse de développement |
| SÉCURITÉ / DONNÉES | M04/M07/M09/M00 | Canal privé prioritaire, ne pas publier la preuve exploitable |

Sévérité alignée au plan #147 : **P0** fuite/élévation de privilège, perte de données ou activité essentielle impossible sans contournement ; **P1** dégradation majeure ; **P2** gêne secondaire/amélioration. M03/M04 confirment la qualification ; ne pas diminuer la gravité pour passer un jalon.

Circuit : reçu → qualifié → reproduit ou non reproduit → affecté → correction proposée → vérification M03/M04 → retest terrain → clos. Un cas non reproduit reste documenté, pas déclaré résolu. Un report conserve motif, risque, décideur et prochaine revue. Chaque retour a un ID, un ticket canonique, les doublons liés, une PR/SHA corrective et une preuve de retest sur la version déployée autorisée ; une PR fusionnée seule ne clôt pas le retour terrain.

## 6. Grilles à copier — vides, aucun résultat inventé

```text
SUIVI ÉQUIPE (privé)
Code club / équipe : ____ / début–fin : ____ / version(s) : ____
Accords et GO datés : ____ / modules convenus : ____
J0 : ____ / J+2 : ____ / J+7 : ____
Premier match réel et point suivant : ____
Semaine : ____ / matchs prévus–réalisés : ____ / actions-clés : ____
Comptes invités–activés : ____ / joueurs concernés–répondants : ____
Tâches observées–réussies sans aide : ____ / minutes de support : ____
Retours ouverts P0/P1/P2 : ____ / tickets et retests : ____
Bilan médian : ____ / date du prochain point : ____
Bilan final et choix de sortie : ____
```

| ID retour | Type / gravité | Ticket canonique | Responsable | Statut | PR / SHA | Retest / version / preuve | Décision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| À renseigner | — | — | — | Aucun retour recueilli | — | Non réalisé | — |

## 7. Mesures et seuils proposés à M00 avant le démarrage

Compter séparément clubs physiques, équipes, comptes et personnes observées. Avec 2–3 clubs, toujours afficher n/N par équipe, périodes et exclusions motivées ; pas de preuve statistique de marché. Valeur manquante = non mesuré, jamais zéro ou réussite.

| Mesure | Définition / fenêtre | Cible de travail, non atteinte |
| --- | --- | --- |
| Activation dirigeant | Équipes avec saison + première invitation + match, J+7 / équipes ouvertes | Toutes, avec guide, sans intervention opérateur sur leurs données |
| Activation joueurs | Comptes activés / invitations réellement transmises, J+7 | ≥80 %, refus et abandons conservés dans le dénominateur ; expliquer séparément |
| Usage régulier | Équipes ayant géré leur match et recueilli des disponibilités / équipes ayant un match prévu, chaque semaine | Toutes sur au moins deux vrais matchs ; semaine sans match = non applicable |
| Engagement joueurs | Joueurs concernés ayant répondu / joueurs concernés par le match | ≥75 % sur au moins deux matchs par équipe |
| Autonomie | Tâches réussies sans aide humaine / tâches observées ; guide écrit autorisé | ≥90 %, au moins un admin et cinq joueurs observés par équipe si effectif suffisant ; décrire tout échantillon réduit |
| Support | Minutes totales, incluant préparation et relances, par équipe/semaine | Cible ≤30 min après les deux premières semaines ; tout dépassement analysé avec M06/M09 |
| Défauts | P0/P1 ouverts et temps jusqu'à correction/retest | Zéro à la décision d'élargissement ; incidents passés explicités |
| Satisfaction | Notes 1–5 séparées admin/joueur, nombre de réponses et non-réponses | Médiane ≥4 ; pas de moyenne masquant un club bloqué |
| Intention de poursuivre/payer | Oui / peut-être / non à l'offre exacte validée M06 ; motif et nombre d'équipes | Au moins 2 clubs favorables sur 3, ou 2 sur 2 ; intention distincte d'une commande |

Questions J+7 : « Qu'avez-vous réussi seul ? Où avez-vous demandé de l'aide ? Qu'est-ce qui vous a empêché d'utiliser l'application ? » Bilan médian : fonctions utiles/inutiles, temps gagné/perdu, outil encore utilisé en parallèle. Bilan final : garder/arrêter et pourquoi ; disposition à payer au tarif confirmé et périmètre annoncé. Témoignage ou logo pour communication : accord distinct préalable ; aucun accord déduit de la participation.

## 8. Fin d'essai et bilan consolidé

Avant accord pilote, arrêter avec M06/M07 la durée et la sortie. Proposition : dates fixes individuelles, point final deux semaines avant fin, confirmation du choix une semaine avant ; aucun prélèvement automatique. Proposer poursuite payante par engagement explicite, prolongation gratuite seulement autorisée, ou sortie avec export et traitement des données selon règles validées M07/M09. Tester export, révocation des accès et suppression/conservation avant toute promesse. Ne pas supprimer automatiquement pour forcer un achat ; ne pas promettre un accès indéfini.

Trame de bilan, **non rempli à ce jour** : dates et matchs réels par équipe ; périmètre annoncé/essayé/non essayé ; versions ; n/N et périodes pour chaque métrique ; assistance ; défauts et liens de retest ; abandons ; raisons d'adoption/refus et intention commerciale ; coût support ; conformité/sécurité/exploitation et risques résiduels ; recommandation M08 ; décision propriétaire datée.

GO élargissement seulement avec durée convenue effectivement observée sur 2–3 clubs, tâches essentielles autonomes documentées, zéro P0/P1 ouvert, corrections retestées, avis M03/M04/M07/M09 et décision M00/propriétaire. Sinon prolongation limitée autorisée avec plan correctif ou NO-GO. Une satisfaction élevée ne lève aucun verrou de sécurité. Une cohorte incomplète n'est pas comptée comme pilote terminé.

## 9. Coordination et compte rendu au chef de projet

| Demande | Livrable attendu | Échéance / effet |
| --- | --- | --- |
| M03 | Valider guides/T01–T18 sur SHA candidat, appareils et scénarios ; preuve fix/retest | Février, bloque ouverture si essentiels échouent |
| M07 | Accord pilote, notice retours, droits médias/mineurs, conservation, sortie et revue adaptée | Avant données réelles, bloque collecte |
| M06 | Fiche offre par équipe, gratuité précise, prix et conditions après test, questionnaire de valeur | Avant accord club ; pas d'offre envoyée ici |
| M02/M04 | Modèle club physique/équipe/espace, rôles et isolement | Avant toute promesse multiéquipe |
| M05 | Libellés et étapes du kit, test d'autonomie | Version candidate |
| M09 | Canal privé, permanence réaliste, reprise/export, coûts support | Avant ouverture |
| M00 | Réconcilier #146 et plan central avec décisions récentes ; enregistrer critères et GO | Avant pilote |

**Livré :** kit, protocole, formulaire, grilles et bilan préparés dans ce fichier. **Contrôles exécutés :** lecture des sources et décisions GitHub, rapprochement des anciens supports et examen statique des libellés Auth ; contrôle du diff et des liens locaux avant commit. **Non exécutés :** application, CI applicative, tests PWA, séance fictive ou réelle, recrutement, support, export/restauration, vérification de production. Zéro résultat terrain.

**Blocages :** validations et preuves du §3 manquantes dans ce travail ; portée gratuite et fin d'essai non arrêtées. **Prochaine action :** M00 fait relire le kit par M03/M06/M07, puis répétition isolée autorisée en février.

**Décision à préparer, sans bloquer cette livraison :** A — deux mois gratuits, une équipe adulte à 11 par club, extension au troisième mois seulement approuvée (recommandé pour ménager le temps de correction) ; B — trois mois dès le départ, même périmètre ; C — autre périmètre explicite à chiffrer et qualifier. Dates et conditions exactes à faire confirmer avant engagement, aucun choix présumé.
