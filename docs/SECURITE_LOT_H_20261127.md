# Sécurité de la base et des comptes — lot H (27/11/2026)

Suite de l'audit du 26/11/2026, points 47, 21, 39 et 9.

## Point 47 — photo de profil limitée à son dossier (fait)

Avant : un membre pouvait mettre dans sa photo de profil le fichier d'un autre
membre et afficher son visage comme le sien.

Maintenant : la base refuse toute photo de profil qui n'est pas dans le dossier
du profil (`<id du profil>/...`). Vaut aussi pour un admin qui change la photo
d'un joueur (l'appli range déjà le fichier dans le dossier du joueur). Les
photos déjà enregistrées ne sont pas relues : elles s'affichent comme avant.

Migration `20261210070000_photos_profil_dossier_et_lecture.sql`, test
`profile_photo_folder_and_read.test.sql`.

## Point 21 — lecture des photos limitée aux dossiers du club (fait)

Avant : la lecture vérifiait seulement que le fichier avait été déposé par un
membre du club. Un fichier rangé dans le dossier d'un autre club restait
visible s'il avait été déposé depuis le club.

Maintenant : la lecture vérifie aussi le dossier (profil, joueur de saison ou
invité du club), comme le dépôt le fait déjà. La liste de la racine ne montre
que les dossiers du club.

Limite assumée : un membre peut toujours lister les dossiers de son propre
club. Ce sont les identifiants des membres, qu'il voit déjà dans l'Effectif.
Interdire toute liste demanderait de changer les fonctions internes du
stockage Supabase, que le projet ne contrôle pas.

### À vérifier avant la mise en ligne

Les photos importées d'AS Grinta n'ont pas pu être relues (accès à la base de
production refusé depuis cette session). Si un fichier est rangé dans un
dossier qui ne correspond à aucun profil, joueur de saison ou invité de son
club, il deviendra invisible. Requête à lancer dans l'éditeur SQL de Supabase
(lecture seule, ne renvoie que des nombres) :

```sql
select count(*) as photos_qui_deviendraient_invisibles
from storage.objects o
left join public.profiles owner on owner.id::text = o.owner_id
where o.bucket_id = 'profile-photos'
  and not (
    ((storage.foldername(o.name))[1] = 'season' and exists (
      select 1 from public.season_players s
      where s.id::text = (storage.foldername(o.name))[2]
        and s.club_id = owner.club_id))
    or ((storage.foldername(o.name))[1] = 'guest' and exists (
      select 1 from public.guest_players g
      where g.id::text = (storage.foldername(o.name))[2]
        and g.club_id = owner.club_id))
    or exists (
      select 1 from public.profiles p
      where p.id::text = (storage.foldername(o.name))[1]
        and p.club_id = owner.club_id)
  );
```

Résultat attendu : 0. Sinon, ne pas mettre en ligne et me redonner le nombre.

## Point 39 — double authentification des admins (proposée, pas obligatoire)

- Profil > « Double authentification » (visible pour les admins) : QR code à
  scanner, puis premier code à 6 chiffres. Désactivation possible avec un code.
- Une fois activée, le code est demandé avant de créer un lien de nouveau mot
  de passe ou de supprimer un compte. Le serveur (`manage-user`) le vérifie
  aussi : un mot de passe volé seul ne suffit plus pour ces actions.
- Admins qui ne l'activent pas : rien ne change.
- Pour la rendre obligatoire plus tard (décision de Samih, pas faite) : secret
  `ADMIN_MFA_REQUIRED=true` sur la fonction `manage-user`. Les admins sans code
  seront alors bloqués sur ces deux actions jusqu'à l'activation.
- Réglage Supabase : Authentication > Multi-Factor, TOTP activé (c'est le cas
  par défaut ; à vérifier dans le tableau de bord).

Non fait : demander le code dès la connexion. Le code n'est demandé qu'au
moment d'une action sensible.

## Point 9 — sauvegardes (proposition, rien changé)

Constat : la sauvegarde hebdomadaire est chiffrée (GPG AES-256) puis déposée
comme artefact du dépôt GitHub, qui est public. Tout compte GitHub connecté
peut télécharger l'archive chiffrée. Sa sécurité repose entièrement sur la
phrase secrète `BACKUP_PASSPHRASE`, et l'archive reste 90 jours.

Recommandation : envoyer l'archive (toujours chiffrée) dans un bucket
Cloudflare R2 privé, et ne plus la déposer comme artefact.

- Pourquoi R2 : le projet utilise déjà Cloudflare, 10 Go gratuits, pas de frais
  de sortie, règle d'expiration automatique (par exemple 90 jours).
- Modification du workflow `production_backup.yml` : remplacer l'étape
  « Retain encrypted archive only » par un envoi avec la CLI `aws s3 cp`
  (compatible R2), avec un jeton R2 limité à l'écriture dans ce seul bucket.
- À faire par Samih : créer le bucket et le jeton dans Cloudflare, ajouter les
  secrets `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`,
  `R2_BUCKET` dans GitHub.
- Alternative plus simple : rendre le dépôt privé. Mais les minutes GitHub
  Actions deviennent payantes au-delà du quota, et le site est publié depuis
  ce dépôt : à vérifier avant.

Rien n'a été changé dans le workflow : j'attends ton accord.
