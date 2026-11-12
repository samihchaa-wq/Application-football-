# Mettre l'appli en ligne sur sa propre adresse

Notice pas à pas pour Samih. Environ 1 h 30 en tout, en plusieurs fois.
Coût : le nom de domaine seulement (~10 €/an). Cloudflare et Brevo sont
gratuits à ce niveau d'usage.

**Pourquoi quitter GitHub Pages ?** Les conditions de GitHub interdisent d'y
héberger un service commercial. GitHub Pages reste utilisable pour les tests
à clubs fictifs, mais l'appli vendue doit être ailleurs. Cloudflare Pages est
gratuit, autorise l'usage commercial et fonctionne même si le dépôt passe en
privé.

**Adresse recommandée** : `app.<domaine>` pour l'appli (ex. `app.lucarne.fr`),
et le domaine seul (`lucarne.fr`) gardé pour la future page de présentation.

---

## Étape 1 : acheter le nom de domaine

À faire **seulement après** la recherche de marque INPI sur le nom (voir le
dossier juridique).

1. Chez OVHcloud ou Gandi pour un `.fr` (Cloudflare ne vend pas les `.fr`).
2. Ne prends aucune option payante (hébergement, e-mail, « DNS Anycast ») :
   seul le domaine est utile.

## Étape 2 : créer le compte Cloudflare et y confier le domaine

1. Crée un compte sur cloudflare.com (offre Free). Active la double
   authentification (Profil > Authentification).
2. « Ajouter un domaine » > tape ton domaine > offre **Free**.
3. Cloudflare affiche **deux serveurs de noms** (ex. `ada.ns.cloudflare.com`).
   Chez OVH/Gandi, remplace les serveurs DNS du domaine par ces deux-là.
   La prise en compte prend de quelques minutes à 24 h ; Cloudflare envoie un
   e-mail quand c'est actif.

## Étape 3 : donner à GitHub le droit de publier

1. Cloudflare > Profil > **Jetons d'API** > Créer un jeton > « Modèle
   personnalisé ».
   - Nom : `GitHub publication Lucarne`
   - Autorisation : **Compte > Cloudflare Pages > Modifier** (rien d'autre)
   - Expiration : dans un an
   Copie le jeton affiché (il n'est montré qu'une fois).
2. Cloudflare > page d'accueil du compte > copie l'**ID de compte** (colonne
   de droite, « Account ID »).
3. GitHub > dépôt Application-football- > Settings > Secrets and variables >
   Actions :
   - Onglet **Secrets** > New repository secret :
     `CLOUDFLARE_API_TOKEN` = le jeton ; `CLOUDFLARE_ACCOUNT_ID` = l'ID de compte.
   - Onglet **Variables** > New repository variable :
     `CLOUDFLARE_PAGES_PROJECT` = `lucarne` ;
     `COMMERCIAL_APP_URL` = `https://lucarne.pages.dev/` (provisoire, voir
     étape 5).

## Étape 4 : première publication

1. GitHub > Actions > « Publier l'appli commerciale sur Cloudflare Pages » >
   Run workflow > Run.
2. Si l'étape finale « Vérifier le site en ligne » échoue, regarde dans
   Cloudflare > Workers & Pages > `lucarne` l'adresse réellement attribuée
   (Cloudflare ajoute parfois un suffixe, ex. `lucarne-4xz.pages.dev`), mets-la
   dans `COMMERCIAL_APP_URL` (avec `https://` et le `/` final) et relance.

## Étape 5 : relier ta propre adresse

1. Cloudflare > Workers & Pages > `lucarne` > **Domaines personnalisés** >
   Configurer > tape `app.<domaine>` > Activer. Cloudflare crée lui-même
   l'enregistrement DNS et le certificat https (quelques minutes).
2. GitHub > Variables : change `COMMERCIAL_APP_URL` en `https://app.<domaine>/`.
3. Relance le workflow de publication (étape 4), puis le workflow
   « Supabase commercial : mise en route » en cochant seulement « functions » :
   les liens des notifications et de l'agenda pointeront vers la nouvelle
   adresse.

## Étape 6 : régler la connexion dans Supabase

Supabase > projet `application-football` > Authentication > **URL
Configuration** :

- Site URL : `https://app.<domaine>/`
- Redirect URLs : ajoute `https://app.<domaine>/**` (garde l'adresse GitHub
  Pages tant que des tests y tournent).

Sans ce réglage, les liens « mot de passe oublié » et la connexion Facebook
renvoient vers une mauvaise adresse.

## Étape 7 : envoyer les e-mails depuis ton domaine (Brevo)

Le service d'e-mails intégré à Supabase n'envoie que quelques messages par
heure : inutilisable avec un vrai club.

1. Crée un compte sur brevo.com (offre gratuite, 300 e-mails/jour, société
   française).
2. Brevo > Expéditeurs, domaines > **Domaines** > Ajouter `<domaine>` >
   choisis « Cloudflare » : Brevo ajoute lui-même les enregistrements DNS
   (sinon, copie-les dans Cloudflare > DNS). Attends la coche verte.
3. Brevo > Expéditeurs > ajoute `contact@<domaine>`.
4. Brevo > SMTP et API > onglet **SMTP** > Générer une clé SMTP. Note
   l'identifiant SMTP (une adresse en `@smtp-brevo.com`) et la clé.
5. Supabase > Authentication > **Emails** > SMTP Settings > Activer :
   - Hôte `smtp-relay.brevo.com`, port `587`
   - Identifiant = l'identifiant SMTP Brevo, mot de passe = la clé SMTP
   - Adresse d'expéditeur `contact@<domaine>`, nom d'expéditeur `Lucarne`
6. Supabase > Authentication > **Rate Limits** : passe la limite d'e-mails à
   100 par heure.
7. Test : sur l'appli, « mot de passe oublié » avec ta propre adresse.

## Étape 8 (plus tard) : connexion Facebook

À faire quand l'adresse définitive marche. developers.facebook.com > Créer une
app > « Authentifier les utilisateurs avec Facebook Login ». Facebook demande
une URL de politique de confidentialité et de suppression des données : celles
de l'appli. Copie l'identifiant et la clé secrète de l'app dans Supabase >
Authentication > Providers > Facebook, et colle dans Facebook l'adresse de
retour affichée par Supabase. Claude peut te guider écran par écran le moment
venu.

---

## Ce qui est vérifié automatiquement à chaque publication

- Refus de publier un commit absent de `main`, une base AS Grinta ou Carte
  soirée, une clé secrète, ou une adresse GitHub Pages / AS Grinta.
- Politique de sécurité du navigateur (CSP) réglée sur la base commerciale.
- En-têtes de sécurité (https obligatoire, pas d'affichage dans un cadre
  d'un autre site).
- Après publication : la nouvelle version est bien visible à l'adresse
  publique, et le https est actif.

## Pas encore testé

Le workflow n'a jamais tourné : il faut le compte Cloudflare pour l'essayer.
La première publication peut révéler un réglage à corriger.
