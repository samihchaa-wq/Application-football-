# M04 — Anciennes sessions et photos entre équipes

17 novembre 2026. Base : 0e5fa39e87f17ba466ef187ae44495a65a67de9c. Suite #149 / #37.

## État agenda réconcilié
Le correctif a été intégré via #157 ; #158 a été fermé sans fusion comme doublon. Preuve CI sur HEAD b9a840ff15690152487801d69681db45a6c0eb0a : https://github.com/samihchaa-wq/Application-football-/actions/runs/43815350984 : jobs calendar-http et database-tests réussis, étape HTTP réelle exécutée, pgTAP et lint exécutés. Cette preuve couvre le SHA indiqué et non une certification générale de main. Les 12 tests du gestionnaire et 3 tests du garde HTTP ont également réussi localement lors du précédent passage.

## Nouveau lot de tests, pas encore validé
Extension du harnais HTTP existant exécuté automatiquement par tenant_http_isolation.yml : remplacement et suppression de photo A par admin B, octets A inchangés après attaques ; contrôle positif du remplacement B avec les mêmes octets. Conservation du même vrai JWT après passage du profil A en pending puis archived : droits admin, lecture des profils, lecture Storage et écriture de couleurs doivent être refusés. État des couleurs inchangé et équipe B témoin ; réactivation A vérifiée.

Aucune modification produit, SQL ou workflow. Le garde local existant demeure. Les fixtures ne ciblent que Supabase local jetable. Les nouveaux cas HTTP restent à exécuter en CI : aucun succès supposé. Un premier brouillon avait passé la compilation Python ; la version publiée inclut un témoin positif supplémentaire et doit être revalidée par la CI. L'exécution locale n'est plus disponible à ce passage (service de commandes indisponible), sans blocage de la publication GitHub.

Limites : pas encore joueur, opérateur, suppression Auth, expirations/révocation de sessions, URLs signées ou Realtime. pending/archived ne prouvent pas la révocation cryptographique du token, mais le retrait des droits applicatifs malgré sa validité. M03 examine la preuve HTTP du nouveau SHA. M00 maintient #37 ouvert. Aucun changement commercial ni AS Grinta original.
