# Corrections issues de l'audit comparatif AS Grinta / Petit Filet (13/11/2026)

## Menu « Paramètres » aligné sur AS Grinta (version du 11/11)

- « Administration » devient « Effectif », comme dans AS Grinta.
- « Équipes & stades » s'ouvre par sa propre adresse (`/admin/stadiums`).
- La saison se crée ou se termine directement depuis Paramètres (plus d'écran « Saisons » dans le menu ; l'ancienne adresse `/admin/season` reste valable).
- L'ancien lien `/admin/settings` renvoie vers Paramètres.
- Le mode « Voir l'app comme un joueur » et son bandeau sont retirés, comme dans AS Grinta.
- Restent propres à Petit Filet : « Réglages du club » et « Ajouter des matchs passés ».
- Les mentions de l'interrupteur d'aperçu dans `AUDIT_ROUTES_ET_PARAMETRES.md` sont donc périmées.

## Données personnelles retirées des tests

Le dépôt est public. Des noms réels de joueurs et de staff d'AS Grinta, ainsi que les identifiants de leurs comptes, restaient dans des tests. Ils sont remplacés par des noms et identifiants fictifs ; les tests vérifient les mêmes règles. Le script `supabase/tests/statistics_module_history.sql`, qui contrôlait les statistiques réelles d'AS Grinta et n'était lancé par aucun contrôle, est supprimé.

Limite : la migration de départ `20261111000100_socle_structure.sql` contient encore ce nom et deux identifiants. Une migration appliquée ne se modifie pas ; leurs effets sont neutralisés par des migrations plus récentes.

## Nom de staff codé en dur dans la base

`private.is_known_non_player_archive_name` écartait un nom précis des statistiques historiques. Dans une base multi-clubs, un homonyme d'un autre club aurait été exclu de ses propres statistiques. La migration `20261116010000_retirer_nom_staff_archive.sql` la rend neutre (aucun nom écarté). Aucune donnée n'est modifiée.

## Vérifié, non modifié

L'ouverture du mode live suit le réglage « Fermeture des pronostics » : c'est voulu (le serveur fige aussi l'effectif à ce moment) et l'aide du réglage l'indique.
