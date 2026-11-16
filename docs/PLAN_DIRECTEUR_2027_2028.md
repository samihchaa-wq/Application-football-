# Petit Filet — Plan directeur 2027–2028 et prompts de missions

Document de pilotage proposé par le fil 00 le **15 novembre 2026**, actualisé le **16 novembre 2026** (Europe/Paris).
Il transpose la dernière demande du propriétaire. Il ne vaut ni autorisation de mise en production ni validation des neuf missions.
Référence technique observée : `main` à `5f404e70f70b4e99d754f7064b567d027d66fe03`.
La branche courante est une proposition documentaire ; aucun code ni paramètre Supabase n'est changé.

## 1. Destination et décisions acquises

- Produit commercial **Petit Filet**, distinct d'AS Grinta original et de Carte soirée, qui restent exclus de toute modification.
- **Mars/avril 2027 :** montrer une version complète et prête à l'usage à **2–3 clubs**.
- Pilotes validés le 16/11/2026 : **3 mois gratuits**, **adultes au football à 11**, **une équipe par club physique**.
- Corriger et retester les retours, puis consacrer **2–3 mois à l'été 2027** à la présentation à davantage de clubs.
- **100 € par équipe et par an, dès la souscription** ; essai gratuit réservé aux 2–3 équipes/clubs pilotes, dont la portée exacte reste à contractualiser.
- Priorités : fonctionnement de toute la version promise, sécurité, capacité de plusieurs centaines de clubs, conformité légale démontrable.
- Le niveau attendu est une version utilisable au quotidien. La période pilote sert à éprouver l'usage et l'autonomie ; elle ne dispense pas des contrôles de sécurité ou de conformité préalables.

**Remplace les hypothèses antérieures :** objectif générique mai 2027, bêta 3–5 clubs pendant 2–4 semaines de l'issue #146, essai 30 jours et ancien prix indicatif 10 €/joueur/an. Les anciennes valeurs ne doivent pas être reprises comme décisions du propriétaire.

**Décisions commerciales actualisées :** la [correction du 16 novembre](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903574947) remplace l'année gratuite généralisée et les anciennes mentions à 100 €/club/an. L'unité commerciale est **l'équipe** : cinq équipes représentent 500 €/an, sous réserve de conditions et traitement fiscal précisés avant offre. Le club physique reste une organisation à distinguer de ses équipes.
**Pilotes :** trois mois gratuits, une équipe adulte de football à 11 par club, sur 2–3 clubs physiques. Décisions 1A/2A/3A confirmées directement par le propriétaire le 16/11/2026. Fixer les dates individuelles et les conditions de sortie avant signature. Aucun prélèvement automatique présumé après l'essai.
**À préciser avant toute offre externe :** prix HT/TTC et fiscalité, identité juridique, paiement/contrats, fin de l'essai pilote, périmètre multiéquipe et droits associés, extension éventuelle aux mineurs après les pilotes et budget.
**Architecture à étudier par M01/M02/M04 :** espace indépendant par équipe ou plusieurs équipes sous un même club ; ne pas assimiler les `clubs` techniques actuels à une structure multiéquipe déjà prouvée. Le football à 5/8 reste à qualifier avant promesse à des catégories de jeunes.
Le calendrier technique reste mars/avril 2027 puis été 2027. Le **paiement est à préparer avant l'ouverture payante de l'été 2027**, sans attendre 2028.

## 2. État vérifié, sans pourcentage artificiel

| Sujet | Ce qui a été observé le 15/11 | Ce que cela ne prouve pas / suite |
| --- | --- | --- |
| Code et livraison | PR #144 fusionnée ; Flutter CI et Supabase business/RLS verts sur le commit main relevé ; publication Cloudflare réussie | La réussite de tous les parcours et de tous les appareils reste à documenter sur cette version |
| Sauvegarde | Workflow Production backup réussi sur le même commit | Ne prouve pas la récupération complète ; exercice isolé DB/Auth/Storage et preuve d'intégrité à rassembler (#91) |
| Supabase | Projet commercial actif en eu-west-3 ; advisor : 165 avertissements fonctions privilégiées, 1 avertissement mots de passe compromis, 1 information RLS sans policy sur journal privé | Qualifier les fonctions et exceptions ; ne pas confondre un warning et une faille démontrée |
| Sécurité | Rapports et garde-fous présents ; PR #145 de défense Storage ouverte en brouillon | Audit et tests négatifs complets JWT/REST/RPC/Storage/Edge/Realtime à consolider |
| Capacité | Harnais local : 200 clubs × 30 profils, 50 clients pgbench par défaut | Ni preuve de 6 000 téléphones simultanés ni garantie sur infrastructure hébergée ; charge complète et coûts à mesurer |
| Bêta | Issue #146 : checklist commune existante, NO-GO documenté | Mettre le nouveau calendrier en cohérence ; lever les critères avec preuves avant vrais clubs |
| Conformité | Pré-audit juridique et modèles présents | Documents anciens, qualifications et preuves à revoir ; aucune conformité finale démontrée par cette lecture |

Sources de l'état :
- [Commit de référence](https://github.com/samihchaa-wq/Application-football-/commit/5f404e70f70b4e99d754f7064b567d027d66fe03).
- [Flutter CI](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196815), [Supabase/RLS](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196869).
- [Sauvegarde réussie](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769955168), [publication Cloudflare réussie](https://github.com/samihchaa-wq/Application-football-/actions/runs/43770267267).
- [Recette sécurité/concurrence](RECETTE_SECURITE_CHARGE_20261115.md), [PR #145](https://github.com/samihchaa-wq/Application-football-/pull/145), [issue bêta #146](https://github.com/samihchaa-wq/Application-football-/issues/146), [reprise #91](https://github.com/samihchaa-wq/Application-football-/issues/91).
- [Linter fonctions privilégiées](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) et [protection des mots de passe compromis](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

**Contradictions documentaires à réconcilier par M00 :** HANDOFF/CHANTIER/README contiennent des photographies anciennes. En particulier, le workflow actuel `auto_release_commercial.yml` déclenché sur push main orchestre sauvegarde, application de migrations et publication Cloudflare. Une fusion peut donc avoir un effet distant même si d'anciens textes disent le contraire. Ne pas fusionner ce plan pour sa seule valeur documentaire sans revue de la chaîne réelle.
La réussite de la publication ne règle pas à elle seule les URL effectives : `config/production.json` affiche encore une URL publique GitHub Pages ; M02/M09 doivent retracer les substitutions et les redirections réellement utilisées.

## 3. Calendrier et portes de sortie

Dates = objectifs de planification. Les preuves et le GO propriétaire conditionnent les ouvertures ; une date atteinte ne transforme pas un contrôle non exécuté en contrôle réussi.

| Période cible | Travail principal | Condition de passage |
| --- | --- | --- |
| 15 novembre–décembre 2026 | Baseline commune, inventaire complet, tickets consolidés, priorités et critères, environnements | Chaque fonction promise a un attendu, un test et un responsable ; écarts et autorisations identifiés |
| Décembre 2026–janvier 2027 | Finaliser parcours, multiclub, Auth/e-mails, modules et correction des anomalies | Version candidate complète ; pas de parcours essentiel connu bloqué ; QA indépendante des correctifs |
| Décembre 2026–février 2027, en parallèle | Sécurité, conformité pilote, exploitation/restauration et capacité | Dossiers M04/M07/M09 et résultats reproductibles ; limites explicites |
| Février 2027 | Recette générale et répétition d'un club neuf/saison/match complet, version stabilisée | GO pilote : toute la grille ci-dessous satisfaite |
| Mars/avril–juin/juillet 2027 selon les dates exactes | 2–3 clubs, une équipe adulte à 11 chacun, trois mois gratuits ; suivi et correctifs continus | Bilan terrain, tâches clés réalisées sans aide permanente, incidents et retours tracés |
| Mai–juin 2027 | Consolidation des retours, correctifs prioritaires et nouvelle recette | GO diffusion élargie, nouvelle capacité mesurée et support prêt |
| Juillet–septembre 2027 | 2–3 mois de démonstrations et acquisition ; entrées par vagues | Les admissions restent sous la capacité, le budget et le support validés |
| Avant l'ouverture payante de l'été 2027 | Finaliser offre 100 €/équipe/an, contrats, acceptation, encaissement et facturation ; tester tous les états d'abonnement | Conditions approuvées, parcours payé testé, essai pilote et sortie clairement encadrés |
| 2027–2028 | Exploitation des équipes abonnées, support, suivi des coûts et renouvellements à douze mois de chaque souscription | Renouvellement, annulation et restitution conformes au contrat ; aucune facturation surprise |

Un pilote commençant en avril pour trois mois se termine fin juin : les correctifs doivent être traités au fil de l'eau pour préserver la prospection d'été.
Recommandation de pilotage : limiter les nouveautés après janvier ; toute extension de périmètre passe par un arbitrage coût/délai/risque. Ne pas supprimer une fonctionnalité attendue pour améliorer artificiellement le taux de réussite.

## 4. Ce que signifie « prêt »

### GO pour les premiers pilotes réels

- Matrice exhaustive du périmètre ; scénarios essentiels exécutés et réussis sur le SHA candidat et l'environnement visé.
- Aucun défaut bloquant/majeur non résolu sur un parcours promis ; aucun risque critique/élevé de sécurité non traité. Les niveaux sont définis dans le registre, pas requalifiés pour passer le jalon.
- Tests négatifs interclubs avec identités réelles de test ; accès admin/opérateur, sessions et médias maîtrisés.
- Création/invitation/connexion et récupération autonome de compte par e-mail utilisables pour les profils concernés ; parcours existants à e-mails synthétiques traités.
- Essais iPhone/PWA, Android et ordinateur effectués ; notifications et flux d'agenda éprouvés dans les contextes annoncés.
- Sauvegarde privée exploitable et restauration DB/Auth/fichiers complète prouvée dans un environnement isolé, objectifs de reprise convenus.
- Conditions pilote et information des personnes en place, obligations RGPD et droits médias/minorité traités selon le périmètre réel.
- Surveillance, canal support, procédure d'incident et possibilité de revenir à une version sûre.
- Capacité suffisante mesurée pour la cohorte pilote, enveloppe financière validée et accord d'ouverture du propriétaire.

### GO pour une diffusion à plusieurs centaines de clubs

Tous les critères pilote, plus :
- Retours pilotes consolidés, corrections importantes retestées, expérience d'un club autonome observée.
- Capacité démontrée sur une infrastructure représentative avec pics de week-end, Auth/API/Realtime/Storage/notifications et contrôle d'intégrité.
- Seuils de performance/erreur et coût, limites d'admission et alertes convenus ; aucune extrapolation d'un simple nombre de clubs dans les données.
- Revue de sécurité indépendante à prévoir et rapport avec remédiation, sous réserve d'accord sur son budget ; le besoin est élevé compte tenu du cloisonnement et de l'ambition de diffusion.
- Dossier de conformité et contrats revus professionnellement, documents et application cohérents ; statut/conditions de gratuité clarifiés.
- Support, coût des pilotes gratuits et exploitation des équipes abonnées financés ; acquisition par vagues et plan de retour arrière.

### GO pour le payant

- Offre annuelle **100 €/équipe/an** approuvée et annoncée, traitement HT/TTC et modalités d'acceptation établis.
- Parcours complet testé : souscription payante initiale, fin de l'essai pilote le cas échéant, acceptation/refus, paiement réussi/échoué, doublon de notification du prestataire, renouvellement, annulation, facture/avoir et restitution/export.
- Qualification juridique des acheteurs et obligations applicables confirmées ; situation fiscale/facturation vérifiée avec le professionnel adapté.
- Pas de suppression de données automatique non prévue pour forcer la conversion.
- Revalidation sécurité/capacité/conformité au moment du passage payant.

**Objectif de capacité proposé à confirmer :** cible nominale 300 clubs, palier de résistance 500 clubs. M09 définit les membres, activités et appareils simultanés, volumes de données et médias, durée des tests et infrastructure associée.
Exemple de seuil de travail, à valider avant campagne : p95 des appels API métier courants ≤ 1 s hors réseau client et transferts médias, erreurs serveur < 0,5 %, zéro perte/doublon non prévu et zéro accès interclub non autorisé observé, essai prolongé et pic au-dessus du nominal. Les scénarios lourds ont leurs budgets distincts. Ces chiffres sont des propositions, pas des résultats.

On vise **des preuves vérifiables et une réduction des risques**, pas une certification de fiabilité ou conformité absolue.

## 5. Neuf missions distinctes, continuité avec les fils existants

| Fil | Périmètre principal | Liens et frontières |
| --- | --- | --- |
| 01 | Inventaire et contrat fonctionnel | Donne les critères à M02 et M03 ; signale les données et règles sensibles à M04/M07. |
| 02 | Développement et parcours multiclub | Reçoit les exigences M01/M05/M06/M07 et les anomalies M03/M04/M08 ; fait valider ses PR par M03/M04. |
| 03 | Recette fonctionnelle et non-régression | Reçoit M01 et les PR M02 ; transmet les défauts à leur propriétaire et les preuves à M00/M08. M09 possède la charge ; M04 possède l'audit de sécurité. |
| 04 | Sécurité et séparation des clubs | Transmet corrections à M02, tests à M03, obligations incident/confidentialité à M07, durcissement exploitation à M09. |
| 05 | Expérience utilisateur, identité et accessibilité | Donne les spécifications à M02, les critères à M03, les ressources à M07 et la démonstration à M08/M06. |
| 06 | Modèle économique et lancement | M07 qualifie les contrats ; M09 chiffre l'exploitation ; M02 implémente ; M08 teste les supports sans contacter de clubs sans ordre explicite. |
| 07 | Juridique, RGPD et droits | M01 précise les traitements ; M02 implémente ; M03 prouve les droits utilisateurs ; M04/M09 apportent les mesures ; M05 apporte la provenance ; M06 précise offre et clients. |
| 08 | Clubs pilotes et retours terrain | Ne lance qu'après GO M00/M03/M04/M07/M09 ; remonte défauts à M02/M03, friction à M05 et demandes produit à M01/M00. |
| 09 | Capacité, sauvegardes et exploitation | M03 teste les parcours ; M04 vérifie les droits ; M07 encadre données/prestataires ; M06 utilise les coûts ; M00 décide des paliers d'ouverture. |

**M00 — chef de projet :** seul propriétaire du plan, du tableau consolidé et de la réconciliation HANDOFF/CHANTIER. Regroupe les travaux, tranche les priorités avec le propriétaire, vérifie les preuves, dépendances et jalons. Ne remplace pas le résultat d'une mission par une reformulation optimiste.

Dépendances :
1. M01 fixe le contrat ; M02 réalise et corrige ; M03 vérifie.
2. M04, M07 et M09 commencent dès maintenant et bloquent un jalon si nécessaire.
3. M05 améliore les parcours et apporte les médias à M07 ; M06 fixe l'offre avec M07/M09.
4. M08 prépare tôt les pilotes, les lance après GO et renvoie les retours à M00/M01/M02/M03/M05.
5. M00 clôt un lot uniquement après preuves de la version concernée et distingue intégration, publication et recette.

## 6. Coordination entre discussions

Les discussions ChatGPT ne forment pas un groupe actif permanent et ce fichier ne les réveille pas. Le fil 00 n'a pas de canal d'envoi direct à tous les autres fils.
Le mécanisme concret est **GitHub comme mémoire commune**, lue par chaque mission quand elle s'exécute :
- Réutiliser les neuf discussions déjà existantes quand elles correspondent ; ne pas multiplier les fils équivalents.
- Coller le prompt de mission ci-dessous dans le fil concerné en conservant son numéro.
- Chaque mission commence par les sources actuelles, publie un compte rendu propre dans `docs/missions/` par branche/PR et lie les issues/PR existantes.
- M00 lit ces éléments, maintient les priorités et la synthèse centrale. Les autres missions ne modifient pas les fichiers centraux en concurrence.
- Pour une dépendance intermission, inscrire la demande et la preuve dans le rapport ; ne pas prétendre qu'un message GitHub relance une conversation.
- Les automatisations citées dans des documents anciens ne sont pas vérifiées par ce plan ; aucune programmation n'a été créée/modifiée pour cette demande.
- Une exécution dans une conversation n'implique pas que les huit autres travaillent en même temps.

Format court pour chaque compte rendu :

```text
Mission / date / SHA / environnement :
Livré et lien PR :
Tests exécutés et preuves :
Non vérifié / limites :
Blocages et mission concernée :
Prochaine action :
Décision propriétaire (si nécessaire) : A / B / C et recommandation.
```

Statuts : **à examiner / en cours / développé / testé en CI / testé réellement / déployé / accepté**, avec preuves adaptées. « Bloqué » indique une cause et une action de déblocage.
P0 : fuite/élévation de privilège, perte de données ou impossibilité d'une activité essentielle sans contournement ; P1 : dégradation majeure ; P2 : gêne secondaire/amélioration. M03/M04 affinent ces catégories.

## 7. Conformité : livrables et méthode

Le dossier doit couvrir obligations applicables avant de vraies données, même pendant l'offre gratuite. Il réunit :
- Qualification des rôles éditeur/club par finalité, information, bases légales et contrats de sous-traitance quand requis.
- Registre, conservation, export/rectification/effacement, sortie du club et effets des sauvegardes.
- Mineurs, droit à l'image, vidéos et éventuelles données de santé ; minimiser les données et éviter les collectes inutiles.
- Licences et provenance des ressources, droits sur le code/contributions, nom/marque et conditions des prestataires.
- Mentions légales, CGU, contrat pilote gratuit, confidentialité et conditions d'abonnement annuel par équipe dès souscription.
- Qualification des clubs/acheteurs : ne pas présumer « B2B » pour toute association ; évaluer règles d'abonnement, reconduction, résiliation et protections applicables.
- Statut de l'éditeur, fiscalité/facturation, prospection, accessibilité et autres obligations à qualifier selon activité et taille effectives.
- Revue d'un juriste/avocat compétent et validation comptable des sujets concernés avant engagements correspondants, sans commander de prestation sans accord.

Une acceptation générique de confidentialité ne remplace pas une base légale ; l'hébergement en France ne règle pas à lui seul tous les flux et transferts. Un texte rédigé ne prouve pas qu'une suppression ou un export fonctionne.

Sources officielles vérifiées pour ce cadrage, à réactualiser pendant M07 :
- [CNIL — qualification des rôles](https://www.cnil.fr/fr/rgpd-comment-bien-identifier-son-role).
- [CNIL — sport amateur, photos, mineurs et données](https://www.cnil.fr/fr/sport-amateur-hors-contrat/questions-reponses).
- [CNIL — santé des sportifs](https://www.cnil.fr/fr/sportifs-quels-cas-et-conditions-collecte-des-donnees-de-sante).
- [Service Public — mentions d'un site professionnel et distinction des clientèles](https://entreprendre.service-public.gouv.fr/vosdroits/F37351).

M09/M02 vérifient également les documentations et versions avant changement :
- [Supabase — checklist production](https://supabase.com/docs/guides/deployment/going-into-prod).
- [Supabase — sauvegardes](https://supabase.com/docs/guides/platform/backups).
- [Changelog Supabase](https://supabase.com/changelog.md), notamment ruptures de versions CLI/Flutter : vérifier les versions réellement épinglées, aucune montée majeure implicite.

## 8. Première séquence de travail

1. M00 : réconcilier les documents avec la nouvelle cible et l'autopublication effective ; établir un registre unique des critères bloquants à partir de #146, #37, #91 et des travaux récents.
2. M01/M03 : matrice du périmètre et statut de recette sur la version candidate, y compris la saison fictive #142 ; distinguer données injectées et scénario réellement joué.
3. M04 : fonctions privilégiées, tests JWT A/B et protection des mots de passe ; produire les correctifs ciblés et prérequis de configuration.
4. M09 : preuve de restauration complète et plan de charge hébergée avec coûts/autorisation nécessaires.
5. M02 : diagnostic récupération e-mail et cohérence URLs réelles ; premiers petits lots de corrections issus de M01/M03/M04.
6. M07/M06 : identité éditeur, périmètre de données, conditions pilotes et règle de gratuité ; traiter les décisions nécessaires par petits QCM.
7. M05/M08 : parcours de découverte et kit des 2–3 clubs, prêts à tester quand les portes s'ouvrent.

## 9. Prompts prêts à copier dans chaque discussion

Chaque bloc est autonome. Les fichiers de rapport sont des destinations proposées à créer dans une branche, pas des preuves qu'ils existent déjà.

### Fil 00 — Chef de projet

```text
Tu travailles sur Petit Filet, mission 00, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Tu es le chef de projet transversal. Adopte le calendrier et les critères du plan directeur, réconcilie les références anciennes sans effacer leur historique, centralise les preuves des neuf missions et maintiens un seul tableau de priorités.
Commence par contrôler l'état actuel de main/CI/livraison, #146, #37, #91, #142 et les PR ouvertes ; traite les affirmations anciennes comme non confirmées jusqu'à preuve. Réserve les fichiers centraux à M00 pour éviter les conflits.
Pour chaque fonction promise et chaque jalon, exige un responsable, une date cible, un critère mesurable, des preuves, les risques et la prochaine action. Organise les neuf missions existantes, limite les travaux concurrents sur le même fichier et refuse une conclusion fondée uniquement sur du code présent ou une CI verte.
Surveille séparément fonctionnalité, sécurité, capacité/exploitation, conformité et préparation pilote/commerciale. Mets les gros changements et nouvelles fonctionnalités en arbitrage pour préserver mars/avril 2027.
Ne prétends pas pouvoir réveiller les autres conversations ni travailler en continu. Utilise les comptes rendus GitHub lorsqu'ils sont disponibles. Les nouvelles automatisations nécessitent une demande distincte de programmation.
Rapport au propriétaire en français simple : ce qui est prouvé, les principaux blocages, les trois actions prioritaires et seulement les décisions nécessaires sous forme A/B/C. Présente un GO/NO-GO motivé pour pilote, diffusion large et payant.
Premier livrable : état de départ réconcilié et backlog des blocages, par PR documentaire sans fusion.
```

### Fil 01 — Inventaire et contrat fonctionnel

```text
Tu travailles sur Petit Filet, mission 01, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : établir le contrat complet de la version qui sera montrée aux clubs.
Inventorie chaque écran, bouton, formulaire, réglage, automatisme, notification et règle temporelle, avec son parcours admin/joueur et son caractère obligatoire ou optionnel par club. Couvre notamment comptes/invitations, clubs, saisons, calendrier et agendas, disponibilités/absences, effectifs/invités/liste d'attente, compositions et simulation, vidéos/maillots, Live coach/remplacements/compte rendu, pronostics, votes, classements, statistiques, badges et archives. Ajoute tout autre module effectivement trouvé.
Pour chaque élément : identifiant stable, comportement attendu, source code/serveur, configuration club, critère d'acceptation, test lié, état réellement observé, anomalie et dépendances.
Réconcilie les audits existants ; ne repars pas d'une page blanche et ne retire pas de fonctionnalité sans décision. Sépare les défauts à corriger des idées futures. Propose le gel du périmètre des pilotes.
Livrable : docs/missions/M01_CONTRAT_FONCTIONNEL.md et backlog référencé. Commence par identifier les contradictions entre code, documentation et application.
Fin vérifiable : tout le périmètre promis est recensé, chaque élément a un critère et un responsable, les inconnues sont explicites.
Coordination : Donne les critères à M02 et M03 ; signale les données et règles sensibles à M04/M07.
```

### Fil 02 — Développement et parcours multiclub

```text
Tu travailles sur Petit Filet, mission 02, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : terminer et corriger l'application par petits lots vérifiables, selon M01 et les priorités M00.
Commence par les parcours bloquants : création/configuration d'un club, invitation et validation des membres, rôles, accès administrateur, changement de club, connexion/déconnexion et récupération autonome du mot de passe par e-mail. Vérifie d'abord les comptes existants et leurs éventuels identifiants/e-mails synthétiques ; ne suppose pas que chaque joueur possède déjà une adresse joignable. Prépare le parcours d'ajout/vérification d'une vraie adresse, les redirections et la délivrabilité avec M09, sans envoyer de messages réels sans autorisation.
Corrige ensuite toutes les fonctions promises, les modules désactivables réellement contrôlés côté serveur, les saisons, médias et interactions concurrentes. Préserve l'historique des clubs et migrations appliquées.
Prépare l'abonnement 100 €/équipe/an dès souscription et l'exception pilote selon le contrat M06/M07 ; aucun débit ni basculement payant implicite. Les prestataires, règles HT/TTC et configurations restent soumis aux décisions nécessaires.
Livrable : docs/missions/M02_IMPLEMENTATION.md, PR ciblées liées aux critères M01, démonstrations et résultats des contrôles exigés par AGENTS.md. Évite une réécriture globale sans besoin prouvé.
Fin vérifiable : chaque correctif respecte un critère, passe les contrôles concernés et est retesté sur la version candidate ; indique séparément ce qui n'est pas déployé.
Coordination : Reçoit les exigences M01/M05/M06/M07 et les anomalies M03/M04/M08 ; fait valider ses PR par M03/M04.
```

### Fil 03 — Recette fonctionnelle et non-régression

```text
Tu travailles sur Petit Filet, mission 03, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : vérifier réellement toutes les fonctionnalités promises et empêcher les faux résultats positifs.
Pars de la matrice M01 et de QA_REGISTRE_VALIDATION.md. Définis des scénarios reproductibles par rôle et club, données d'entrée, attendu/obtenu, environnement, version, preuve et gravité. Marque « non exécuté » tout parcours non joué ; ne déduis pas un succès de la présence d'un test.
Couvre une saison complète de bout en bout, puis fin/changement/archives de saison ; clubs vides et fournis, erreurs et reprises réseau, double clic/retry, deux administrateurs concurrents, mauvais ordre d'actions, limites de dates et heure Europe/Paris, scores atypiques et modules désactivés. Teste inscription, invitation, récupération de mot de passe, notifications, agendas, exports et suppression avec M07. Vérifie la cohérence compositions → Live → statistiques → badges/classements et absence de doublons.
Prévois de vrais essais iPhone/Safari/PWA, Android/Chrome et ordinateur, installation/mise à jour/hors-ligne, liens d'e-mails, petits écrans et permissions notifications. N'invente pas les résultats d'un appareil inaccessible : documente l'essai à faire et le rôle humain nécessaire.
Livrable : docs/missions/M03_RECETTE.md, matrice de couverture, journal des défauts et retests.
Fin vérifiable : 100 % des fonctionnalités du périmètre ont un résultat de recette explicite ; tous les parcours essentiels réussissent sur la version candidate et aucune anomalie bloquante n'est ouverte.
Coordination : Reçoit M01 et les PR M02 ; transmet les défauts à leur propriétaire et les preuves à M00/M08. M09 possède la charge ; M04 possède l'audit de sécurité.
```

### Fil 04 — Sécurité et séparation des clubs

```text
Tu travailles sur Petit Filet, mission 04, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : produire un dossier de sécurité démontrable avant les premiers vrais clubs, puis avant l'ouverture élargie.
Établis un modèle de menaces et teste les autorisations avec de vrais JWT dans un environnement isolé autorisé : anonyme, joueur, admin, autre club, membre retiré/suspendu, club suspendu, opérateur. Examine lectures ET écritures REST/RPC, RLS, vues, SECURITY DEFINER, Edge Functions, Storage/URLs publiques ou signées, Realtime, invitations, exports, flux d'agenda et notifications.
Les 165 avertissements authenticated_security_definer_function_executable ne sont pas 165 failles prouvées : examine propriétaires, privilèges, garde d'identité/club/rôle, search_path et politiques effectives. Justifie les exceptions ; ne révoque pas globalement des RPC utilisées. Vérifie la PR #145 et le réglage de mots de passe compromis signalé par Supabase.
Audite également élévation de rôle, accès opérateur, sessions/révocation, récupération de compte, abus/rate limits, secrets et historique du dépôt public, dépendances et CI. Publie uniquement des constats assainis ; ne révèle jamais d'identités ou d'extraits sensibles.
Livrable : docs/missions/M04_SECURITE.md, cas d'attaque reproductibles, qualification gravité/exploitabilité, correctifs et retests. Prépare le périmètre d'une revue de sécurité indépendante avant la diffusion large, sans commander de prestation.
Fin vérifiable : aucune vulnérabilité critique/élevée non traitée, aucun accès interclub non autorisé dans la matrice testée, exceptions justifiées et limites explicites.
Coordination : Transmet corrections à M02, tests à M03, obligations incident/confidentialité à M07, durcissement exploitation à M09.
```

### Fil 05 — Expérience utilisateur, identité et accessibilité

```text
Tu travailles sur Petit Filet, mission 05, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : rendre Petit Filet cohérent et utilisable sans formation lourde en conservant son identité actuelle.
Inspecte le parcours d'un dirigeant puis d'un joueur qui découvre l'application : création du club, invitations, premier match, composition, Live et consultation des résultats. Identifie ambiguïtés, actions cachées, états vides, erreurs incompréhensibles et obstacles sur téléphone.
Vérifie lisibilité, contrastes, taille des actions, navigation clavier/lecteur d'écran, préférence de réduction des animations, poids des médias et efficacité sur réseau faible. Distingue améliorations d'usage et éventuelles obligations d'accessibilité à qualifier avec M07.
Conserve la direction graphique existante ; aucune nouvelle refonte ni changement de nom sans besoin et décision. Vérifie les personnalisations par club, absence de références visibles héritées d'AS Grinta, cohérence maillots/vidéos/historiques et animations.
Livrable : docs/missions/M05_UX.md, parcours annotés et spécifications de correctifs priorisées ; guide de démonstration simple. Fournis à M07 un inventaire de provenance des polices, logos, photos, sons, badges et animations, avec preuves ou incertitudes.
Fin vérifiable : un dirigeant et un joueur peuvent réaliser les tâches clés selon un protocole observé ; défauts critiques d'usage corrigés et retestés avec M03/M08.
Coordination : Donne les spécifications à M02, les critères à M03, les ressources à M07 et la démonstration à M08/M06.
```

### Fil 06 — Modèle économique et lancement

```text
Tu travailles sur Petit Filet, mission 06, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : préparer une offre durable à 100 €/équipe/an dès souscription, avec essai gratuit réservé aux pilotes.
Prépare une proposition claire : clients cibles, interlocuteur signataire/payeur, unité club/équipes/joueurs, fonctions incluses, limites et support. Les anciens essais de 30 jours et le prix de 10 €/joueur/an présents dans des documents ne sont pas les nouvelles décisions du propriétaire.
Précise le début de la souscription annuelle, la facturation par équipe, les échéances et renouvellements, l'essai pilote, l'acceptation du payant, les rappels, l'absence de paiement, l'export et la sortie. Ne remets pas l'année gratuite générale dans l'offre ; pas de paiement automatique surprise. Qualifie HT/TTC avec M07 et les informations réelles de l'éditeur.
Chiffre, avec sources à jour, coûts, recettes et financement pour 10, 100, 300 et 500 équipes, et indique séparément les clubs physiques correspondants selon les hypothèses : infrastructure, médias/egress, e-mails, support, juridique et acquisition. Isole les coûts des pilotes gratuits ; distingue coût estimé et capacité prouvée, hypothèses, marge et budget maximal.
Prépare l'offre pilote, fiche de présentation, démonstration, FAQ, liste de canaux et suivi des prospects pour juillet–septembre 2027. Aucun envoi ni engagement de tarif non validé. Évalue paiement/facturation/annulation/échec/remboursement avec M07/M02, en tenant compte de la nature réelle des associations clientes.
Livrable : docs/missions/M06_OFFRE_LANCEMENT.md, offre proposée, budget et décisions A/B/C.
Fin vérifiable : calendrier et règle de gratuité sans ambiguïté, modèle financé, prix/conditions approuvés avant d'engager les clubs et plan d'acquisition mesurable.
Coordination : M07 qualifie les contrats ; M09 chiffre l'exploitation ; M02 implémente ; M08 teste les supports sans contacter de clubs sans ordre explicite.
```

### Fil 07 — Juridique, RGPD et droits

```text
Tu travailles sur Petit Filet, mission 07, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : constituer un dossier de conformité France/UE traçable, dès les pilotes gratuits, puis avant l'abonnement payant.
Reprends l'audit et les modèles existants, vérifie le code et les parcours réels. Utilise des sources officielles actuelles, cite les dates et distingue obligation applicable, cas conditionnel, recommandation et point à arbitrer. La gratuité ne dispense pas de protéger les données ni de prévoir les conditions d'utilisation.
Qualifie par finalité les rôles du club et de l'éditeur, bases légales, contrats article 28 si applicables, prestataires et transferts, conservation, information et exercice des droits, suppression/export de compte et fin de club, backups, registre, analyse de nécessité d'une AIPD/DPO et procédure de violation.
Examine spécifiquement mineurs, portraits/vidéos/droit à l'image, motifs d'absence pouvant révéler la santé, pronostics et récompenses éventuelles, cookies/SDK et prospection. Audite licences/droits des médias, sons, badges, code et contributions IA, nom/marque/domaines et hébergement. Ne suppose pas qu'une association est toujours un client professionnel.
Prépare mentions légales, CGU, contrat pilote, confidentialité, clauses de sous-traitance et conditions de souscription payante par équipe et de sortie de l'essai pilote selon les décisions M06. Liste les informations éditeur à fournir, les questions d'accessibilité, statut, TVA/facturation à valider et les éventuelles obligations de plateforme selon les usages réels.
Livrable : docs/missions/M07_CONFORMITE.md, registre des obligations avec preuves et textes à faire relire par un juriste/avocat compétent ; fiscalité/statut à vérifier avec l'expert adapté. N'annonce ni conformité absolue ni certification juridique.
Fin vérifiable : aucune obligation bloquante identifiée sans traitement avant collecte réelle ; documents cohérents avec l'application, tests des droits et revue professionnelle préparée puis tracée.
Coordination : M01 précise les traitements ; M02 implémente ; M03 prouve les droits utilisateurs ; M04/M09 apportent les mesures ; M05 apporte la provenance ; M06 précise offre et clients.
```

### Fil 08 — Clubs pilotes et retours terrain

```text
Tu travailles sur Petit Filet, mission 08, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : préparer puis suivre 2–3 clubs pilotes qui démarrent en mars/avril 2027 et utilisent Petit Filet pendant trois mois gratuits, avec une équipe adulte de football à 11 par club.
L'issue #146 mentionne encore 3–5 clubs et 2–4 semaines : réconcilie cette ancienne proposition avec le nouveau calendrier du propriétaire ; ne crée pas un second programme concurrent.
Prépare des profils de clubs complémentaires, un référent par club, recrutement et accord pilote, règles de gratuité validées avec M06/M07, installation PWA et guides admin/joueur, première saison/premier match, canal support et formulaire de retour. Ne contacte ni n'invite personne sans autorisation explicite.
Définis le suivi : démarrage accompagné, point après le premier match, bilans réguliers et bilan final. Mesure activation, clubs réellement actifs, parcours réussis sans aide, temps de support, défauts et gravité, satisfaction et intention de payer ; propose des seuils à M00 avant le début.
Distingue bug, incompréhension, paramétrage et nouvelle idée. Chaque retour devient une entrée liée à un ticket, décision, correction et retest avec le club concerné. Prépare les preuves d'usage et témoignages uniquement avec accord des personnes.
Livrable : docs/missions/M08_PILOTES.md, kit pilote, grille de suivi anonymisée et bilan consolidé.
Fin vérifiable : 2–3 clubs ont utilisé le produit en conditions réelles pendant la période convenue, les parcours essentiels sont documentés, les blocages sont corrigés/retestés et la décision d'élargir repose sur des mesures.
Coordination : Ne lance qu'après GO M00/M03/M04/M07/M09 ; remonte défauts à M02/M03, friction à M05 et demandes produit à M01/M00.
```

### Fil 09 — Capacité, sauvegardes et exploitation

```text
Tu travailles sur Petit Filet, mission 09, sous la coordination du fil 00.
Dépôt commercial : samihchaa-wq/Application-football-. Supabase commercial : jvxkhgdopslctpcjrhzw.
Lis AGENTS.md, docs/HANDOFF.md, docs/CHANTIER.md et docs/PLAN_DIRECTEUR_2027_2028.md. Si le dernier fichier n'est pas encore sur main, ouvre la PR #147 (https://github.com/samihchaa-wq/Application-football-/pull/147) et lis-le sur sa branche.
Calendrier validé : 2–3 clubs pilotes à partir de mars/avril 2027, trois mois gratuits chacun, une seule équipe adulte de football à 11 par club ; corrections puis prospection pendant 2–3 mois à l'été 2027. Décision 4A : disponibilités sans justification libre ; préparer retrait de la saisie et du contrat de nouvelle écriture, sans détruire l'historique. Décision commerciale actualisée le 16/11 : 100 €/équipe/an dès souscription, essai gratuit réservé aux pilotes avec conditions à préciser. Aucune année gratuite généralisée. Distingue club physique, équipe facturée et espace technique ; aucun engagement financier implicite.
Réutilise les travaux existants. Vérifie les faits actuels : un document ancien, une PR fusionnée et une CI verte ne prouvent pas tous les parcours ni l'état déployé.
Ne modifie jamais AS Grinta original ni Carte soirée. Le dépôt commercial est public : aucun secret ni donnée personnelle dans les livrables.
Avance sur les lectures, tests isolés et branches/PR commerciales utiles. Aucune fusion vers main, écriture distante, migration commerciale, publication, dépense ou contact externe sans autorisation applicable : une fusion déclenche actuellement une chaîne automatique de sauvegarde, migrations et déploiement. Ne suppose pas une autorisation nouvelle à partir du seul intitulé de la mission.
Travaille dans ton périmètre ; ne réécris pas les fichiers centraux de M00. Remonte les dépendances au fil 00 par ton rapport GitHub.
Rapport obligatoire : mission, date, environnement et SHA, travail livré, preuves/liens, tests réellement exécutés, ce qui reste non vérifié, blocages, prochaine action et éventuelle décision A/B/C. Distingue documenté, développé, testé en CI, testé réellement, déployé. Ne déclare jamais « certifié à 100 % ».
Ta mission : prouver une capacité adaptée à plusieurs centaines de clubs et une exploitation récupérable.
Établis d'abord le modèle de charge : clubs inscrits et actifs, membres/club, matchs simultanés le week-end, appareils actifs, rafales de connexion, abonnements Realtime, appels API, writes Live/pronostics, médias et notifications. Propose une cible nominale 300 clubs et un palier 500, avec hypothèses explicites et budget ; ce sont des objectifs, pas une capacité déjà certifiée.
Le test local historique 200 clubs × 30 comptes et 50 clients pgbench est utile mais ne représente pas 6 000 téléphones simultanés. Réutilise-le puis prépare des essais bout en bout isolés : Auth, REST/RPC, Realtime, Edge, Storage, e-mails/push, pics, durée prolongée, panne/reprise, idempotence et intégrité interclubs. Mesure latences p95/p99, débit, erreurs, CPU/mémoire/verrous/connexions, quotas et coût ; indique le périmètre réellement mesuré.
Reprends #91 : une sauvegarde verte n'est pas une restauration prouvée. Prépare et, seulement avec autorisation appropriée, réalise la restauration DB/Auth/Storage depuis une vraie archive vers une infrastructure isolée, contrôle les octets et les droits. Propose objectifs RPO/RTO, sauvegardes privées chiffrées, rétention et exercice périodique.
Vérifie préproduction séparée, monitoring/alertes, support, incident/rollback, cohérence versions app/schéma, chaîne automatique sur main, configuration URL/redirects e-mails, fournisseur SMTP et quotas. La config production.json contient encore PUBLIC_APP_URL sur GitHub Pages malgré des publications Cloudflare : retrace les substitutions effectives avant de conclure à un défaut.
Livrable : docs/missions/M09_CAPACITE_EXPLOITATION.md, rapport de capacité reproductible, limites et dimensionnement/coûts par palier, procédures d'exploitation.
Fin vérifiable : seuils convenus atteints sur infrastructure représentative, données intègres, reprise complète mesurée et alertes effectivement testées ; aucune promesse de centaines de clubs fondée seulement sur un seed.
Coordination : M03 teste les parcours ; M04 vérifie les droits ; M07 encadre données/prestataires ; M06 utilise les coûts ; M00 décide des paliers d'ouverture.
```

## 10. Décisions à préparer, sans bloquer le travail autorisé

| Sujet | Proposition de travail | Quand la décision est indispensable |
| --- | --- | --- |
| Essai pilote uniquement | Validé : trois mois gratuits, une équipe adulte à 11 par club ; fixer dates et sortie ; pas d'année gratuite générale | Avant contrat pilote |
| Prix annuel par équipe | 100 €/équipe/an dès souscription ; préciser HT/TTC et modalités avec M06/M07 | Avant offre commerciale |
| Périmètre et minimisation | Validé : pilotes adultes à 11 ; aucune justification libre d'absence à saisir. Extension aux mineurs à qualifier séparément | Vérifier l'application effective avant pilotes |
| Éditeur/statut et contrats | Informations réelles du propriétaire, revue adaptée | Avant exploitation/engagements concernés |
| Infrastructure et revue indépendante | Devis/estimations reliés à la charge, enveloppe maximale | Avant toute dépense ou création payante |
| Passage en production et admission | GO fondé sur preuves, puis autorisation explicite | À chaque ouverture/élargissement significatif |

Le plan est un outil de pilotage : aucun abonnement, envoi, dépense, migration, publication ni modification de données n'a été réalisé pour le produire.

## 11. Premier contrôle M00 — 16 novembre 2026

[Tableau de départ et prochaines actions](missions/M00_PILOTAGE_20261116.md).
Les neuf consignes ont été transmises par le propriétaire ; cela ne prouve ni neuf livraisons ni neuf exécutions continues. Le premier correctif M02 est en PR #148, en attente de correction/validation CI et recette. Aucun GO de fusion n'est donné.

## 12. Arbitrages du propriétaire — 16 novembre 2026 (QCM 1A, 2A, 3A, 4A)

Décisions reçues directement dans le fil 00, sans condition supplémentaire à redemander :

| ID | Décision validée | Effet attendu |
| --- | --- | --- |
| 1A | Trois mois gratuits par équipe pilote | M06/M07/M08 fixent les dates individuelles et la sortie de l'essai. Pas de débit automatique présumé. |
| 2A | Adultes, football à 11 pour les premiers pilotes | M01/M02/M07/M08 cadrent comptes, guides et admission ; aucune promesse de prise en charge des mineurs ou du foot à 5/8 à ce jalon. |
| 3A | Une équipe par club physique pendant les pilotes | M01/M02/M04/M08 testent ce périmètre. Ce choix ne tranche pas l'architecture ni l'offre multiéquipe de la version ultérieure. |
| 4A | Indisponibilité sans justification libre | M01/M02/M03/M07 préparent et vérifient la suppression de la saisie libre et le refus de nouvelles justifications côté serveur, y compris appels directs. |

M02 prépare le lot produit 4A avec identification de tous les champs, formulaires, modèles, RPC et journaux concernés. M03 teste les saisies nouvelles et les anciennes versions ; M04 vérifie les accès ; M07 définit le traitement des copies et données déjà enregistrées. **Aucune suppression destructive d'historique ni purge distante implicite** : inventorier, proposer le traitement proportionné, puis appliquer dans le cadre des autorisations appropriées.
M05 aligne les libellés et états d'absence ; M06/M07/M08 réconcilient leurs options devenues obsolètes avec ces décisions. Les missions lisent cette section lors de leur prochaine exécution ; aucun réveil automatique des conversations.
La mise en œuvre applicative n'est pas déclarée faite par cette note. Les seuils GO/NO-GO, tests, revue et règles de mise en production restent applicables. Aucune dépense, invitation, fusion ou modification distante effectuée pour consigner ces décisions.
