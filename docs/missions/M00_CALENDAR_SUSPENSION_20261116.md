# M00/M04 — Calendrier : suspension du club

16 novembre 2026, Petit Filet commercial uniquement. Base :
`5f404e70f70b4e99d754f7064b567d027d66fe03`. Références : plan #147,
audit M04 #149 et issue #37. Proposition de correction, non déployée.

## Déclencheur et effet

Le flux `calendar-feed` utilise une clé de service. Il vérifiait le jeton
d'abonnement et le statut actif du profil, mais pas le statut de son club.
Dans la reproduction isolée, un profil encore actif d'un club suspendu
recevait donc toujours le calendrier (200) ou sa redirection navigateur (302).
Cela confirme le défaut dans le handler, pas une exploitation réelle de la
base commerciale ni une fuite entre clubs démontrée.

La lecture d'abonnement exige maintenant aussi `clubs.status = active`, avec
la jointure `clubs!inner`. Un club suspendu ne produit plus ni calendrier ni
redirection : 404 générique, sans lecture de matchs. Le contrôle est relu
à chaque requête. Les clubs actifs conservent GET/HEAD, la redirection,
l'identité du calendrier et les UID historiques des événements.

## Vérifications exécutées

- Banc comportemental Node 24.22.1 sans réseau ni secret : exécution du vrai
  corps TypeScript, types effacés ; seuls les deux imports externes, le SDK
  transport et l'environnement Deno sont remplacés. Aucun changement du
  code métier testé. Le double applique les filtres et jointures internes
  nécessaires ; il ne constitue pas une pile PostgREST ou un test de RLS.
- Avant correction, **6/12 tests échouent** : statut suspendu/inconnu/nul/absent,
  navigateur/HEAD et suspension du même jeton entre deux requêtes.
- Après correction, **12/12 tests réussissent**. Vérifications complémentaires :
  absence de lecture de matchs après refus, retour après réactivation,
  profil inactif, club absent, jeton révoqué/invalide, erreur SQL simulée,
  méthodes interdites, et exclusion des matchs de l'autre club fictif.
- `python3 supabase/tests/edge/verify_edge_security_contract.py` : réussi,
  avec contrôle du statut de club avant la redirection.
- `git diff --check` : réussi. Test comportemental branché sur la CI Supabase,
  Node 24 et action épinglée déjà utilisée dans le dépôt.

Commande reproductible :

```bash
node --test supabase/tests/edge/calendar_feed_security.test.mjs
python3 supabase/tests/edge/verify_edge_security_contract.py
```

## Limites et conditions de livraison

La CI complète sur le SHA final doit être examinée, ainsi qu'un essai HTTP
sur une stack Supabase isolée autorisée (club actif → suspendu → actif), avant
toute validation de mise en ligne. Aucun pgTAP local, déploiement Edge ou
essai HTTP commercial n'a été exécuté pour ce lot. Le code de production
reste inchangé tant que cette proposition n'est pas effectivement déployée.
Le test garantit la réaction du handler aux réponses filtrées du double ;
la jointure et le filtrage PostgREST réels doivent encore être éprouvés.

Les événements déjà téléchargés par un agenda tiers ne peuvent pas être
effacés à distance par ce contrôle. Il concerne les prochains accès au flux.
Ce lot ne traite ni les autres RPC/Edge ni l'ensemble de l'audit sécurité.

Aucune migration SQL, écriture de données, copie de données réelles,
dépense, fusion ou publication. AS Grinta original et Carte soirée intacts.

## Complément : essai HTTP réellement isolé à exécuter en CI

La première CI complète de #157 a réussi sur
`10688700fa23618c2698cf168b52f4cff4efd854`. Ce succès n'incluait pas encore
l'essai HTTP ci-dessous ; ses nouveaux résultats doivent être vérifiés sur
le nouveau SHA, sans réutiliser le vert du premier commit.

`calendar_feed_http.py` démarre la vraie fonction avec la CLI sur la stack
locale jetable de la CI, crée deux clubs et comptes fictifs et utilise les
vrais endpoints Auth/Edge/PostgREST. Il vérifie GET, HEAD, redirection non
suivie, suspension/réactivation du même jeton, maintien de l'accès au club B,
profil inactif et révocation du jeton. Les matchs réels et appareils restent
hors de cet essai (calendriers fictifs vides, identité de club contrôlée).

Les cibles API/DB sont locales et fixes, validées avant toute écriture ; aucun
argument cible ou secret n'est accepté. Les données et clés sont éphémères.
La sortie brute de la CLI et les journaux Edge ne sont pas publiés. Les
redirections ne sont jamais suivies vers un hébergeur public.

Vérifications locales du complément : compilation Python et diff sans erreur ;
trois tests existants de sécurité des cibles HTTP locaux réussis. Docker et
Supabase CLI n'étant pas installés dans cette session, le résultat HTTP réel
ne doit être déclaré réussi qu'après l'étape dédiée du nouveau run CI.

Documentation vérifiée avant correction :
[Supabase — RLS et clés de service](https://supabase.com/docs/guides/database/postgres/row-level-security).
