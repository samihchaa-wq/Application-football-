# Petit Filet — assainir les abonnements Web Push malformés

## Observation réelle (lecture seule)

Dans la base commerciale du 13/11/2026 : `push_delivery_log`
contient **67 tentatives, 0 succès**. Les erreurs dominantes
(`The subscription p256dh value should be 65 bytes long.` et
`Failed to decode base64url`) signalent des clés de souscription invalides.

**Limite :** les comptes/appareils fictifs peuvent expliquer ces résultats.
Cela ne prouve pas que les notifications échouent sur des mobiles réels.

## Correction ciblée

`send-push/delivery_policy.ts` vérifie désormais avant envoi :

- `p256dh` est du base64url décodable, 65 octets et une clé P-256 non
  compressée (premier octet `0x04`) ;
- `auth` est du base64url décodable de 16 octets.

Si l'une des deux valeurs est incorrecte, l'envoi est **sauté sans requête
réseau et sans relance**, enregistré comme tentative échouée, et l'endpoint
malformé est transmis à la RPC existante `internal_push_prune`.

Les trois voies d'envoi (envoi ciblé, événement Live, événement sportif)
emploient la même validation. Les erreurs temporaires des abonnements valides
conservent leur logique de réessai. Aucune clé privée ou valeur de souscription
n'est écrite dans la documentation ni le log d'erreur.

## Couverture

Tests Deno ajoutés à `delivery_policy_test.ts` :
clés bien formées, clé P-256 tronquée ou invalide, secret `auth` invalide,
absence d'appel réseau pour abonnement irrécupérable, livraison inchangée pour
un abonnement structurellement valide.

## Limites / garde-fous

- **Pas de modification SQL, de Supabase commercial ni d'AS Grinta original.**
- La PR ne répare pas les appareils dont l'abonnement est invalide : ils
  doivent se réabonner depuis le navigateur ou l'application.
- La validation structurelle **ne démontre pas la délivrabilité**, qui exige
  des essais sur appareils réels et l'examen des permissions du navigateur.
- Ne pas fusionner ni déployer cette PR avant CI Deno/Flutter et revue.
