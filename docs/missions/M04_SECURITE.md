# Mission 04 — Sécurité et séparation des clubs

État : **en cours, premier lot de preuves ; NO-GO sécurité non levé**.
Rapport du 16 novembre 2026 (Europe/Paris). Plan appliqué : PR #147, prompt Fil 04.
Code examiné : main `5f404e70f70b4e99d754f7064b567d027d66fe03`.
Environnement distant : Supabase commercial `jvxkhgdopslctpcjrhzw`, **lecture seule**.
Les observations du 15 novembre ont été complétées par une nouvelle lecture le 16 novembre.
Aucune modification d'AS Grinta original ou de Carte soirée ; aucun compte créé, aucune migration, fusion ou publication.

## Résultat utile au chef de projet

Le socle SQL présente des protections effectives dans ses métadonnées. Cela ne prouve pas encore l'ensemble des parcours négatifs avec de vrais JWT.
Un écart de contrôle de suspension est identifié dans le code de l'agenda déployé ; reproduction dynamique isolée à réaliser.
Ne pas fermer #37 et ne pas considérer les 165 avertissements comme 165 failles ni comme 165 exceptions intégralement validées.

## Vérifications réellement exécutées

| Contrôle | Résultat et portée |
| --- | --- |
| Catalogues commerciaux : tables publiques | 0 table ordinaire/partitionnée sans RLS. Contrôle structurel, pas test de toutes les policies. |
| Vues publiques | 0 vue sans option `security_invoker=true`. |
| Fonctions publiques SECURITY DEFINER accessibles à anon | 0. Ne prouve pas la fermeture de tout endpoint anonyme. |
| Fonctions publiques privilégiées accessibles à authenticated | 165 : 161 propriétaires club_scope, 4 postgres. |
| Schéma private, même critère | 49 fonctions supplémentaires : 47 club_scope, 2 postgres. L'audit ne doit pas se limiter au compteur public de l'advisor. USAGE, exposition PostgREST et chaînes d'appels à vérifier séparément. |
| search_path | Vide explicitement pour les 214 fonctions privilégiées ci-dessus. |
| Rôle club_scope, première lecture | NOLOGIN, NOBYPASSRLS, non-superutilisateur. Vérifier aussi les appartenances et la propriété des tables lors de la revue complète. |
| Storage commercial | profile-photos privé ; app-assets et badge-images publics. Aucun octet ni URL privée collectés. La confidentialité des photos ne s'étend pas automatiquement aux deux buckets publics. |
| Edge calendar-feed déployée | Source récupérée via API de gestion : version 25, verify_jwt=false. Lecture de code, sans appeler un abonnement réel. |
| Contrat statique Edge local | `python3 supabase/tests/edge/verify_edge_security_contract.py` : OK. |
| Garde de sécurité du harnais HTTP local | `python3 -m unittest discover -s tool/qa -p 'test_tenant_http_safety.py' -v` : 3 tests réussis. **Ces tests ne lancent pas Auth/REST/Storage.** |

Les requêtes de catalogue ne lisent pas les identités ni les secrets. Une requête SQL contenant plusieurs SELECT ne renvoie que son dernier résultat dans ce connecteur ; les compteurs ci-dessus ont donc été reconfirmés ensemble dans un unique résultat JSON, plutôt que déduits d'un résultat tronqué.

## Preuves CI existantes consultées, distinctes d'une nouvelle exécution

PR #145, HEAD `40a74f05bba499f43f68c2577526fe357bcae6d9` :
- [HTTP Auth/RLS/RPC/Storage](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769841568) : succès lors de la consultation.
- [Suite métier/RLS](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769841470) : échec ; étape pgTAP échouée, lint ensuite ignoré. **La PR ne satisfait pas ses conditions de fusion.** Cause précise à diagnostiquer, sans assimiler cet échec à une fuite.
- Le harnais HTTP lu crée deux clubs et deux administrateurs GoTrue avec JWT réels ; il teste lectures propres, en-tête x-club-id falsifié, RPC admin, photos privées et suspension/réactivation de club avec le même JWT.
- Il ne couvre pas à lui seul joueur, opérateur, compte retiré, toutes les RPC, URLs signées, Realtime ou les fonctions Edge déployées.

Ces résultats sont ceux de cette branche et de ce SHA ; ils ne valent pas une nouvelle recette de main ou une validation commerciale complète.
Pas de Docker, psql, Supabase CLI ni Deno disponibles dans le PATH de cet environnement de travail : aucune nouvelle suite SQL/HTTP locale complète exécutée ici.

## Constats et gravité

### M04-01 — Agenda : suspension du club non contrôlée — P1 provisoire, à reproduire

Source : `supabase/functions/calendar-feed/index.ts`, également observée dans la fonction distante v25.
Le flux exige un token d'abonnement existant et un profil actif. La sélection joint le club mais ne filtre pas son statut.
La lecture des matchs utilise la clé service et un filtre explicite sur le club de l'abonnement ; elle contourne donc les RLS et ne réutilise pas le garde de club actif.

Conséquence attendue par lecture de code : un détenteur d'un lien valide pourrait continuer de récupérer les dates, adversaires et adresses du club suspendu, tant que son profil reste actif.
**Aucune récupération de données d'un club suspendu n'a été tentée en production. Aucune fuite vers un autre club n'est démontrée.**
Précondition : posséder le lien secret ; ce n'est pas un accès libre à tous les agendas.
Le niveau final dépend du contrat de suspension et du retest isolé.

Demande M02 : contrôler le club actif avant de servir le flux ou une redirection ; examiner également la cohérence entre le club du profil actuel et celui de l'abonnement.
Demande M03 : exécuter le cas AGENDA-SUSP ci-dessous, incluant GET et HEAD.
Aucun changement distant dans ce lot.

### M04-02 — Protection des mots de passe compromis désactivée — configuration à traiter

Advisor commercial observé : `auth_leaked_password_protection` WARN.
Ce constat est une faiblesse de configuration, pas une compromission démontrée.
M02/M09 : préparer activation et test de création/changement de mot de passe, avec autorisation de configuration appropriée ; relecture advisor ensuite.
[Remédiation officielle](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

### M04-03 — Exceptions SECURITY DEFINER : revue incomplète — blocage de preuve

Les 165 fonctions publiques ne doivent pas être révoquées globalement. Leur usage depuis Flutter peut être légitime.
Les quatre exceptions postgres publiques sont get_my_club_access et les trois RPC plateforme. La justification doit suivre les signatures exactes, gardes et dépendances.
Revoir aussi les 49 fonctions privées accessibles au rôle connecté : le nom du schéma ne garantit pas son inaccessibilité.
Les tests statiques de présence d'un nom de garde ne démontrent ni son exécution sur tous les chemins ni son efficacité.
[Advisor et remédiation](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

### M04-04 — PR #145 : durcissement utile, pas réparation d'une fuite établie

La policy club_scope_access permissive ne neutralise pas club_isolation restrictive TO PUBLIC.
Le rôle club_scope reste soumis à cette dernière. L'ajout d'un filtre club explicite dans les chemins Storage est une seconde barrière.
Ne pas présenter la migration comme urgente sur la seule base de la policy permissive. Suite SQL rouge à résoudre avant intégration, puis autorisation de fusion ; aucune migration commerciale appliquée dans cette mission.

## Modèle de menaces

| Acteur / moyen | Risque | Contrôle attendu |
| --- | --- | --- |
| Visiteur ou JWT falsifié | Données et fonctions privilégiées accessibles | Signature/audience/expiration vérifiées ; anon fermé sauf endpoints publics justifiés |
| Joueur actif | Élévation admin, modification d'un autre profil | Droits serveur et contraintes ; métadonnées utilisateur ignorées pour l'autorisation |
| Admin B connaissant des UUID A | Lecture/écriture interclub REST/RPC/Storage | Club dérivé du profil serveur, garde métier et RLS restrictive |
| Compte retiré/suspendu, JWT encore valide | Droits conservés après changement | Relire statut et rattachement courant sur chaque frontière sensible |
| Club suspendu | Accès via anciennes sessions/liens | Politique explicite appliquée aussi aux Edge avec clé service |
| Opérateur | Accès global indûment accordé | Liste opérateurs serveur, moindre privilège, audit des actions |
| Détenteur d'un lien privé | Accès agenda ou URL signée après révocation | Durée/révocation documentées et tests ; pas de lien dans logs publics |
| Contributeur/dépendance/CI | Secrets publics ou déploiement abusif | Scan historique confidentiel, permissions CI minimales, protection main et sauvegardes |

## Matrice de recette restante et cas reproductibles

Tous les cas ci-dessous sont **à exécuter**, sauf recouvrement partiel explicitement référencé dans les preuves CI. Exclusivement environnement isolé, clubs et données fictifs.

| Cas | Étapes | Attendu |
| --- | --- | --- |
| IDENT-01 | Obtenir JWT joueur/admin A et B ; tenter PATCH rôle/club_id puis modifier user_metadata et réutiliser le JWT | Aucun gain de rôle ni changement de club ; état SQL inchangé |
| RETIRE-01 | Connexion A, conserver JWT ; suspendre/archiver puis retirer le profil dans l'instance jetable | Aucun accès métier résiduel REST/RPC/Storage/Edge ; bootstrap propre seulement si prévu |
| RPC-AB | Pour chaque signature sensible : appel autorisé A, joueur refusé, admin B avec cible A, paramètres/en-têtes falsifiés | Refus/vide sans données A ni effet ; lire l'état final via témoin privilégié local |
| STORAGE-AB | Créer objets A/B, lire, lister, remplacer/upsert, déplacer et supprimer avec chacun des rôles | Actions légitimes réussies ; aucun accès croisé ; octets et existence vérifiés après refus |
| STORAGE-LINK | Tester URL publique et signature pour photos ; suspendre puis réutiliser lien signé avant/après expiration | Photos non publiques ; durée résiduelle des signatures documentée et arbitrée |
| AGENDA-SUSP | Créer un abonnement A, vérifier GET/HEAD valides ; suspendre club A seulement, conserver profil actif et token ; rejouer GET/HEAD et navigation navigateur | Refus uniforme sans calendrier ni redirection divulguant le flux ; B reste disponible |
| EDGE-AB | manage-user reset/delete contre B ; claim-club avec compte déjà rattaché ; falsifier rôle, token et club | Aucun effet sur B, pas d'invitation ni e-mail réel ; pas de confiance dans x-club-id client |
| EXPORT-AB | Export joueur/admin A, tenter cible B et vérifier la structure complète | Aucune donnée B, aucun secret push/Auth |
| REALTIME-AB | Souscrire A aux tables/canaux B puis produire une mutation fictive B ; retirer A et continuer la session | Aucun événement B ; comportement après retrait explicitement vérifié |
| OPER-01 | Appeler les trois RPC plateforme depuis joueur/admin A/B puis opérateur autorisé et opérateur révoqué | Seul opérateur valide accepté, sans dépendre de user_metadata |
| AUTH-RECOVERY | Liens de récupération expirés/réutilisés, scanner de liens, changement mot de passe et anciennes sessions | Usage unique, bonne destination commerciale, révocation conforme au contrat |
| ABUS-01 | Séries bornées inscription, invitation, agenda, récupération et push, avec limites connues | Pas d'envoi réel ; limites efficaces côté serveur, erreurs non révélatrices |

Compléter chaque ligne avec SHA, configuration, rôle, méthode/route, statut/réponse assainie, état avant/après et lien de preuve.
Ne jamais accepter HTTP 500 générique comme preuve de refus : identifier l'erreur attendue et prouver l'absence d'effet.

## Confidentialité, dépendances et exploitation : travail non terminé

- Le dépôt reste public conformément à la décision B ; aucun changement de visibilité.
- Pas de scan exhaustif nouveau de l'historique, médias, dumps ou secrets dans ce lot. Les anciens rapports ne suffisent pas à fermer ce point.
- Pas d'audit complet des vulnérabilités des dépendances ni des appartenances de rôles.
- Pas de validation complète de révocation Auth, rate limiting Edge ou livraison push.
- Conservation/révocation des liens d'agenda et droits photos à transmettre M07.
- Restauration DB/Auth/Storage, accès aux artefacts chiffrés et secrets hors dépôt à transmettre M09, suivi #91.
- Les textes anciens HANDOFF/CHANTIER divergent de la chaîne auto_release actuelle : M00/M09 doivent réconcilier ; aucune fusion implicite de cette documentation.

## Revue indépendante avant diffusion large

Préparer un périmètre incluant Auth/session, escalade de privilèges, tests interclubs REST/RPC/Storage/Realtime, Edge service_role, agenda, export/effacement, abus, CI et sauvegardes.
Fournir environnement isolé représentatif, comptes par rôle, schéma, inventaire des RPC et règles de suspension ; demander des preuves assainies, gravité, recommandations et retest.
Aucune prestation commandée ni dépense engagée.

## Relais et prochaine action

M02 : traiter M04-01 et examiner les gardes Edge utilisant service_role.
M03 : compléter la matrice réelle et diagnostiquer la CI SQL #145.
M07 : qualifier photos, liens privés, rétention et procédure d'incident.
M09 : configuration Auth, secrets/CI, restauration et environnement de recette.
M00 : maintenir #37 ouvert ; contrôler les preuves avant GO pilote mars/avril 2027.

Prochain lot M04 : reproduction isolée AGENDA-SUSP, inventaire par signature des fonctions privilégiées puis extension du harnais JWT aux profils retirés et aux opérations Storage complètes.
Décision propriétaire : aucune requise pour ces travaux isolés et préparatoires. Toute modification commerciale ou fusion reste hors de ce lot.
