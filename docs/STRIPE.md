# Paiement par carte (Stripe)

## Fonctionnement

1. L'admin du club appuie sur « Payer par carte » (écran Abonnement, ou écran
   « club suspendu »).
2. La fonction `stripe-checkout` appelle `admin_prepare_card_payment()` avec le
   jeton de l'admin : la base calcule et fige le montant (parrainage compris).
3. Stripe Checkout encaisse ce montant exact. Un appui répété dans les
   30 minutes réutilise le même paiement en attente (pas de second paiement à
   régler) ; la page de paiement expire 32 minutes après sa création.
4. Stripe appelle `stripe-webhook` (signature vérifiée), qui appelle
   `stripe_record_card_payment()` : même effet qu'un paiement noté à la main
   (année ouverte, club rouvert, facture, parrainage). Idempotent.
5. Parrainage à 100 % : bouton « Activer mon année offerte »
   (`admin_claim_free_year()`), sans Stripe.

Remboursements : depuis la fiche d'un club dans le Gestionnaire
(« Rembourser »). Une carte est remboursée par la fonction `stripe-refund`
(au nom de l'éditeur) ; un remboursement fait dans le tableau de bord Stripe
est aussi enregistré (événement `refund.created`). Chaque remboursement crée
un avoir numéroté AV-AAAA-NNNN dès que la facture du paiement est émise.

Contestations : l'événement `charge.dispute.*` crée une alerte dans
« À faire ». La réponse se fait dans le tableau de bord Stripe ; l'éditeur
marque ensuite l'alerte comme traitée. Une contestation qui évolue redevient
à traiter.

Frais et reçu : après chaque paiement, le webhook lit les frais Stripe et le
lien du reçu (visibles dans la Caisse et la fiche club).

## Mise en service (une fois)

1. Migration `20261130000000_paiement_carte_stripe.sql` : appliquée par la
   publication automatique.
2. Déployer les fonctions `stripe-checkout`, `stripe-webhook` et
   `stripe-refund`.
3. Secrets des fonctions Supabase :
   - `STRIPE_SECRET_KEY` : clé secrète Stripe (`sk_test_…` puis `sk_live_…`) ;
   - `STRIPE_WEBHOOK_SECRET` : secret du point de terminaison (`whsec_…`).
   `PUBLIC_APP_URL` existe déjà.
4. Stripe › Développeurs › Webhooks › Ajouter un point de terminaison :
   - URL : `https://jvxkhgdopslctpcjrhzw.supabase.co/functions/v1/stripe-webhook`
   - événements : `checkout.session.completed`,
     `checkout.session.async_payment_succeeded`, `refund.created`,
     `refund.updated`, `charge.dispute.created`, `charge.dispute.updated`,
     `charge.dispute.closed`.
5. Tester en mode test (carte `4242 4242 4242 4242`), puis passer en clés live
   (nouveau point de terminaison live, nouveau `whsec_…`).

Sans `STRIPE_SECRET_KEY`, le bouton affiche « Le paiement par carte n'est pas
encore disponible » : rien n'est cassé.
