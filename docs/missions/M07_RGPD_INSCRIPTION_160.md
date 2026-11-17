# M07 — Revue juridique et RGPD du parcours d'inscription #160
**17 novembre 2026 — revue documentaire, avis final professionnel et recette restant à obtenir.**
Périmètre : nouvelles inscriptions Petit Filet, équipes autonomes, pilotes adultes à 11. Complète M07_CONFORMITE.md et M07_KIT_CONTRACTUEL_EQUIPES.md ; n'altère aucun texte actif ni aucune version d'acceptation.

## 1. Verdict et preuves
**Validation conditionnelle du cadrage seulement ; pas de GO de conformité du parcours déployé.**
L'e-mail de service obligatoire est défendable si sa nécessité est documentée. Le contrôle de majorité pilote est un choix produit. La conservation systématique d'une naissance complète après ce contrôle n'est pas justifiée par les éléments examinés.

Sources techniques lues sur main le 17/11 :
- `supabase/functions/register-account/index.ts`, blob `b7afccf66776625c69c19bca3ca0fc3ced520ef3` : ligne 162 e-mail omissible, 276 Auth technique confirmée, 336–362 confirmation présentée comme facultative et échec intercepté, 369 créateur actif.
- `supabase/functions/register-account/account_email.ts`, blob `373e7cce61f8e0a8409523fec1621aa1e54333b1` : message annonçant lien valable 24 h et à usage unique. **Ce texte ne prouve pas expiration et consommation serveur.**
- `lib/features/auth/presentation/consent_fields.dart`, blob `f152a39b977f6286f4eb763a8fba3babea602ab0` : déclaration d'âge historique et acceptation CGU/confidentialité groupées.
- `lib/features/legal/domain/legal_documents.dart`, blob `beb2a2e35b5b15008ece727b099d66a00e3979c8` : e-mail facultatif, déclaration d'âge, mineurs sous 15 ans, durées globales, prestataires et coordonnées à réviser.
- [#160](https://github.com/samihchaa-wq/Application-football-/issues/160) et commentaires M03/M00 : observation publiée à SHA `4ac75c14d077bc2bf8bc6e3278023d0db8948932`, confirmation v25 identique déclarée par M00/M03 ; **pas une nouvelle observation de production de M07**.

Les anciens HANDOFF/CHANTIER restent partiellement historiques ; leurs règles de gouvernance ont été relues. Pas de nouvelle inspection Supabase, de création de compte, de mail envoyé ni de parcours physique par M07. Une erreur de chemin initiale vers `_shared/account_email.ts` a été corrigée via l'import réel ; aucune conclusion tirée du fichier absent.

## 2. Obligations établies, choix produit et qualifications
| Sujet | Qualification | Conclusion |
| --- | --- | --- |
| Finalité, base, minimisation, sécurité, conservation et information | Obligations RGPD art. 5/6/12/13/25/32 | S'appliquent aux inscriptions gratuites comme payantes [S1–S4] |
| E-mail réel obligatoire | Choix de service soumis à nécessité | Justifier confirmation, récupération et communications indispensables ; aucune obligation RGPD générale d'en imposer un à chaque joueur |
| Lien de confirmation | Mesure de sécurité/qualité et exigence produit | Moyen pertinent ; pas une obligation générale de double opt-in RGPD pour ouvrir un compte |
| Pilotes réservés aux majeurs | Décision produit | Seuil 18 ans au jour d'entrée à appliquer serveur ; pas une majorité RGPD universelle |
| Date de naissance complète | Collecte à justifier, non imposée par RGPD | L'âge exact au seuil peut être calculé ; cela ne justifie pas le stockage durable |
| Consentement aux traitements indispensables | Pas à imposer par défaut | Choisir une base adaptée ; ne pas solliciter un faux consentement révocable pour une condition nécessaire |
| Protection mineurs | Obligations conditionnelles | Art. 8/LIL 45 seulement pour consentement aux services en ligne dans leur champ ; contrat et image se traitent séparément [S5–S7] |

### Finalités et bases proposées à documenter
1. Gestion du compte de service et récupération : art. 6(1)(b) seulement si relation avec le membre et nécessité objective établies ; le contrat éditeur/organisation seul ne suffit pas pour toutes données du joueur.
2. Vérification de majorité liée à l'admission pilote : intérêt légitime proposé, après nécessité et mise en balance écrites (pilote adulte, risques/attentes, alternative moins intrusive). Ne pas invoquer une obligation légale générale ni faire passer la seule inscription dans les CGU pour une nécessité contractuelle.
3. Prévention des abus et protection du service : intérêt légitime distinct, accès et journaux proportionnés.
4. Organisation sportive : responsable réel à identifier, base propre à ses finalités ; éditeur sous-traitant lorsqu'il agit sur instructions.
5. Marketing, publication facultative et autres réutilisations : qualification distincte, jamais déduite de l'e-mail confirmé.

Ce sont des propositions de qualification, pas plusieurs bases interchangeables à afficher indistinctement. Le registre doit fixer une base par finalité avant lancement. [S3/S8]

## 3. Décision de minimisation proposée à M02/M04
**Cible recommandée pour pilotes :** date saisie pour calcul serveur, aucun stockage durable de la date complète si aucune autre finalité nécessaire n'est établie. Après validation, ne garder que décision d'admission, seuil/politique appliqués, date du contrôle et origine « déclaration utilisateur ». Un simple attribut majoritaire n'est pas une preuve d'identité ; pas de garantie « âge vérifié » trompeuse.

Si M02 doit temporairement stocker la date pour une inscription en attente : stockage privé, accès borné et purge à l'admission ou à l'abandon. M00 doit approuver cette adaptation de conservation ; la saisie obligatoire décidée n'est pas supprimée implicitement.
Alternative maintien date complète : documenter finalité supplémentaire, nécessité contre l'attribut, durée, accès, impact et avis compétent avant de valider. « Peut servir un jour », anniversaire décoratif ou curiosité admin ne suffisent pas. [S2]

Ne pas demander systématiquement pièce d'identité ni biométrie. Le moyen de vérification doit être proportionné au risque ; le simple formulaire reste contournable. Un refus mineur ne doit pas conduire à conserver inutilement son dossier ni à recruter le mineur par un mail commercial.

## 4. Conservation : politique proposée, pas configuration appliquée
| Donnée/état | Proposition à approuver | Vérification technique M03/M04/M09 |
| --- | --- | --- |
| Date complète pour contrôle initial | Transitoire ; suppression après décision si aucun autre besoin nécessaire | Absente profil partagé/Auth user_metadata/JWT/log/analytics/erreur, copies nettoyées |
| Statut âge et admission | Pendant compte/pilote ; révision à sortie, preuve minimale séparée si litige justifié | Source déclarative et politique tracées, pas de date reconstruite |
| E-mail confirmé | Pendant service nécessaire ; changement = nouvelle confirmation | Ancienne adresse et demandes en attente purgées selon nécessité ; récupération cohérente |
| Inscription non confirmée | 30 jours depuis création proposés ; renvoi seul ne repousse pas indéfiniment | Nettoyage planifié indépendant du trafic, Auth/profil/jetons et invitation liés |
| Compte confirmé en attente admin | Revue à 30 jours ; décision/refus et suppression selon procédure annoncée | Ne pas laisser dossiers en attente sans borne ; délai distinct explicite si besoin |
| Jeton confirmation | Expiration 24 h déjà annoncée à vérifier ; invalidation à usage/renvoi/changement | Secret brut jamais en DB/journaux ; purge après consommation/expiration sans délai inutile |
| Traces anti-abus et envoi | Durée courte justifiée séparément, avant de fixer un nombre | Pas de corps de mail, naissance, mot de passe ou jeton dans logs |
| Preuve CGU | Archivage privé minimal pour défense de droits si justifié | Pas de naissance complète conservée avec la preuve par défaut ; 5 ans non automatiquement requis pour tout |
| Sauvegardes | Durée propre justifiée et bornée par M09 | Accès limité, rotation et non-réintroduction des données effacées en restauration |

Les durées proposées ne sont pas des délais imposés par la loi. Ni « tant que le compte existe » pour toute donnée, ni « 6 mois après fin » uniformes ne remplacent une analyse. Les engagements 7–90 j logs/90 j backups/5 ans preuve des textes actuels ne sont pas démontrés ici. [S4]

## 5. Visibilité, droits et suppression
Par défaut, aucun e-mail ni naissance complète aux coéquipiers, administrateurs ordinaires, classements ou notifications. L'admin a besoin du statut d'admission, pas de la date ; accès exceptionnel à des informations de contact seulement si finalité/habilitation démontrée. Exports collectifs et RPC doivent respecter cette règle.
Le membre peut accéder à ses données effectivement conservées (adresse, confirmations, statuts et origine, décisions, dates utiles) et demander rectification. L'export personnel ne remplace pas une réponse complète à l'accès.
Accès/rectification/effacement/limitation/opposition selon conditions ; portabilité dans le champ art. 20, pas toutes données automatiquement. Réponse en principe sous un mois ; extension de deux mois possible selon conditions avec information motivée dans le premier mois. Contrôle d'identité proportionné, pas de pièce automatique [S9].
Suppression compte : vérifier Auth/profil, invitations, tokens, mails en attente, stockage, copies de noms historiques et appareils ; révocation des liens et sessions pertinente. Distinguer suppression, anonymisation effective et conservation légale/contentieuse justifiée. Informer des exceptions ; ne pas promettre disparition immédiate absolue des backups [S10].
L'accès aux demandes et textes reste possible pendant attente/refus d'admission, sans imposer accès sportif ou approbation admin. Demande sur données de l'équipe transmise au responsable, aide du sous-traitant ; finalités propres de l'éditeur traitées directement.

## 6. Ajustements documentaires exacts pour M02
### CGU : clauses à remplacer/ajouter
« L'accès aux pilotes est réservé aux personnes âgées d'au moins 18 ans à la date d'admission. Cette restriction concerne les pilotes ; elle ne définit pas une règle générale d'accès futur des mineurs.
À l'inscription, vous renseignez une adresse e-mail que vous contrôlez et votre date de naissance pour le contrôle d'admission. Vous confirmez votre adresse via le lien reçu. La confirmation de cette adresse ne prouve ni votre identité ni votre âge et ne confère aucun rôle d'administration.
Avant confirmation, seules les fonctions de confirmation/correction/renvoi, aide, accès aux textes, exercice des droits et déconnexion sont ouvertes. L'éventuelle approbation d'un administrateur d'équipe reste indépendante. Une erreur d'envoi ne vaut pas confirmation.
Vous pouvez corriger votre adresse et demander un nouveau lien ; les limites de renvoi sont présentées clairement pour protéger les comptes. La procédure de correction des informations d'âge est accessible auprès de [contact].
Les conditions propres aux anciens comptes sont communiquées séparément ; cette évolution ne supprime pas automatiquement leurs identifiants ou données. »

Contrat d'usage à accepter : « J'accepte les conditions d'utilisation ». Politique : « Comment vos données sont utilisées » avec lien visible avant envoi ; pas d'acceptation de confidentialité présentée comme consentement à tous traitements.
CGU administrateurs :
« L'administrateur intervient dans les limites de son habilitation pour l'équipe. Il informe les personnes et relaie leurs demandes selon la répartition des responsabilités. Il ne publie ni exporte les données privées sans nécessité et autorisation appropriées. Une approbation d'équipe ne remplace pas les conditions d'admission ni, le cas échéant, une autorisation parentale. »
Pas de clause transférant toute responsabilité RGPD à l'admin.

### Politique de confidentialité : contenu à compléter avant collecte
| Section | Informations nécessaires pour #160 |
| --- | --- |
| Qui décide | Identité/contact de chaque responsable par finalité, DPO si désigné ; organisation réelle/personne derrière équipe ; éditeur pour fins propres |
| Données et caractère obligatoire | E-mail, saisie date/attribut retenu, statut confirmation/admission et preuves ; finalités champ par champ, conséquence du refus ; ne pas annoncer date stockée si seulement transitoire |
| Pourquoi et base | Base précise par finalité ; intérêts légitimes identifiés ; contrat seulement nécessaire, pas « toute donnée car CGU acceptées » |
| Accès et transferts | Catégories destinataires, accès support autorisé, SMTP/hébergement réels ; transferts/garanties et moyen d'en obtenir copie lorsque requis |
| Combien de temps | Durées/critères par état selon tableau validé, purge et limites sauvegarde cohérentes |
| Droits | Contacts et modalités, droits applicables, retrait si consentement, réclamation CNIL ; pas de validation admin nécessaire pour réclamer |
| Décisions automatiques | Décrire contrôle d'âge et moyen de corriger/contester ; qualifier art. 22 si effet juridique ou similaire significatif, ne pas présumer sa présence ou absence |
| Sources indirectes | Invitations/imports admin : sources et catégories, information art. 14 lorsqu'applicable |
| Mises à jour | Date/version, texte durable et réacceptation contractuelle si modification pertinente ; ne pas confondre information RGPD et nouveau consentement |

Micro-notice avant envoi, **à adapter après choix de conservation** :
« Votre e-mail est nécessaire pour confirmer votre adresse, récupérer votre compte et recevoir les messages utiles au service. Votre date de naissance sert au contrôle de majorité du pilote. [Décrire traitement transitoire ou durée justifiée retenue.] Ces informations ne sont pas affichées aux autres membres. Le pilote est réservé aux majeurs. Responsables, bases, destinataires, durées et droits : [lien vers notice complétée]. »

Modifier les passages actuels : e-mail « si tu en ajoutes », déclaration d'âge, rôle de l'éditeur automatiquement responsable de toute Auth, « obligation de preuve » sans texte légal déterminé, autorisation générale des mineurs de moins de 15 ans. Vérifier aussi les listes fournisseurs et garanties de transferts ; ne pas recopier les assertions existantes sans preuve.

### Consentements et vérification d'e-mail
Pas de case obligatoire marketing/image pour ouvrir le compte. Les finalités facultatives fondées sur consentement exigent choix spécifique, libre, informé, preuve et retrait simple. Un lien de service ne vaut pas permission publicitaire ; mail de confirmation sans promotion. La création seule du compte ne donne pas automatiquement l'exception marketing « client existant » [S11].
La conservation de la version CGU acceptée et de la notice remise sert la preuve ; elle ne transforme pas l'information en consentement global. Le navigateur autorisant push ne règle pas toutes les bases RGPD.

## 7. Mineurs hors pilote et administrateurs : ne pas généraliser
**Hors pilote, aucun GO mineurs donné.** Préparer une politique par public et fonctionnalité avec juriste.
- Le seuil français de 15 ans s'applique au consentement dans le champ art. 8 RGPD/LIL 45. En dessous, accord conjoint enfant/titulaire(s) de l'autorité parentale et efforts raisonnables adaptés ; pas simple case « parent d'accord » universellement suffisante.
- À 15–17 ans, capacité contractuelle/droit à l'image et intérêt de l'enfant restent à analyser. L'avis CNIL relatif à certains actes courants n'est pas une majorité générale ; sa page indique être en cours de mise à jour [S7].
- Une équipe adulte n'empêche pas qu'un invité mineur figure dans un média ou un import. Réduire/traiter ces cas ; pilotes adultes ne sont pas une exonération de droits des tiers.
- Administrateur d'équipe n'est pas automatiquement représentant légal de l'enfant ni responsable de traitement personnel. Identifier celui qui décide réellement des finalités ; l'admin peut agir sous son autorité. La structure équipe technique ne tranche pas ce rôle [S8].
- L'éditeur reste tenu à ses obligations propres ; art. 28 si traitement pour compte d'autrui, art. 26 si responsabilité conjointe établie. Ne pas prétendre que la case « pouvoir d'engager » vérifie ce pouvoir.

## 8. Transmission et critères de levée
| ID | Mission | Critère attendu |
| --- | --- | --- |
| J160-01 | M02/M07/M00 | Base/nécessité documentées, décision transitoire vs maintien naissance complète et notice assortie |
| J160-02 | M02/M04 | État non confirmé bloqué serveur pour créateur ET joueur ; chemins register/claim/invitation, anciennes API, Auth technique distingués |
| J160-03 | M04/M03 | JWT/REST/RPC/Realtime/Storage/exports : aucune naissance ou adresse indue intra/interéquipe ; métadonnées utilisateur non autorité d'admission |
| J160-04 | M02/M03/M09 | Email erroné, SMTP en panne, renvoi, changement, token expiré/réutilisé et autre appareil testés ; aucun rôle accordé au clic |
| J160-05 | M02/M03 | Dates invalides/futures, limite 18 ans, 29 février, date d'admission et fuseau définis ; correction et refus proportionné |
| J160-06 | M02/M09/M03 | Purge planifiée des attentes/tokens et données sensibles dans logs ; sauvegarde/restauration respecte suppression |
| J160-07 | M03/M07 | Accès/rectification/effacement après attente/refus, tiers protégés, anciens comptes conservés ; preuves synthétiques uniquement |
| J160-08 | M02/M07 | CGU/notice publiées ensemble avec comportement, versions client/serveur archivées ; pas de texte anticipant un contrôle absent |

Les exigences techniques sont transmises sur #160 pour M02/M04 ; leur publication ne réveille pas les autres conversations. Cette PR n'implémente pas le serveur. Les durées et clauses proposées attendent décisions et vérification avant activation.

## 9. Points à faire valider par un professionnel
Qualification responsable/éditeur/organisateur, bases exactes et mise en balance ; maintien de la date complète ; capacité/consentement mineurs hors pilotes ; qualification art. 22 du refus automatique selon effets ; fournisseur/transferts ; règles de preuve et contentieux. Le RGPD n'impose pas universellement un avocat pour ces démarches : la revue professionnelle est un jalon du projet, pas une formalité légale générale inventée.

**Exécuté :** lecture statique et comparaison exigences/textes, sources officielles relues, contrôle documentaire et relecture distante. **Non exécuté :** application, CI de code, téléphone, SQL, inspection de données, purge, mail réel, audit fournisseur, avis juridique professionnel.
Aucune conformité absolue, signature ou autorisation de lancement. Aucun frais, contact externe, donnée personnelle ou production modifiée ; AS Grinta original et Carte soirée exclus.

## Sources officielles relues le 17 novembre 2026
- S1 [CNIL — principes RGPD, art. 5–8](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2).
- S2 [CNIL — minimisation](https://www.cnil.fr/fr/minimiser-les-donnees-collectees).
- S3 [CNIL — nécessité contractuelle](https://www.cnil.fr/fr/les-bases-legales/contrat).
- S4 [CNIL — conservation, 02/04/2026](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees).
- S5 [Légifrance — article 45 LIL](https://www.legifrance.gouv.fr/loda/article_lc/LEGIARTI000037823135).
- S6 [CNIL — consentement des moins de 15 ans](https://www.cnil.fr/fr/recommandation-4-rechercher-le-consentement-dun-parent-pour-les-mineurs-de-moins-de-15-ans) ; [vérification proportionnée](https://www.cnil.fr/fr/recommandation-7-verifier-lage-de-lenfant-et-laccord-des-parents-dans-le-respect-de-sa-vie-privee).
- S7 [CNIL — capacité des mineurs, page en cours de mise à jour](https://www.cnil.fr/fr/recommandation-1-encadrer-la-capacite-dagir-des-mineurs-en-ligne).
- S8 [CNIL — qualification des rôles, 06/06/2025](https://www.cnil.fr/fr/rgpd-comment-bien-identifier-son-role).
- S9 [CNIL — droits, art. 12–22](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3) ; [délai de réponse](https://www.cnil.fr/fr/cnil-direct/question/exercice-des-droits-informatique-et-libertes-dans-quel-delai-doit-me-repondre) ; [justification d'identité](https://www.cnil.fr/fr/cnil-direct/question/exercice-de-mes-droits-informatique-et-libertes-dois-je-fournir-obligatoirement).
- S10 [CNIL — effacement](https://www.cnil.fr/fr/comprendre-mes-droits/le-droit-leffacement-supprimer-vos-donnees-en-ligne) ; [préparer les droits, sauvegardes](https://www.cnil.fr/fr/preparer-lexercice-des-droits-des-personnes).
- S11 [CNIL — consentement](https://www.cnil.fr/fr/les-bases-legales/consentement) ; [prospection électronique, 10/06/2026](https://www.cnil.fr/fr/la-prospection-commerciale-par-courrier-electronique-sms-mms-et-automate-dappel).
