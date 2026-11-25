# Audit complet — 25/11/2026

## Phase 0 — État des lieux (fait)

| Contrôle | Résultat |
|---|---|
| Analyse statique (`flutter analyze`) | 0 problème |
| Tests | 1556 réussis, 0 échec |
| Couverture des tests | 64,2 % des lignes (21 956 / 34 195) |
| Build web release | OK, 51 Mo au total (script principal 4,9 Mo, moteur de rendu 37 Mo) |
| Graphe de code | mis à jour |
| Dépendances | 62 paquets ont une version plus récente, bloquées par les contraintes (voir plan de mise à jour existant) |

À noter :
- Des traces d'erreur s'affichent pendant les tests, mais tous passent :
  bruit ou erreurs attendues, à vérifier en phase 8.
- Un avertissement de build sur la police d'icônes iPhone (CupertinoIcons) :
  mineur, à vérifier en phase 6.
- Stripe : d'après `docs/HANDOFF.md`, aucun paiement ni événement Stripe n'a
  jamais été reçu en production, et les fonctions Stripe n'ont jamais été
  exécutées en test. À confirmer en lecture seule en phase 2.

Non testé : vrai téléphone, vrais paiements.

## Phase 1 — Sécurité + données (fait)

Méthode : lecture seule de la base de production `application-football`
(l'ancien projet `AS-Grinta` n'a pas été touché), lecture du code des
fonctions serveur, du site web et du dépôt.

### Verdict : aucun problème bloquant ni important trouvé

| Contrôle | Résultat |
|---|---|
| Tables de l'app | 65 sur 65 protégées par des règles d'accès ; aucune ouverte aux visiteurs non connectés |
| Cloisonnement entre clubs | 463 fonctions tournent sous un rôle qui respecte les règles par club ; règle « club_isolation » stricte sur les tables |
| Fonctions ouvertes aux visiteurs non connectés | 0 |
| Fonctions sensibles de paiement (`apply_*`, `stripe_*`, `vault_secrets`, `http_post`…) | non appelables par les utilisateurs |
| Fonctions « plateforme » (23) | toutes vérifient que l'appelant est l'éditeur |
| Fonctions « staff » / « coach » relues | toutes vérifient le rôle |
| Fonctions serveur publiques (5) | `stripe-webhook` : signature + anti-rejeu 5 min ; `send-push` : jeton interne ; `register-account` et `account-email` : limitation de débit ; `calendar-feed` : jeton aléatoire |
| Fichiers stockés | 3 espaces, images seulement (png/jpeg/webp, 5–10 Mo) ; photos de profil privées |
| Secrets dans le code | aucun (seule la clé publique `anon`, normale) ; aucune clé `service_role` côté app |
| Site web | CSP, HSTS, anti-iframe, anti-détection de type en place |

### Points mineurs (aucun corrigé : ils demandent de toucher à la base, donc ton accord)

1. **Image de badge pas assez contrôlée** : `staff_update_badge_image` accepte
   toute adresse qui *contient* le chemin du stockage, donc une image hébergée
   ailleurs passe. `staff_create_badge` ne vérifie pas l'adresse du tout.
   Réservé aux administrateurs de badges, risque faible. Correctif : exiger
   l'adresse exacte du stockage du projet.
2. **Reste de l'ancien projet** : fonction `grinta_sync.ping` (renvoie `1`),
   appelable par tout le monde, signalée par l'alerte Supabase. Inoffensive,
   à supprimer.
3. **Alerte « tables privées sans règle »** (6 tables `private.*`) : voulu, ces
   tables sont fermées à tous ; aucune action.

### Non vérifié

- **Réglages d'authentification de la production** (mots de passe compromis
  refusés, durée des sessions, limites de tentatives) : non lisibles d'ici.
  À contrôler par toi dans le tableau de bord Supabase.
- **Isolation entre deux clubs en vrai** : la production n'a qu'1 club. La
  protection est lue dans le code (règles strictes), pas éprouvée avec un
  deuxième club. Un test local existe (`docs/M04_TEST_HTTP_DEUX_CLUBS_*`),
  non rejoué ici.
- **Tests de sécurité de la base (pgTAP)** : non lancés, pas de base locale ici.
- **Données** : la production contient 21 profils actifs et 1 club (pas
  « personne encore ») ; 0 événement Stripe reçu, 1 paiement enregistré.

## Phase 2 — Paiements Stripe (fait)

Méthode : lecture du code des 3 fonctions Stripe et des fonctions de base
qu'elles appellent, lecture seule de la production, 26 tests des fonctions
Stripe relancés (réussis), et 3 appels invalides à la production (rejetés,
aucun effet).

### État réel en production
- Les 3 fonctions Stripe sont déployées et à jour.
- La clé de signature du webhook est configurée (réponse « signature
  invalide », et non « non configuré »).
- **Jamais utilisé** : 0 paiement par carte tenté, 0 événement Stripe reçu.
  Le seul paiement enregistré est un virement de 79 € saisi à la main.
- **Non vérifiable d'ici** : la clé secrète Stripe (nécessaire au bouton
  « Payer par carte »), et le point de terminaison déclaré côté Stripe.
  Le bouton n'a donc jamais été éprouvé de bout en bout.
- L'abonnement du club est actif jusqu'au **18/11/2037** : à confirmer que
  c'est voulu (période offerte ?).

### Ce qui est solide
- Le montant ne vient jamais de l'app : la base le calcule et le fige.
- Le paiement est enregistré seulement si montant et devise sont identiques
  à ceux figés ; ligne verrouillée, enregistrement une seule fois.
- Signature Stripe vérifiée, rejeu refusé après 5 min.
- Remboursement : droit « éditeur » vérifié, plafond = montant payé moins
  déjà remboursé ; un même remboursement (appli + tableau de bord Stripe) ne
  peut pas être compté deux fois (contrainte d'unicité en base).
- Contestations : transformées en alerte pour l'éditeur.

### Problèmes
1. **Important, peu probable : double paiement possible.** Chaque appui sur
   « Payer par carte » crée un nouveau paiement à régler, et l'ancien reste
   payable jusqu'à 24 h. Si un admin ouvre deux pages de paiement et règle les
   deux, le club est débité deux fois et deux années sont ouvertes (il faut
   un remboursement manuel). Le commentaire du code (« un double appui ne
   crée pas deux sessions ») est faux dans les faits. Correctif proposé :
   faire expirer la page de paiement après 30 min et réutiliser le paiement
   en attente récent au lieu d'en créer un autre. Touche aux paiements :
   **attend ton accord**.
2. **Mineur** : le webhook ne contrôle pas `livemode` (test ou réel) ; sans
   conséquence tant qu'un point de terminaison correspond à un secret.
   Il faudra séparer clairement test et réel au passage en vrais paiements.

### Non testé
- Un vrai paiement de bout en bout (même en mode test) : exige la clé
  secrète Stripe, absente d'ici.
- Les tests de la base (pgTAP) sur ces fonctions.

### Correction du problème 1 (double paiement) — faite, accord reçu
- Base (`20261206000000_paiement_carte_sans_doublon.sql`) : un paiement en
  attente de moins de 30 min, même club, même montant et mêmes réductions,
  est réutilisé ; verrou par club contre les appels simultanés.
- Fonction `stripe-checkout` : la page de paiement expire 32 min après la
  création ; deux appels pour le même paiement envoient des paramètres
  identiques, donc Stripe renvoie la même page (clé d'idempotence).
- Vérifié : 28 tests des fonctions Stripe réussis ; logique SQL rejouée dans
  une base jetable (réutilisation, montant changé, plus de 30 min, déjà payé,
  6 appels simultanés = 1 seule ligne).
- **Non vérifié** : test pgTAP ajouté (lancé par la CI seulement) ; vrai
  comportement de Stripe sur un appel répété (la réponse identique pour des
  paramètres identiques est documentée par Stripe, mais je n'ai pas de clé
  pour l'essayer) ; **migration non appliquée à la production** (elle part à
  la publication automatique, après fusion).
