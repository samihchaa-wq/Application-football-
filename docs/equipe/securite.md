# Sécurité — rapport

## Passage du 2026-11-26 — sujet : cloisonnement entre clubs des fonctions « admin » et « éditeur »

Question : un admin du club A peut-il, via une fonction serveur, lire ou modifier les données du club B ? Vérifié en base réelle, SELECT uniquement.

**Fait**
- Visiteur non connecté : aucune fonction du schéma public exécutable. OK.
- 164 fonctions à privilèges appelables par un utilisateur connecté (alerte Supabase « SECURITY DEFINER »). Attendu par conception :
  - 137 appartiennent au rôle `club_scope`, qui ne contourne pas les règles d'accès. Une règle bloquante `club_isolation` (club du profil de l'appelant) s'applique alors sur profils, matchs, compositions. Le club vient du profil connecté, impossible à changer par l'appelant. → un admin ne touche que son club, même en passant l'identifiant d'un autre club.
  - 27 appartiennent à `postgres` (contourne les règles) : 25 fonctions éditeur, toutes gardées par « est éditeur » en tête ; 2 fonctions paiement admin (`admin_claim_free_year`, `admin_prepare_card_payment`) limitées au club de l'appelant ; `get_my_club_access` ne lit que son propre club. OK.
- 5 fonctions admin sans contrôle repéré au premier tri (`admin_update_profile_fields`, compositions entre nous v2/v4/v5, reset) : relues, elles vérifient bien le rôle admin, et le cloisonnement ci-dessus s'applique. OK.
- 6 tables du schéma privé (compteurs de factures, événements Stripe, alertes paiement…) : accès fermé à tous sauf serveur. Voulu.

**Problèmes**
- Faible — base, fonction `grinta_sync.ping` : chemin de recherche non figé (alerte Supabase). Effet : quasi nul aujourd'hui ; bonne pratique à corriger lors d'une prochaine migration. → Décision attendue (migration).
- Faible — anciennes versions `admin_save_internal_composition_v2` et `_v4` toujours appelables. La v4 accepte de sauter la vérification « composition visuelle complète » que la v5 impose. Effet : un admin pourrait publier une compo incomplète en appelant l'ancienne version. Pas une fuite, règle métier contournable. → Décision attendue : retirer v2/v4 si l'appli ne les utilise plus.

**Non testé / reste à vérifier**
- Pas d'essai réel avec deux comptes de clubs différents (demanderait des écritures) : conclusion tirée de la lecture des règles et des propriétaires, pas d'une attaque simulée.
- Schémas exposés par l'API en production (réglage du tableau de bord, invisible en SQL). Si `private` était exposé, 49 fonctions privées deviendraient appelables directement. Config locale : non exposé. À confirmer dans Supabase → Settings → API.
- Fonctions non préfixées `admin_`/`platform_` (joueurs) : non relues une par une ce passage.

**Décisions attendues**
1. Migration : figer le chemin de recherche de `grinta_sync.ping`.
2. Retirer les anciennes versions de compo entre nous (v2, v4 publique) si inutilisées.
