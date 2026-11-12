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
   - Aucune variable à créer à ce stade : le projet s'appelle `lucarne` par
     défaut et l'adresse `*.pages.dev` attribuée par Cloudflare est lue
     automatiquement (variables facultatives `CLOUDFLARE_PAGES_PROJECT` et
     `COMMERCIAL_APP_URL`, voir étape 5).

## Étape 4 : première publication

1. GitHub > Actions > « Publier l'appli commerciale sur Cloudflare Pages » >
   Run workflow > Run.
2. Le journal affiche « Adresse publique utilisée : https://….pages.dev/ »
   (Cloudflare ajoute parfois un suffixe si `lucarne` est déjà pris).

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

L'appli envoie elle-même les e-mails de compte (« mot de passe oublié »,
confirmation de l'adresse) par Brevo. Tant que Brevo n'est pas branché, ces
écrans affichent « L'envoi d'e-mails n'est pas encore configuré » et aucun
joueur ne peut récupérer son mot de passe seul.

1. Crée un compte sur brevo.com (offre gratuite, 300 e-mails/jour, société
   française). Active la double authentification.
2. Brevo > Expéditeurs, domaines > **Domaines** > Ajouter `<domaine>` >
   choisis « Cloudflare » : Brevo ajoute lui-même les enregistrements DNS
   (sinon, copie-les dans Cloudflare > DNS). Attends la coche verte.
3. Brevo > Expéditeurs > ajoute `contact@<domaine>`.
4. Brevo > SMTP et API > onglet **Clés API** > Générer une clé API, nom
   `Lucarne appli`. Copie la clé (montrée une seule fois).
   Brevo peut bloquer les envois venant d'une adresse IP inconnue : les
   fonctions Supabase changent d'adresse, donc dans Brevo > Sécurité >
   **IP autorisées**, désactive ce blocage (sinon le premier essai échoue et
   Brevo t'envoie un e-mail « IP non reconnue »).
5. GitHub > dépôt Application-football- > Settings > Secrets and variables >
   Actions :
   - Onglet **Secrets** > New repository secret : `BREVO_API_KEY` = la clé.
   - Onglet **Variables** > New repository variable :
     `MAIL_FROM_EMAIL` = `contact@<domaine>` ; `MAIL_FROM_NAME` = `Lucarne`.
6. GitHub > Actions > « Supabase commercial : mise en route » > Run workflow,
   en cochant seulement « functions ». Le journal doit afficher « Envoi des
   e-mails : réglé ».
7. Test : sur l'appli, « mot de passe oublié » avec ta propre adresse.

Facultatif, par sécurité : les e-mails envoyés par Supabase lui-même (rares
ici) partent par défaut d'un service limité à quelques messages par heure.
Pour les faire passer aussi par Brevo : Brevo > SMTP et API > onglet **SMTP**
> Générer une clé SMTP, puis Supabase > Authentication > **Emails** > SMTP
Settings > Activer (hôte `smtp-relay.brevo.com`, port `587`, identifiant et
clé SMTP Brevo, expéditeur `contact@<domaine>`, nom `Lucarne`).

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
