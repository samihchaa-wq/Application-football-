# Problèmes trouvés hors lot (Kyky)

Une ligne : quoi, où, gravité. La propriétaire choisit l'ordre.

- Remboursement par carte : l'éditeur peut enregistrer un faux numéro de remboursement Stripe à la main (`platform_record_refund`, migration 20261201000000). Réservé à l'éditeur. Gravité : faible.
- `stripe-refund` : limite de taille du message lue seulement dans l'en-tête déclaré (supabase/functions/stripe-refund/handler.ts). Gravité : faible.
- `stripe-checkout` et `stripe-refund` : CORS ouvert à toutes origines (`*`). Le jeton de connexion protège ; durcir quand le domaine final est fixé. Gravité : faible.
- Sécurité base : aucun test base de données (pgTAP) lancé dans cette session, faute de Postgres/Supabase local. À relancer en CI. Gravité : à vérifier.
