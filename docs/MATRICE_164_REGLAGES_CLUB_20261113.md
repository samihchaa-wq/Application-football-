# Matrice 164 fonctionnalités — règles et options par club

> **Décision plus récente à appliquer :** aucun crédit +1 automatique ; correction exclusivement par administrateur. Voir [PR #105](https://github.com/samihchaa-wq/Application-football-/pull/105) et [contrat](changes/waitlist-admin-only-correctif-20261113.md). Les autres lignes de cette matrice sont conservées comme état documentaire ; ne pas les considérer comme tests réellement exécutés.

Établie le 13 novembre 2026 après comparaison GitHub AS Grinta (lecture seule) / Petit Filet. **Inventaire de décisions et preuves, pas déclaration de recette terminée.**

## Résumé

| Décision primaire | Nombre |
|---|---:|
| Conserver sans changer l'expérience | 77 |
| Adapter au multiclub | 33 |
| Rendre paramétrable | 36 |
| Option à pouvoir activer/désactiver | 17 |
| Retirer un reliquat historique seulement | 1 |
| **Total** | **164** |

Les modules obligatoires (authentification, sécurité, cloisonnement, intégrité des données, obligations légales et facturation) restent actifs pour tous les clubs, sans interrupteur. Un module désactivé ne doit ni effacer de données ni autoriser des écritures par l'API directe.

## Preuves et statut

- **Constat actuel :** 7 interrupteurs génériques (`predictions`, `statistics`, `man_of_the_match`, `live_mode`, `badges`, `season_wrapped`, `weather`) ; règles numériques issues de `get_club_rules`; adresse domicile, quota, identité, maillots ; administration badges. La présence d'un contrôle ne prouve pas son application partout.
- **Non démontré individuellement** = **à vérifier dans code/SQL**, ni « manquant » ni « déjà présent ». Les fonctions dont l'option est utile ne doivent pas devenir désactivables sans confirmation des dépendances.
- **Axes P0 :** isolement A/B, permission admin, attente manuelle, cohérence temporelle et pas de perte historique.
- **Axes P1 :** maillots gardiens / rendu bout en bout / snapshot historique (issue #67), stade neutre (issue #71), réglages regroupés avec aides (PR #78), barèmes/rappels/badges.
- **Axes P2 :** formats hors 11, internationalisation, clips joueurs et options de confort non requis au premier pilote.
- **Aucune opération Supabase**, aucune fusion ni mutation AS Grinta.

## Matrice de décision et validation (164 lignes)

*« Constat actuel » identifie une preuve de réglage lorsqu'elle est connue. Toutes les autres lignes exigent lecture détaillée et tests ; on n'infère pas de fonctionnalités manquantes sur le seul libellé.*

| Référence | Fonction | Décision | Constat actuel | Prochain contrôle / adaptation | Priorité source |
|---|---|---|---|---|---|
| A01 | Créer un club et son compte administrateur | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A02 | Rejoindre un club par code ou lien partagé | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| A03 | Changer le code d'invitation | Garder | Code d’invitation — RPC admin existante | Vérifier parcours réel et conserver comportement actuel. | P1 |
| A04 | Inscription joueur avec validation administrateur | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| A05 | Génération de l'identifiant prénom + initiale | Adapter | Non démontré individuellement | Tester homonymes club A/B et migration des comptes existants. | P0 |
| A06 | Connexion identifiant et mot de passe | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A07 | Connexion Facebook | Option | Non démontré individuellement | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| A08 | Adresse e-mail facultative et confirmation | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A09 | Mot de passe oublié et réinitialisation | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A10 | Mot de passe initial imposant un changement | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P1 |
| A11 | Acceptation CGU, politique et âge | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A12 | Changer son profil et sa photo | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| A13 | Exporter ses données personnelles | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A14 | Supprimer son compte et gérer les données historiques | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A15 | Déconnexion, révocation push, changement de compte | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| A16 | Accès club suspendu ou compte en attente | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| A17 | Compte unique rattaché à un seul club | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P1 |
| B01 | Nom et nom court sur tous les écrans | Paramétrer | Nom et nom court — Réglages du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| B02 | Écusson du club et valeur neutre par défaut | Paramétrer | Écusson — Réglages du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| B03 | Couleurs du club et contrastes | Paramétrer | Couleurs principale/secondaire — Réglages du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| B04 | Nom commercial et icône installée | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| B05 | Adresse du terrain à domicile | Paramétrer | Adresse domicile — Réglages du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| B06 | Nombre de convoqués par défaut | Paramétrer | Quota usuel — Réglages du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| B07 | Règles d'ouverture/fermeture et délais | Paramétrer | Catalogues temporels — get_club_rules / admin_set_club_rule | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| B08 | Choix des modules facultatifs | Option | 7 modules — get_club_modules / admin_set_club_module | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P0 |
| B09 | Changements de paramètres en temps réel | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| B10 | Fuseau horaire du club | Paramétrer | Non démontré individuellement | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P2 |
| B11 | Langue, devise, formats de date | Paramétrer | Non démontré individuellement | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P2 |
| B12 | Un espace équivaut à une seule équipe | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P2 |
| C01 | Ouvrir et archiver une saison | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| C02 | Cycle saisonnier juillet-juin | Paramétrer | Non démontré individuellement | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P2 |
| C03 | Fichier joueurs avec/sans compte | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| C04 | Fusion de l'effectif au rattachement du compte | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| C05 | Attribut coach sans place dans quota | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| C06 | Attribut gardien | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| C07 | Invités sans compte permanent | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| C08 | Historique canonique des joueurs et alias | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| C09 | Trois photos de maillot par joueur | Paramétrer | 3 photos historiques par joueur ; couleurs gardien NON configurables (issue #67) | Ne pas recolorier automatiquement les photos existantes. | P1 |
| C10 | Statuts membre actif, en attente, départ | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| C11 | Administration des profils et approbation | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| C12 | Aperçu 'voir comme joueur' | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D01 | Créer un match championnat, amical ou « entre nous » ; **coupe non implémentée** | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D02 | Journée de championnat | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D03 | Domicile/extérieur, stade et adversaire | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D04 | Horaire, lieu et heure de rendez-vous | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| D05 | Calendrier mensuel, passé, prochain, live | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D06 | Fenêtre 'prochain match' J-6 midi par défaut | Paramétrer | features_open_days / features_open_hour | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| D07 | Événements de club hors match | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| D08 | Flux calendrier .ics et liens publics | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| D09 | Suppression de match et historique des annulations | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| D10 | Historique de matchs importés | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| D11 | Saisie manuelle d'anciens matchs | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| D12 | Calcul et affichage météo du match | Option | Module weather | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| D13 | Affichage score résultat et compétition | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| E01 | Réponse présent/absent au match | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| E02 | Ouverture automatique ou anticipée des réponses | Paramétrer | features_open_days / features_open_hour | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E03 | Périodes d'indisponibilité anticipées | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| E04 | Motif d'indisponibilité privé | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| E05 | Disponibilités sans réponse et relances | Paramétrer | Rappels / délais : catalogue de règles, couverture à vérifier | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| E06 | Quota convoqués, remplaçants et coach | Paramétrer | usual_squad_size | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E07 | Liste d'attente par priorité saison précédente | Paramétrer | waitlist_mode | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E08 | Liste d'attente à 3 modes | Paramétrer | waitlist_mode (3 choix) | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E09 | Passages +1 et compteur en attente | Paramétrer | +1 automatiques au coup d’envoi, permanents sur la saison (PR #86) | Comportement serveur testé ; expliqué dans l’aide i. Ancienne règle « admin uniquement » remplacée. | P0 |
| E10 | Réorganisation manuelle / forcée par admin | Paramétrer | Non démontré individuellement | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E11 | Départ, retour, promotion, rétrogradation | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| E12 | Effectif publié, gel T-15, exception justifiée | Paramétrer | Règles temporelles, gel match selon serveur | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| E13 | Invités dans l'effectif du match | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| E14 | Match 'entre nous': tous les présents convoqués | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| E15 | Validation et notifications effectif | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| F01 | Éditeur de terrain, placement et remplaçants | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| F02 | Catalogue de 26 formations foot à 11 | Paramétrer | Formations 11 existantes, défaut club non prouvé | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| F03 | Dispositif initial 4-2-1-3 | Paramétrer | 4-2-1-3 codé comme défaut ; personnalisation club absente | Ajouter défaut formation configurable par club uniquement si métier le justifie. | P1 |
| F04 | Simulation de composition optimale | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| F05 | Profils de postes calculés via matchs passés | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| F06 | Publication et correction de composition | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| F07 | Compositions de deux équipes 'entre nous' | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| F08 | Animation d'entrée et stade vidéo | Garder | Vidéo à neutraliser : issue #71 | Nettoyer les deux MP4 et poster ; valider plusieurs frames + mobile. | P1 |
| F09 | Mini-vidéos individuelles détourées 3 à 5 secondes par joueur (souhait produit, distinct de l'animation de stade) | Paramétrer | Mini-vidéos non livrées | Reporter : médias utilisateurs, droits et coûts non arbitrés. | P2 |
| F10 | Portrait fixe si joueur sans mini-vidéo | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| F11 | Choix du maillot du match | Paramétrer | 3 maillots par club ; gardien manquant (issue #67) | Implémenter tenues gardien + propagation avant/live/après + snapshot historique. | P1 |
| F12 | Photos de kits associées à joueur/saison | Paramétrer | Maillots/joueurs, slots historiques | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| G01 | Activation/désactivation Live par club | Option | Module live_mode | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P0 |
| G02 | Ouverture T-15 et pilote unique | Paramétrer | prediction_close_minutes / gel live | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| G03 | Chronomètre, début/pause/reprise | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| G04 | Événements de but et passe décisive | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| G05 | Remplacements et temps de jeu | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| G06 | Changement de formation en Live | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| G07 | Notifications de buts en direct | Option | Rattachement à live_mode, notification à vérifier | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| G08 | Finalisation récapitulatif du Live | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| G09 | Compte rendu après match et correction | Paramétrer | correction_window_hours | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| G10 | Score, buteurs, passes, présence et clean sheet | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| G11 | Vote anonyme de joueur du match | Option | Module man_of_the_match | Garder module off côté RPC et historique des votes. | P0 |
| G12 | Ouverture/clôture et résultat du vote | Paramétrer | motm_window_hours | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| H01 | Pronostiquer score d'un match | Option | Module predictions | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P0 |
| H02 | Confidentialité des pronos avant résultat | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| H03 | Fermeture T-15 configurable | Paramétrer | prediction_close_minutes | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| H04 | Cotes automatiques basées sur adversaire/historique | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| H05 | Points exact, différence et issue | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| H06 | Classement de saison, général et historique | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| H07 | Rappel automatique personnalisé | Paramétrer | prediction_reminder_hour / prediction_reminder_lead_minutes | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| H08 | Désactivation pronostics et refus côté serveur | Option | Module predictions et protection RPC | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P0 |
| H09 | Multiplicateur/prono portefeuille ×2 historique | Retirer reliquat | Non démontré individuellement | Conserver compatibilité historique, retirer seulement contenu obsolète. | P2 |
| I01 | Statistiques collectives équipe | Option | Module statistics | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| I02 | Statistiques individuelles buts et passes | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| I03 | Clean sheets et statistiques gardiens | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| I04 | Participation, titularisation et banc | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| I05 | Classements, filtres et podiums | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| I06 | Carte joueur et historique des matchs | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| I07 | Archives statistiques importées | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| I08 | Désactivation de statistiques sans effacement | Option | Module statistics | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| J01 | Catalogue de badges et catégories | Option | Module badges | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| J02 | Badges automatiques par seuil | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| J03 | Badges événementiels et secrets | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| J04 | Badges manuels par administrateur | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| J05 | Armoire à badges et récompenses affichées | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| J06 | Images, couleurs et badges stars | Paramétrer | Administration badge / couleurs / images | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| J07 | Noms genrés, protégés, personnalisés | Paramétrer | Nom neutre Étoile du match ; badges à auditer | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| J08 | Seuils en fonction du nombre de matchs | Paramétrer | Seuils badges par club — PR #57 ; tests serveur à revoir | Vérifier que seuils modifiés sont appliqués serveur au club A sans changer B. | P2 |
| J09 | Notification d'attribution et boîte de réception | Option | Module badges + notifications | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| K01 | Bilan personnel de fin de saison | Option | Module season_wrapped | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| K02 | Diapositives et animations partageables | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| K03 | Aperçu administrateur avec données fictives | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| K04 | Bouton visible entre deux saisons seulement | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| K05 | Musique du bilan | Option | Option bilan / piste audio, droit et disponibilité à vérifier | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P2 |
| K06 | Nom Wrapped dans ressources/écran | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| L01 | Abonnement Web Push et autorisation appareil | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| L02 | Notifications d'ouverture des disponibilités | Paramétrer | Rappels disponibilité — règles du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| L03 | Convocation, désistement, liste d'attente | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| L04 | Changement, annulation ou report de match | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| L05 | Composition publiée | Option | Notifications composition / préférences à vérifier | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| L06 | Pronostics, vote HDM et résultat | Option | Notifications liés aux modules pronostics/votes | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| L07 | Badge débloqué | Option | Module badges + préférences | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. | P1 |
| L08 | Message libre administrateur et sélection destinataires | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| L09 | Préférences individuelles et coupe-circuit club | Paramétrer | Préférences notifications membre et modules du club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P0 |
| L10 | Historique notifications et pastille non lue | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P1 |
| L11 | Service worker, manifeste et installation PWA | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| L12 | Météo et push via tâche planifiée | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| M01 | Tableau admin comptes en attente | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| M02 | Éditer membres, effectif, badges et profils | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| M03 | Éditer matchs, saisons et paramètres | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| M04 | Envoi de notification libre | Garder | Non démontré individuellement | Vérifier parcours réel et conserver comportement actuel. | P0 |
| M05 | Gestion du statut d'abonnement et essai 30 jours | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| M06 | Prix indicatif 10 euros/joueur/an | Paramétrer | Prix non validé — ne pas rendre arbitraire côté club | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| M07 | Paiement, facturation et renouvellement | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| M08 | Console éditeur et opérateur de plateforme | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| M09 | Quotas stockage et fichiers | Paramétrer | Quota de stockage affiché, non réglable par admin | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. | P1 |
| M10 | Sauvegarde, restauration et supervision | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| M11 | Journal d'incidents et support | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| M12 | Gestion des comptes d'un club payant suspendu | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| N01 | Isolation par club tables PostgreSQL | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N02 | Isolation par club Storage | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N03 | Isolation par club Realtime et caches | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N04 | Fonctions privilégiées SECURITY DEFINER | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N05 | Endpoint publics, Web Push et anti-abus | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N06 | Migrations installées vs dépôt | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N07 | État des Edge Functions commerciales | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N08 | Tables et migrations testées en CI | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N09 | Déploiement site commercial actuellement désactivé | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P0 |
| N10 | Confidentialité du dépôt et de son historique | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N11 | Informations légales incomplètes | Adapter | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |
| N12 | Compatibilité des anciennes routes, RPC et clients | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P1 |
| N13 | Dépendances Flutter/JS et licences médias | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| N14 | Performance à 2, 20, 200 clubs | Adapter | Non démontré individuellement | Comparer code/règles AS Grinta, adapter puis tester régression. | P1 |
| N15 | Protection antifuite profils et exports | Garder | Non désactivable (intégrité) | Obligatoire : maintenir contrôle serveur/RLS et tests. | P0 |

## Références de travail

- `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` : source exhaustive initiale et constats/risques.
- `docs/CAHIER_DES_CHARGES_FIL_02.md` : lots F2-00 à F2-29 et critères d'acceptation.
- `docs/AUDIT_PARITE_REGLAGES_20261113.md` (PR #78) : comparaison des fichiers et réalisation du premier écran de réglages.
- Issues #66 (réglages), #67 (maillots gardiens), #71 (vidéo stade).

**À chaque PR de correction** : joindre les IDs correspondants, les fichiers/RPC effectivement vérifiés, les tests exécutés sur HEAD et les cas club A/B. Le présent tableau est un point de départ pour les preuves, pas une validation fonctionnelle.
