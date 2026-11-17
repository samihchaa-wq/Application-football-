# M01 — Lot 02 : commandes des comptes et contrat #160

**17 novembre 2026, Europe/Paris. Mission en cours, pas de GO pilote.**
Code relu : `0e5fa39e87f17ba466ef187ae44495a65a67de9c` (main récupéré). Copie locale commerciale isolée, aucune écriture distante de données. Ce lot complète [le contrat initial](M01_CONTRAT_FONCTIONNEL.md), intégré via [#155](https://github.com/samihchaa-wq/Application-football-/pull/155). Les faits de cet ancien rapport restent datés de leur baseline.

## Décisions actualisées, sans rouvrir les choix acquis

Le plan central impose **équipes autonomes uniquement**, 100 €/équipe/an et pilotes adultes à 11 pendant trois mois gratuits. Les noms techniques clubs/club_id ne justifient ni renommage automatique ni hiérarchie multiéquipe. L'ancien point M01-EC02 demandant le choix d'architecture est résolu par cette décision ; il reste à vérifier son application et le vocabulaire visible.

[L'issue #160](https://github.com/samihchaa-wq/Application-football-/issues/160) fixe email réel et naissance obligatoires pour les nouvelles inscriptions, confirmation par lien puis approbation admin si nécessaire, conservation de la connexion par identifiant. Le pilote admet les adultes ; ne pas inventer une politique définitive mineurs. Les anciennes références A08 « email facultatif » et A11 « déclaration 15 ans » décrivent le code historique, **plus le contrat cible**.

## Constats reproductibles dans le code

| Réf. | Constat statique | Effet pour le contrat | Propriétaire |
|---|---|---|---|
| M01-AUTH-01 | auth_register_page.dart:335 affiche email facultatif ; _submit accepte vide ; Edge register-account/index.ts accepte aussi l'absence | Exigence nouvelle non implémentée dans cette baseline ; ne pas la compter testée | M02, rattachement #160 |
| M01-AUTH-02 | consent_fields conserve choix d'âge ; aucun résultat birth/naissance dans lib/features/auth et register-account | Date de naissance et admission adulte nécessitent encore la chaîne UI/serveur et confidentialité | M02/M04/M07 #160 |
| M01-AUTH-03 | register-account:336–363 laisse réussir le compte si envoi de confirmation échoue ; garde routeur relue sans étape contact confirmé | Définir état d'attente/correction/renvoi et blocage serveur des nouveaux non-confirmés ; pas uniquement changer le formulaire | M02/M04 #160 |
| M01-AUTH-04 | ForgotPasswordDialog._send ne vérifie pas _sending à l'entrée ; bouton désactivé, mais onSubmitted appelle directement _send | Risque de requêtes dupliquées par Entrée pendant envoi ; à reproduire en widget avant de conclure à plusieurs mails réellement envoyés | M02/M03 |
| M01-AUTH-05 | Libellés créer club/code du club et secours admin du club encore présents | Adapter texte en équipe ; préserver noms techniques pour compatibilité | M02/M05 |
| M01-AUTH-06 | /control possède garde serveur distincte et branche routeur dédiée ; tests platform_auth_redirect présents | Ajouter console à l'inventaire initial de 48 routes, devenu historique ; admin équipe ≠ gestionnaire | M01/M03/M04 |

Aucune absence de garde complète côté base commerciale n'est déduite de la seule lecture du routeur. Les schémas, fonctions installées et configuration SMTP **n'ont pas été réinterrogés dans ce lot**. Aucun dysfonctionnement de production reproduit. Le correctif invitation #148 et la console #163 sont présents dans le code courant ; ne pas les redévelopper depuis l'ancien cahier.

## 30 commandes et scénarios à transmettre

ID stable : M01-<sous-ID>, parent Axx conservé. Scénario M03 : REC-<sous-ID>. **Chaque ligne est NON EXÉCUTÉE en client réel dans ce lot** ; les fichiers de tests indiqués sont des points de départ de couverture, pas une preuve qu'ils couvrent tout le critère ni qu'ils ont été lancés ici.

Acteurs : visiteur/nouveau compte pour inscription et récupération ; titulaire pour profil/session ; admin pour admission ; opérateur pour console. **Socle obligatoire**, non désactivable par module d'équipe. Réalisation M02 ; recette M03 ; contrôles autorisations M04 ; données/acceptations M07 ; envoi M09. Chaque écriture doit aussi être vérifiée par appel direct, mauvais rôle/autre équipe, perte réseau et double soumission.

Sources courtes : pages .dart sous lib/features/auth/presentation sauf auth_redirect.dart sous lib/app/router, club_repository.dart sous lib/features/club/data, auth_repository.dart/account_email_repository.dart sous lib/features/auth/data, account_local_data.dart sous lib/core/storage. Tests à retrouver dans test/ selon architecture ; username/consent tests sous supabase/functions/register-account ; test_auth_password_contract.py sous tool/tests.

| Sous-ID (parent conservé) | Parcours | Commande/contrôle | Critère d'acceptation | Chemin / symbole | Test lié ou manquant |
|---|---|---|---|---|---|
| A01-01 | Créer/rejoindre | Choix du mode | Champs adaptés ; bascule conserve les saisies utiles sans créer d’équipe. | auth_register_page.dart / RegisterMode | auth_register_page_test.dart |
| A02-01 | Invitation | Ouvrir lien avec code | Code prérempli après démarrage à froid et restauration de session ; aucune adhésion implicite. | auth_redirect.dart / needsClub | auth_redirect_test.dart |
| A02-02 | Invitation | Saisir code | Espaces/tirets/minuscules normalisés ; code invalide refusé client et serveur. | club_repository.dart / normalizeInviteCode | choose_club_page_test.dart |
| A01-02 | Création | Nom et nom court | Nom 2–80, nom court facultatif ≤12 ; messages utilisent équipe ; erreurs sans perte des autres champs. | auth_register_page.dart / _submit | auth_register_page_test.dart |
| A04-01 | Identité | Prénom/nom | Validation cohérente UI/serveur pour espaces, accents, apostrophes et limites ; pas de création partielle. | auth_register_page.dart / _submit ; register-account/index.ts | auth_register_page_test.dart |
| A05-01 | Identifiant | Homonymes concurrents | Deux inscriptions obtiennent des identifiants distincts ; aucun compte existant renommé/écrasé. | register-account/index.ts / reserveUsername | username_test.ts |
| A08-01 | Email | Email obligatoire | Vide, malformé et omission API refusés ; aucune confusion adresse technique/contact réel. | auth_register_page.dart / _submit ; register-account/index.ts | auth_register_page_test.dart |
| A11-01 | Naissance | Date obligatoire | Date réelle, non future, obligatoire UI/API ; calcul âge serveur et admission pilote à 18 ans. | consent_fields.dart ; register-account/index.ts ; #160 | NOUVEAU : dates/bornes/29 février |
| A11-02 | Vie privée | Confidentialité naissance | Date complète absente des profils de coéquipiers, notifications et exports de tiers ; titulaire conserve ses droits. | #160 ; personal_data_repository.dart | NOUVEAU : matrice REST/RPC/exports M04 |
| A10-01 | Mot de passe | Saisie et visibilité | 12–72 caractères selon politique commune ; confirmation identique ; masquer/afficher ne soumet pas. | auth_register_page.dart ; password_policy.dart | test_auth_password_contract.py |
| A11-03 | Conditions | Acceptations et liens | Textes accessibles avant inscription ; acceptations versionnées ; création équipe exige contrat adapté, sans accord précoché. | consent_fields.dart ; register-account/index.ts | consent_test.ts |
| A01-03 | Soumission | Créer compte | Double clic/Entrée/retry réseau sans doublon ; erreur serveur affichée, possibilité de reprendre. | auth_register_page.dart / _submit | NOUVEAU : timeout après écriture |
| A08-02 | Attente email | Inscription réussie | Accusé consulte ton email ; envoi échoué ne signifie pas confirmation ; compte en attente récupérable. | register-account/index.ts / emailConfirmationSent | NOUVEAU : fournisseur indisponible |
| A08-03 | Accès | Compte non confirmé | Gardes métier serveur et routeur ; seuls confirmation/correction/renvoi/aide/légal/déconnexion accessibles. | auth_redirect.dart ; #160 | NOUVEAU : matrice compte non confirmé |
| A08-04 | Confirmation | Lien reçu | Usage unique, expiration, jeton haché ; confirmation sur autre appareil sans donner rôle admin/opérateur. | confirm_email_page.dart / _confirm ; account-email | NOUVEAU : vrai lien sur boîte test autorisée |
| A08-05 | Confirmation | Lien invalide et Réessayer | Absent/expiré/rejoué : message utile ; panne réseau distincte ; nouvelle tentative sans mutation de rôle. | confirm_email_page.dart / _ConfirmState | NOUVEAU : états confirmation |
| A08-06 | Adresse | Correction et renvoi | Adresse erronée corrigeable ; quotas anti-abus et renvoi idempotent ; nouvelle adresse à confirmer. | account_email_repository.dart / requestConfirmation ; #160 | NOUVEAU : renvois concurrents |
| A04-02 | Admission | Attente admin | Email confirmé ne suffit pas à activer un membre soumis à approbation ; accès après les deux conditions. | auth_redirect.dart / isPending ; #160 | auth_redirect_test.dart |
| A06-01 | Connexion | Identifiant et mot de passe | Champs vides refusés ; mot de passe masquable ; Entrée équivaut au bouton ; erreur lisible. | auth_sign_in_page.dart / _submit | auth_sign_in_error_banner_test.dart |
| A06-02 | Session | Chargement/reprise | Erreur temporaire profil ne devient pas fausse déconnexion ; route attendue conservée ; retry explicite. | auth_redirect.dart / profileUnavailable | auth_initial_session_startup_test.dart |
| A06-03 | Navigation | Destination après login | Retour local autorisé ; URL externe/protocole relatif rejetés ; aucune escalade par redirect. | auth_redirect.dart / _safeLocalRedirect | exhaustive_auth_router_state_space_test.dart |
| A09-01 | Récupération | Ouvrir mot de passe oublié | Dialogue, email valide, Annuler ; explication secours admin pour anciens comptes sans contact confirmé. | auth_sign_in_page.dart / ForgotPasswordDialog | forgot_password_dialog_test.dart |
| A09-02 | Récupération | Envoyer lien | Réponse générique identique connu/inconnu ; clic et Entrée pendant envoi ne multiplient pas les requêtes. | auth_sign_in_page.dart / _send ; requestPasswordReset | NOUVEAU : double Entrée pendant envoi |
| A09-03 | Récupération | Lien expiré/rejoué | Sans session/jeton valide, aucun changement autorisé ; lien ancien et nouveau lien testés. | forced_password_change_page.dart / _verifyRecoveryToken | auth_redirect_test.dart + nouveau cas jeton |
| A10-02 | Changement | Nouveau mot de passe | Même politique UI/Edge ; confirmation égale ; succès permet reconnexion ; drapeau obligatoire levé après succès. | forced_password_change_page.dart / _submit ; auth_repository.dart | test_auth_password_contract.py + recette réelle |
| A15-01 | Session | Déconnexion | Désabonnement push et purge des données locales ; second compte ne lit pas premier ; erreurs traitées. | account_local_data.dart ; sign_out_confirmation.dart | sign_out_push_unsubscribe_test.dart |
| A16-01 | Statut | Pending/suspendu | Accès API et routes directes refusés selon statut ; support/légal disponibles ; aucun contournement client. | auth_redirect.dart ; auth_state.dart | auth_redirect_test.dart + matrice M04 |
| A17-01 | Rattachement | Equipe autonome | Un espace = une équipe ; conserver clubs/club_id techniques ; ne pas construire une hiérarchie club/équipes. | PLAN_DIRECTEUR_2027_2028.md ; club_repository.dart | NOUVEAU : équipe A/B |
| A16-02 | Gestionnaire | Route control | Compte sans équipe peut atteindre garde opérateur ; admin équipe n’est pas opérateur ; changement mdp exigé si nécessaire. | auth_redirect.dart / consoleRequested | platform_auth_redirect_test.dart |
| A08-07 | Compatibilité | Comptes existants | Pas de suspension globale/renommage ; parcours explicite pour ajouter email/date, sans écraser historiques. | #160 ; account_email_repository.dart | NOUVEAU : ancien compte avec données |

## Vérifications réellement exécutées

Dans la copie de cette baseline, sans réseau ni base :
- python3 tool/check_auth_password_contract.py : PASS, politique Flutter/Edge cohérente 12–72.
- python3 -m unittest discover -s tool/tests -p test_auth_password_contract.py : **6 tests PASS**.
- python3 supabase/tests/edge/verify_edge_security_contract.py : PASS.

Ces tests contrôlent des garde-fous statiques ; ils ne valident ni inscription, ni jeton, ni SMTP, ni délivrabilité. Aucun Flutter/widget, Deno, navigateur, iPhone/Android, JWT HTTP ou parcours réel exécuté ici. Aucun mail ou push déclenché, aucun compte créé/supprimé, aucune naissance réelle collectée ; aucune modification AS Grinta original/Carte soirée, main, schéma ou déploiement. Documentation seulement.

## Transmission et prochaine action

M02 : reprendre #160 et les IDs A08-01 à A08-07/A11-01 ; séparer contact confirmé, admission et Auth technique ; préserver anciens comptes. Pour M01-AUTH-04, reproduire d'abord le double Entrée avant correctif.
M03 : ajouter attendu/obtenu, version, données fictives, capture/log et retest par REC ; ne pas transformer les six tests Python en trente parcours réussis.
M04 : vérifier le refus des accès métier non confirmés côté serveur et la confidentialité date/email.
M07/M09 : cadrer naissance/admission adulte et conditions d'envoi de test ; configuration fournisseur et vraie réception restent à prouver.

Lot suivant M01 : commandes du cycle match → effectif → composition → Live → résultat, et résolution du contrat temporel Étoile demandé par M03. Le reste des 164 unités et l'exhaustivité boutons restent ouverts.
