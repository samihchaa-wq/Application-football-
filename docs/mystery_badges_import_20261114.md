# Import des badges mystères d’AS Grinta vers Petit Filet

Cette migration restitue **23 badges personnalisés identifiables par leur code d’origine**, dont **11 badges à attribution automatique**, en s’appuyant uniquement sur les migrations SQL d’AS Grinta : `20260923230000_automatic_mystery_badges.sql`, `20260930150000_more_automatic_mystery_badges.sql`, `20261006092000_automatic_triple_chrono_badge.sql` et `20261002120000_texts_audit_wording.sql`.

Le catalogue est inséré dans `private.badge_templates` pour les futurs clubs et complété de manière non destructive dans les clubs existants. Les codes originaux sont conservés afin de rattacher les règles connues ; les 11 règles automatiques sont déjà prises en charge par `private.profile_match_exploits` et `recalculate_profile_badges`. Les attributions restent propres à chaque club ; aucun profil, résultat, donnée utilisateur ni badge décerné d’AS Grinta n’est copié.

## Limites vérifiées

**La liste exhaustive de la production AS Grinta n’est pas consultable avec les connexions actuellement disponibles.** Le seed du dépôt original ne contient pas les badges créés depuis l’interface d’administration. Les 23 codes couvrent ceux référencés dans les quatre migrations historiques étudiées ; d’autres badges peuvent exister uniquement dans la base originale. Ne pas annoncer une synchronisation exhaustive sans comparer le catalogue de cette base.

**Les visuels personnalisés ne sont pas copiés.** Les 23 badges utilisent provisoirement l’emblème standard `🏅` sur fond orange. Ils pourront recevoir leurs véritables images une fois que leurs fichiers sources auront été exportés volontairement et importés dans le Storage commercial, sans référencer le Storage original.

Pour `« Voy a marcar »`, `Sauvetage in extremis` et `Le Plongeur`, le libellé est attesté mais la description finale exacte n’est pas présente dans ces migrations. La description est laissée vide pour ne pas inventer une condition.

## Vérification

Exécuter `supabase/tests/database/import_as_grinta_mystery_badges.test.sql` sur une base isolée après application des migrations. Contrôler la présence de 23 badges par club, des 11 règles automatiques et des 12 attributions manuelles possibles, puis vérifier l’armoire et l’administration. Les badges déjà gagnés demeurent inchangés. Aucun déploiement vers AS Grinta n’est requis ou autorisé.
