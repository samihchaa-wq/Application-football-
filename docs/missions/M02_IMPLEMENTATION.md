# M02 — Développement et parcours multiclub

Rapport du 16 novembre 2026 (Europe/Paris). Départ : `5f404e70f70b4e99d754f7064b567d027d66fe03`, dépôt commercial uniquement. Plan : PR #147, prompt Fil 02. Aucun changement AS Grinta original ou Carte soirée.

## Lot 02-01 — Invitation d’un compte connecté sans club

**État : développé, recette Flutter et revue M03/M04 à obtenir ; non déployé.**

Critères issus de M01 : F2-00/F2-09, parcours T01–T05 du cahier `docs/CAHIER_DES_CHARGES_FIL_02.md` (#25). Ce lot ne prétend pas valider intégralement ces scénarios serveur.

Défaut constaté par lecture du chemin exécuté : `/auth/register?code=ABCDEFGH` est redirigé vers `/auth/choose-club` quand `needsClub` est vrai ; le code est perdu. Après un démarrage à froid, la même perte se produit depuis `/auth/loading?redirect=...`.

Correction : conserver uniquement le code de l’invitation locale, le transmettre au formulaire et le normaliser. Conserver aussi cette destination pendant le chargement initial. Une nouvelle invitation sur la page déjà ouverte met à jour le champ. Aucun rattachement automatique : consentement, validation et RPC existante restent nécessaires. Un membre déjà rattaché ne change pas de club via ce correctif.

Tests ajoutés : redirection directe et après chargement ; démarrage à froid sans boucle ; rejet des destinations externes ou étrangères au parcours ; formulaire prérempli sans envoi automatique ; actualisation d’une invitation sur une page montée. Fichiers : `test/app/router/auth_redirect_test.dart`, `test/features/auth/presentation/choose_club_page_test.dart`.

## Vérifications et limites

- `git diff --check` : réussi.
- Formatage Dart exécuté avec le SDK disponible, puis retrait des modifications de présentation étrangères au lot. Le contrôle de format de la CI reste requis avec la version du projet.
- Exécution Flutter ciblée tentée : l’outil Flutter doit se reconstruire et résoudre ses dépendances ; aucun résultat de test obtenu dans la fenêtre locale. Analyse et build Web non validés localement. Les tests ajoutés ne sont donc pas déclarés réussis.
- Exiger sur le SHA de la PR : formatage, `flutter analyze --fatal-warnings --fatal-infos`, suite Flutter et build Web définis dans `.github/workflows/flutter_ci.yml`. Aucune fusion avec contrôles incomplets ou rouges.
- Aucun essai navigateur/téléphone ni création de compte, rattachement, envoi d’e-mail ou migration distante réalisés.

## Comptes et récupération — constat commercial en lecture seule

Requêtes agrégées sur Supabase commercial `jvxkhgdopslctpcjrhzw` : 42 comptes Auth / 42 profils sur 2 clubs ; 42 identités techniques en domaine non joignable `.local`/`.invalid` ; 0 adresse de contact confirmée, 0 confirmation en attente ; 42 profils actifs sans adresse de récupération. Aucun identifiant individuel ni adresse n’est publié.

Le code existant possède déjà `AccountEmailRepository`, `account-email`, confirmation et récupération. `profiles.contact_email` est distinct de l’adresse Auth technique : ne pas remplacer aveuglément les identifiants ni supposer que l’adresse de contact devient une adresse de connexion. L’envoi réel et sa configuration ne sont pas prouvés par la présence du code.

M09 : vérifier fournisseur d’envoi, configuration, URL publique et délivrabilité avant essai autorisé. La publication Cloudflare remplace PUBLIC_APP_URL dans son workflow ; la valeur GitHub Pages du JSON seul ne prouve pas une erreur déployée. Références documentaires consultées : https://supabase.com/changelog.md ; https://supabase.com/docs/guides/auth/passwords ; aucune mise à niveau implicite du SDK.

## Coordination et prochain lot

- M01 : reprise de #25 et demande de rattachement aux nouveaux identifiants du contrat publiée dans #147. Nouveau contrat M01 non reçu au moment de cette préparation ; ne pas inventer de critères acceptés.
- M03 : exécuter les tests ajoutés sur la PR puis rejouer invitation avec session restaurée, consentement et validation admin en environnement isolé.
- M04 : vérifier le refus serveur des codes expirés, membres en attente et accès interclubs ; aucune modification RLS/SQL dans ce lot.
- M05 : prise en charge UX visible sur #147, absence d’édition concurrente annoncée sur comptes/invitations.
- M06/M07/M00 : dernière correction tarifaire lue dans #147 : **100 €/équipe/an**, pilotes gratuits sous conditions à préciser ; elle remplace l’année gratuite générale et les commentaires antérieurs à 100 €/club. Aucune implémentation de paiement sans contrat validé.

Le modèle actuel lie un profil à un `club_id` ; aucune prise en charge de plusieurs équipes par club ou de basculement multiadhésion n’est démontrée. Prochain lot : cartographier espace équipe autonome versus plusieurs équipes par club, droits/comptes/saisons et abonnement, puis faire arbitrer M00 avant migration. Ne pas promettre la prise en charge des catégories à 5/8 sur ce modèle football à 11.

Décision propriétaire immédiate : aucune requise pour relire ce correctif. Paiement, migration, déploiement et architecture multiéquipe restent hors de ce lot.
