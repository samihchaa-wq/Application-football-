# Tester le paiement par carte de bout en bout (Stripe, mode test)

But : vérifier toute la chaîne avant d'encaisser un vrai club. Un admin paie
par carte, Stripe prévient l'appli, l'année d'abonnement s'ouvre, une facture
est émise, puis on rembourse et un avoir est émis.

Aucun argent réel ne circule : on utilise uniquement des clés de test
(`sk_test_…`) et la carte de test de Stripe. Ne jamais mettre une clé dans le
dépôt, dans un fichier suivi par git ou dans un message.

Fonctionnement général : voir `docs/STRIPE.md`.

## Attention : ne pas tester sur la base de production

Il n'existe qu'une base Supabase en ligne, celle de production. Un paiement de
test reçu par la production y serait traité comme un vrai : paiement noté dans
la Caisse, année ouverte pour le club, facture numérotée PF-AAAA-NNNN prise
dans la suite légale des factures (qui doit rester continue et sans facture
fictive). Le webhook n'écarte pas les événements de test : il les note
seulement comme « mode test » dans `private.stripe_events`.

On teste donc sur une pile Supabase locale (sur un ordinateur), jamais sur la
production. Si un jour un projet Supabase de préproduction existe, la même
procédure s'y applique.

## Matériel

- Un compte Stripe en mode test (bascule « Mode test » du tableau de bord).
- Supabase CLI et Docker, pour la pile locale.
- Stripe CLI (`stripe login` une fois), pour relayer les événements de Stripe
  vers la pile locale.
- Flutter, pour lancer l'appli contre la pile locale.

## 1. Démarrer la pile locale

```sh
supabase start
```

La sortie donne l'adresse de l'API (`http://127.0.0.1:54321`), la clé
publique (anon) et l'adresse de la base
(`postgresql://postgres:postgres@127.0.0.1:54322/postgres`).

## 2. Relayer les événements Stripe

Dans un second terminal :

```sh
stripe listen --forward-to http://127.0.0.1:54321/functions/v1/stripe-webhook \
  --events checkout.session.completed,checkout.session.async_payment_succeeded,refund.created,refund.updated,charge.dispute.created,charge.dispute.updated,charge.dispute.closed
```

La commande affiche un secret `whsec_…` : c'est le `STRIPE_WEBHOOK_SECRET`
de la pile locale.

## 3. Lancer les fonctions serveur avec les clés de test

Créer hors du dépôt un fichier, par exemple `~/stripe-test.env` :

```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...   (celui de l'étape 2)
PUBLIC_APP_URL=http://localhost:8080
```

Vérifier que la clé commence bien par `sk_test_` : une clé `sk_live_`
encaisserait réellement.

```sh
supabase functions serve --env-file ~/stripe-test.env
```

## 4. Préparer un club de test avec un montant dû

Dans la base locale (`psql` sur l'adresse de l'étape 1). Créer d'abord, depuis
l'appli locale, un compte admin de club et un compte éditeur, puis :

```sql
-- Le compte éditeur voit le Gestionnaire (remplacer par son id).
insert into private.platform_operators (user_id) values ('<id du compte éditeur>');

-- Coordonnées vendeur fictives, seulement sur la base locale : sans elles,
-- aucune facture n'est émise.
update private.invoice_settings
set seller_name = 'Éditeur de test', seller_address = '1 rue du Test, 75000 Paris',
    siret = '00000000000000', contact_email = 'test@example.invalid';

-- Le club de test : essai terminé, forfait de 79 €, adresse de facturation.
update public.club_subscriptions
set status = 'trialing', trial_ends_at = now() - interval '1 day',
    base_price_cents = 7900, billing_address = '2 allée du Club, 31000 Toulouse'
where club_id = '<id du club de test>';
```

## 5. Payer

1. Lancer l'appli contre la pile locale, sur le port de `PUBLIC_APP_URL`
   (8080), avec l'adresse et la clé publique de l'étape 1.
2. Se connecter avec l'admin du club, ouvrir Abonnement, appuyer sur
   « Payer 79,00 € par carte ».
3. Sur la page Stripe : carte `4242 4242 4242 4242`, une date d'expiration
   future, n'importe quel code à 3 chiffres, n'importe quel nom.
4. Stripe renvoie vers l'écran Abonnement.

Pour tester aussi un refus : carte `4000 0000 0000 0002` (aucun paiement ne
doit être enregistré).

## 6. Vérifier

Dans la base locale :

```sql
-- L'événement est arrivé, en mode test, et a été traité sans erreur.
select id, type, livemode, ok, error, received_at
from private.stripe_events order by received_at desc limit 5;
-- Attendu : checkout.session.completed, livemode = false, ok = true.

-- Le paiement est noté, par carte, avec la session Stripe.
select amount_cents, method, received_on, stripe_checkout_session_id
from public.club_payments where club_id = '<id du club de test>';

-- L'abonnement est prolongé d'un an.
select status, current_period_end from public.club_subscriptions
where club_id = '<id du club de test>';
-- Attendu : active, fin de période dans environ un an.

-- La facture est émise.
select number, status, issued_on, amount_cents from public.club_invoices
where club_id = '<id du club de test>';
-- Attendu : un numéro PF-AAAA-0001, status = issued.
```

Dans l'appli : l'écran Abonnement indique « Payé jusqu'au … » ; la Caisse du
Gestionnaire montre le paiement, ses frais Stripe et le lien du reçu.

Rejouer le même événement (`stripe events resend <id>`) ne doit créer ni
second paiement ni seconde facture.

## 7. Rembourser

1. Avec le compte éditeur : Gestionnaire, fiche du club, « Rembourser ».
2. Vérifier :

```sql
select type, livemode, ok from private.stripe_events
order by received_at desc limit 3;
-- Attendu : refund.created (puis refund.updated), ok = true.
```

Le remboursement apparaît dans la fiche du club avec un avoir AV-AAAA-0001.
Dans le tableau de bord Stripe (mode test), le paiement est marqué remboursé.

## 8. Après le test

- `supabase stop --no-backup` efface la pile locale et ses données de test.
- Supprimer `~/stripe-test.env` ou le garder hors du dépôt.
- Pour la mise en service réelle : clés live et nouveau point de terminaison
  live (voir `docs/STRIPE.md`), et coordonnées réelles de l'éditeur dans
  `private.invoice_settings`.

## Ce que cette procédure ne couvre pas

- Les contestations (`charge.dispute.*`) : déclenchables avec
  `stripe trigger charge.dispute.created`, mais sans lien avec un club réel.
- Le paiement sur le vrai domaine (CSP, redirections Cloudflare) : à vérifier
  une seule fois après la mise en service, avec un petit montant réel
  remboursé ensuite.
