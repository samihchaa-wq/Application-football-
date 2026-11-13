# M04 — Vérification HTTP multiclub avec deux JWT réels

**Sécurité :** exécution exclusivement sur Supabase CLI local, ports 54321 et 54322 ; comptes, clubs et fichiers de test fictifs. Aucune clé ni donnée de la base commerciale ou du club AS Grinta.

Le workflow `.github/workflows/tenant_http_isolation.yml` :
- crée deux clubs distincts, puis leurs comptes par l'API Auth GoTrue ;
- obtient les JWT signés et interroge les tables via PostgREST et les RPC ;
- vérifie le cloisonnement RLS et le refus d'un en-tête `x-club-id` falsifié ;
- teste des écritures d'admin propres au club et le refus d'une cible étrangère ;
- téléverse deux images fictives dans Storage et refuse lecture/écriture interclub ;
- suspend puis réactive un club, vérifie la révocation immédiate des droits avec le JWT initial et le fonctionnement de l'autre club.

**Condition de validation :** la CI `tenant-http` doit être verte sur le dernier commit. Les protections existantes pgTAP et les tests Edge restent complémentaires.

**Limites :** un test local ne certifie pas la configuration en production, le niveau de sécurité d'un serveur public ni la restauration complète des données et fichiers. À qualifier séparément avant l'accueil de clubs réels.

Source de suivi : issue #37.