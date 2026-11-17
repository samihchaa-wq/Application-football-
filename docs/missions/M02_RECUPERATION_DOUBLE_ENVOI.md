# M02 — Récupération : éviter les doubles soumissions

Rapport du 17 novembre 2026. Base commerciale : `0e5fa39e87f17ba466ef187ae44495a65a67de9c`. Référence M01 : A08–A10 / REC-A09 ; F2-09.

Le bouton de récupération est désactivé pendant la demande mais le champ conserve son callback clavier. Plusieurs pressions sur Entrée peuvent donc relancer le repository sans attendre la première réponse. Correction : garde synchrone dans le handler pour les états en cours, réussi ou démonté. Une erreur libère toujours la possibilité de réessayer. Aucun changement de la réponse générique pour les adresses inconnues ni des limites serveur.

Deux tests de widget ajoutés avec repository simulé : réponse retardée et soumissions répétées, y compris callback ancien après succès ; échec puis nouvelle tentative réussie. Ils n'envoient aucun e-mail.

État : développé, tests écrits, exécution non confirmée. La tentative Flutter locale n'a pas fourni de résultat exploitable ; à la reprise, le service d'exécution local est indisponible. Aucun succès de test, d'analyse ou de build revendiqué. CI Flutter complète (format, analyse stricte, tests, couverture, build Web) à obtenir sur le SHA de la PR avant validation. M03 : rejouer le clavier sur téléphone et navigateur ; la délivrabilité réelle reste un sujet distinct avec M09.

La PR #148 d'invitation est déjà fusionnée ; ce lot part de main intégrant le poste de contrôle #163 et conserve son accès gestionnaire. Aucun changement SQL, API, configuration, envoi réel, fusion, publication ou donnée de production ; AS Grinta original et Carte soirée intacts. Prochaine action : corriger tout échec CI puis transmettre la preuve M03/M00. Aucun arbitrage propriétaire requis pour ce correctif.
