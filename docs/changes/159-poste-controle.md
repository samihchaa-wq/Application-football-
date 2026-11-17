# Poste de contrôle Petit Filet — chantier 159

## Ambition validée par le propriétaire

Le 16 novembre 2026, le propriétaire valide un compte gestionnaire de qualité,
avec un véritable centre de commande, accessible sur ordinateur et téléphone.
Le périmètre reste exclusivement **par équipe** ; les identifiants historiques
`club_id` n'ajoutent aucun niveau club commercial.

L'ambition comprend : vue quotidienne des sujets à traiter, recherche globale,
fiches équipes, investigation des incidents, consultation contrôlée selon les
rôles, assistance Idées/Problèmes, communication ciblée, paiements/promotions/
parrainage, simulation financière, analyse des parcours, déploiement progressif
des nouveautés, journal des actions, sécurité/sessions, sauvegardes et reprise,
puis assistant proposant des conclusions reliées à leurs preuves.

Les actions sensibles (envois, droits, opérations financières, restauration,
publication) sont préparées avec aperçu et conséquences, puis confirmées
explicitement. La consultation n'usurpe jamais une identité ni ne modifie
implicitement le rattachement d'un compte à une équipe.

## Premier lot développé : consultation réelle

- Entrée « Espace gestionnaire » depuis la connexion ; route `/control`, en
  dehors de la navigation des équipes et chargée en différé.
- Une session sans équipe peut rejoindre le contrôle opérateur sans créer une
  équipe artificielle. Les droits sont vérifiés par les RPC serveur existantes,
  jamais par un rôle admin d'équipe ou une métadonnée utilisateur.
- Navigation responsive : Vue générale, Équipes, Supervision, Évolutions.
- Compteurs définis, dates d'observation, recherche et filtres d'équipe,
  fiche équipe et échéances annuelles enregistrées à trente jours.
- Échecs des tâches et notifications sur une heure, taille de la base ;
  source manquante affichée indisponible/non mesurée, jamais un faux zéro.
- Aucun montant hérité par joueur affiché comme chiffre d'affaires ; aucune
  modification de profil ou de match présentée comme une connexion.
- Aucun cache disque ; rafraîchissement chaque minute, au retour d'arrière-plan
  et à la demande. Pendant une nouvelle vérification, masquer les anciennes
  données. Un refus serveur sur l'une des deux RPC retire toute la réponse.
- Consultation uniquement : aucun bouton d'envoi, suspension ou facturation.

## Sources vérifiées en lecture seule

Référence du code : `main` `61e941b15bfd5df6c9e00281bb38bbf565d9b871`.
Supabase commercial uniquement : définitions de `platform_list_clubs`,
`platform_health`, `private.is_platform_operator` et droits EXECUTE lus.
Les deux RPC publiques contrôlent la liste privée des opérateurs ; elles sont
réservées au rôle authenticated et refusées à anon. Ces lectures de catalogue
ne remplacent pas des tests avec JWT ni une revue exhaustive de sécurité.
Le précédent contrôle dans cette conversation comptait zéro opérateur activé.
Ce lot ne crée aucun compte ni droit privilégié.

Sources des mesures :

| Indicateur | Source actuelle | Limite |
|---|---|---|
| Équipes | lignes de `platform_list_clubs` | espaces techniques enregistrés |
| Membres actifs | compteur `members` | profils au statut actif, pas des utilisateurs connectés |
| Dernière modification | `last_activity_at` | mises à jour profils/matchs, pas connexions |
| Échéance | `current_period_end` | date enregistrée, pas prélèvement ni revenu garanti |
| Notifications | `platform_health` | tentatives ; aucune preuve de lecture |
| Tâches | `failed_jobs_last_hour` | exécutions cron en échec, pas incidents uniques |
| Taille DB | `database_bytes` | taille totale, pas capacité prouvée |
| Recettes/coûts/sauvegardes/restaurations | aucune source raccordée | non mesuré |

La liste d'équipes est actuellement chargée en une requête. Pagination serveur,
recherche indexée et preuve de charge restent nécessaires avant de prétendre
à une console validée pour plusieurs centaines d'équipes.

## Découpage de la suite

1. **Identité et traçabilité.** Préparer l'attribution privée du propriétaire,
   second facteur et récupération, révocation, preuve de session et journal
   privé. Ne pas activer cet accès avant revue sécurité et choix d'identité privé.
2. **Assistance.** Registre privé Idées/Problèmes, suivi, réponses et accusés,
   idempotence, limites d'envoi et conservation/effacement. Le support ne publie
   pas les demandes dans GitHub public.
3. **Observabilité.** Relier incidents, traces, tâches et notifications, définir
   les fenêtres temporelles et dédupliquer ; instrumenter les parcours avec
   minimisation des données. Construire une vraie file « À traiter ».
4. **Commercial.** Registre de paiements vérifiés, devis et échéances, promotions
   et parrainage #161, remboursements/avoirs. Simulation strictement séparée des
   vrais abonnements ; prix 100 €/équipe/an, HT/TTC à formaliser.
5. **Communication et configuration.** Annonces ciblées avec aperçu et suivi,
   politiques de notification, configurations versionnées et nouveautés par
   cohortes ; rollback testé avant toute publication progressive.
6. **Consultation des espaces.** Vue limitée et auditée, champs autorisés et
   motif d'accès explicites, sans modification de JWT, usurpation de session,
   accès général aux échanges ou contournement de RLS.
7. **Reprise et sécurité.** Preuves de sauvegarde/restauration, alertes testées,
   exercice isolé, sessions et actions confirmées ; pas de restauration aveugle.
8. **Assistant.** Questions en langage naturel, données autorisées, preuves et
   degré de certitude ; accès et outils limités, confirmation des mutations.

## Vérification et état

Nouveaux tests : modèles et bornes d'échéances, agrégats, recherche/filtres,
droits refusés, révocation pendant les lectures, supervision manquante,
réponses invalides, routage à froid/sans équipe, écrans 390/1280 pixels,
recherche et fiche, retrait des données après refus et texte agrandi à 360 pixels.
Ils doivent être exécutés avec la suite Flutter existante et le build web sur
le dernier SHA avant de conclure à une validation. Aucun résultat de test non
exécuté n'est revendiqué par cette liste.

Local : formatage Dart effectué, analyse du modèle sans dépendances réussie,
contrôle de diff effectué. La préparation Flutter a été bloquée par le contrôle
automatique d'environnement (tentative signalée vers un service de métadonnées).
Pas de contournement ; validation complète confiée à GitHub CI.

**Statut : premier lot développé, pas activé/déployé.** Pas de compte créé, pas
de migration ni écriture Supabase, pas de secret, achat, notification réelle,
fusion ou publication. AS Grinta original et Carte soirée intacts.
