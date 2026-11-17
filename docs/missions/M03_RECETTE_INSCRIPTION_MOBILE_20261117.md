# M03 — Recette d'inscription mobile, version commerciale publiée

**Relevé : 17 novembre 2026.** Référence de production : `main` `4ac75c14d077bc2bf8bc6e3278023d0db8948932`, version Cloudflare `0.3.3+97-4ac75c14d077`.
Cible : [Petit Filet](https://petit-filet.pages.dev/) et projet Supabase commercial `jvxkhgdopslctpcjrhzw`. **Aucune mutation de production**, aucun compte ni e-mail créé, aucune donnée personnelle ni donnée d'AS Grinta original consultée.

## Distinction des preuves

- **DÉPLOYÉ AUTOMATIQUEMENT** : publication Cloudflare #44070483288 réussie, contrôle de version du site et en-têtes HTTP inclus dans le job. Ce n'est pas un test de navigation complète sur téléphone.
- **CI DU SHA PUBLIÉ** : Flutter #44067385631 et Supabase SQL/RLS #44067385971 verts. Les tests existants ne certifient pas la nouvelle règle #160.
- **CODE CLIENT** : `lib/features/auth/presentation/auth_register_page.dart` accepte encore l'e-mail vide et propose une déclaration « 15 ans ou plus ». L'interface est toujours libellée « club », alors que le produit ne gère que des équipes autonomes.
- **CODE SERVEUR PUBLIÉ** : le code actif de l'Edge Function `register-account` (version 25), récupéré via Supabase, est **identique** au fichier `supabase/functions/register-account/index.ts` de `main`. Il autorise l'e-mail manquant, n'accepte pas de date de naissance et permet que la création d'un compte réussisse malgré un échec de courriel de confirmation. Un créateur d'équipe obtient actuellement `status: active` avant confirmation de contact.
- **SCHÉMA COMMERCIAL** : `public.profiles` comprend notamment `age_confirmation` et `contact_email_confirmed_at`. Une date de naissance séparée n'a pas été constatée dans les colonnes concernées inspectées. Un champ `email` technique non nul n'est **pas** une preuve d'e-mail réel confirmé (le login utilise un domaine technique).
- **NAVIGATEUR/TÉLÉPHONE RÉEL** : **NON EXÉCUTÉ**. Le site n'a pas pu être ouvert depuis l'outil Web disponible dans cette session ; ne pas inventer de capture, clic, courrier reçu ou connexion gestionnaire.

## Scénarios de la première tranche

| Référence | Action et critère | Preuve / état |
| --- | --- | --- |
| REC-MOB-01 | Ouvrir lien d'invitation, code normalisé puis soumission à largeur logique de téléphone 390 × 844 | Nouveau test widget fictif ajouté dans cette PR ; verdict à relever de la CI de branche |
| REC-MOB-02 | Créer une équipe depuis un petit écran avec consentements et contrat | Nouveau test widget fictif ajouté ; **libellé actuel « club »** signalé |
| REC-160-01 | Refuser e-mail vide, malformé et absent dans JSON | **NON CONFORME dans client et serveur**, obligation #160 |
| REC-160-02 | Demander date de naissance valide, refuser moins de 18 ans sur les pilotes | **NON IMPLÉMENTÉ** ; déclaration d'âge existante ne suffit pas |
| REC-160-03 | E-mail non confirmé n'ouvre pas les parcours de gestion, y compris administrateur fondateur | **NON DÉMONTRÉ / garde insuffisante à ce stade** : vérifier SQL/RPC et Edge avant correctif |
| REC-160-04 | Confirmation, échec SMTP, renvoi/correction, expiration, lien consommé | **NON TESTÉ sur vraie boîte e-mail** |
| REC-SESSION-01 | Connexion identifiant + mot de passe ; erreur lisible ; entrée clavier | Tests widget existants dans le dépôt ; **pas une connexion live** |
| REC-RESET-01 | Récupération par e-mail et refus du double envoi clavier | Test widget corrigé via PR #165 ; vraie réception et reset **NON TESTÉS** |
| REC-PLATFORM-01 | Un admin d'équipe ne devient pas gestionnaire de plateforme | Tests de redirection et d'isolation déjà en CI ; **login réel gestionnaire NON VÉRIFIÉ** |
| REC-MOB-03 | iPhone Safari / Android Chrome : clavier, zoom, scroll, retour et latence | **NON TESTÉ PHYSIQUEMENT** |

## Décision technique et ordre de correction

**NO-GO d'inscription pilote adulte tant que #160 n'est pas résolue.** Une simple saisie obligatoire dans Flutter ne suffit pas : l'API Edge reste accessible directement. Développer d'abord une validation unique de l'e-mail et de la naissance **côté Edge**, un stockage privé/minimal de la naissance, et une interdiction serveur des actions métier tant que l'e-mail n'est pas confirmé pour les *nouveaux* comptes (sans verrouiller les comptes historiques). Ajouter ensuite le champ date mobile et les états d'attente/correction de contact, en maintenant connexion par identifiant. L'approbation admin du joueur invité reste une condition distincte.

**Test de bascule obligatoire :** équipes fictives A/B, administrateur fondateur, membre en attente, utilisateur non confirmé, utilisateur ancien, lien de confirmation expiré, double requête et échec de messagerie. Aucun véritable compte ni données réelles d'AS Grinta. Les habilitations doivent être vérifiées sur **RPC/Storage/Edge**, pas uniquement sur le routeur.

**Niveau de preuve attendu ensuite :** SHA exact, appareil/OS/navigateur, e-mail de test autorisé, rôle, attendu/observé, captures expurgées, incident associé. Les tests widgets CI sont un jalon de non-régression et ne remplacent pas cette recette.

**P0 parallèles conservés :** #37 audit sécurité avant vrais utilisateurs et #91 exercice réel de restauration DB + Storage dans un environnement isolé. Aucune fusion automatique vers `main` depuis la présente PR QA.
