# Grille QA — 164 fonctionnalités métier de Petit Filet

> Référence : `main` au commit `2dc59830baf986e6a7d4b6fa93aabcf9869b17b9`, consulté le 13 novembre 2026. Généré à partir de `docs/MATRICE_164_REGLAGES_CLUB_20261113.md` et confronté au code et au schéma en lecture seule. **Ce fichier n'atteste aucun test utilisateur**.

**Légende de preuve :** `DB (lecture)` = état de base vérifié par requête SELECT ; `CODE` = présence détectée dans la source ; `NON VÉRIFIÉ` = parcours de bout en bout non exécuté. Aucun test à l'écran authentifié n'a été possible depuis ce poste. Un contrôle statique/CI n'est pas un test réel. Le résultat demandé pour chaque fonctionnalité doit évoluer vers `OK`, `KO` ou `NON VÉRIFIÉ` avec date, profil, match, capture et preuve.

| N° | ID | Élément | Décision | Preuve exécution | Résultat actuel | Observation / test obligatoire |
|---:|---|---|---|---|---|---|
| 1 | A01 | Créer un club et son compte administrateur | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 2 | A02 | Rejoindre un club par code ou lien partagé | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 3 | A03 | Changer le code d'invitation | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 4 | A04 | Inscription joueur avec validation administrateur | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 5 | A05 | Génération de l'identifiant prénom + initiale | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Tester homonymes club A/B et migration des comptes existants. |
| 6 | A06 | Connexion identifiant et mot de passe | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 7 | A07 | Connexion Facebook | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 8 | A08 | Adresse e-mail facultative et confirmation | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 9 | A09 | Mot de passe oublié et réinitialisation | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 10 | A10 | Mot de passe initial imposant un changement | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 11 | A11 | Acceptation CGU, politique et âge | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 12 | A12 | Changer son profil et sa photo | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 13 | A13 | Exporter ses données personnelles | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 14 | A14 | Supprimer son compte et gérer les données historiques | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 15 | A15 | Déconnexion, révocation push, changement de compte | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 16 | A16 | Accès club suspendu ou compte en attente | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 17 | A17 | Compte unique rattaché à un seul club | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 18 | B01 | Nom et nom court sur tous les écrans | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 19 | B02 | Écusson du club et valeur neutre par défaut | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 20 | B03 | Couleurs du club et contrastes | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 21 | B04 | Nom commercial et icône installée | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 22 | B05 | Adresse du terrain à domicile | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 23 | B06 | Nombre de convoqués par défaut | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 24 | B07 | Règles d'ouverture/fermeture et délais | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 25 | B08 | Choix des modules facultatifs | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 26 | B09 | Changements de paramètres en temps réel | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 27 | B10 | Fuseau horaire du club | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 28 | B11 | Langue, devise, formats de date | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 29 | B12 | Un espace équivaut à une seule équipe | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 30 | C01 | Ouvrir et archiver une saison | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 31 | C02 | Cycle saisonnier juillet-juin | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 32 | C03 | Fichier joueurs avec/sans compte | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 33 | C04 | Fusion de l'effectif au rattachement du compte | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 34 | C05 | Attribut coach sans place dans quota | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 35 | C06 | Attribut gardien | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 36 | C07 | Invités sans compte permanent | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 37 | C08 | Historique canonique des joueurs et alias | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 38 | C09 | Trois photos de maillot par joueur | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Ne pas recolorier automatiquement les photos existantes. |
| 39 | C10 | Statuts membre actif, en attente, départ | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 40 | C11 | Administration des profils et approbation | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 41 | C12 | Aperçu 'voir comme joueur' | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 42 | D01 | Créer un match championnat, amical ou « entre nous » ; **coupe non implémentée** | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 43 | D02 | Journée de championnat | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 44 | D03 | Domicile/extérieur, stade et adversaire | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 45 | D04 | Horaire, lieu et heure de rendez-vous | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 46 | D05 | Calendrier mensuel, passé, prochain, live | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 47 | D06 | Fenêtre 'prochain match' J-6 midi par défaut | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 48 | D07 | Événements de club hors match | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 49 | D08 | Flux calendrier .ics et liens publics | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 50 | D09 | Suppression de match et historique des annulations | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 51 | D10 | Historique de matchs importés | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 52 | D11 | Saisie manuelle d'anciens matchs | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 53 | D12 | Calcul et affichage météo du match | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 54 | D13 | Affichage score résultat et compétition | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 55 | E01 | Réponse présent/absent au match | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 56 | E02 | Ouverture automatique ou anticipée des réponses | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 57 | E03 | Périodes d'indisponibilité anticipées | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 58 | E04 | Motif d'indisponibilité privé | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 59 | E05 | Disponibilités sans réponse et relances | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 60 | E06 | Quota convoqués, remplaçants et coach | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 61 | E07 | Liste d'attente par priorité saison précédente | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 62 | E08 | Liste d'attente à 3 modes | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 63 | E09 | Passages +1 et compteur en attente | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comportement serveur testé ; expliqué dans l’aide i. Ancienne règle « admin uniquement » remplacée. |
| 64 | E10 | Réorganisation manuelle / forcée par admin | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 65 | E11 | Départ, retour, promotion, rétrogradation | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 66 | E12 | Effectif publié, gel T-15, exception justifiée | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 67 | E13 | Invités dans l'effectif du match | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 68 | E14 | Match 'entre nous': tous les présents convoqués | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 69 | E15 | Validation et notifications effectif | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 70 | F01 | Éditeur de terrain, placement et remplaçants | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 71 | F02 | Catalogue de 26 formations foot à 11 | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 72 | F03 | Dispositif initial 4-2-1-3 | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Ajouter défaut formation configurable par club uniquement si métier le justifie. |
| 73 | F04 | Simulation de composition optimale | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 74 | F05 | Profils de postes calculés via matchs passés | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 75 | F06 | Publication et correction de composition | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 76 | F07 | Compositions de deux équipes 'entre nous' | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 77 | F08 | Animation d'entrée et stade vidéo | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Nettoyer les deux MP4 et poster ; valider plusieurs frames + mobile. |
| 78 | F09 | Mini-vidéos individuelles détourées 3 à 5 secondes par joueur (souhait produit, distinct de l'animation de stade) | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Reporter : médias utilisateurs, droits et coûts non arbitrés. |
| 79 | F10 | Portrait fixe si joueur sans mini-vidéo | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 80 | F11 | Choix du maillot du match | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Implémenter tenues gardien + propagation avant/live/après + snapshot historique. |
| 81 | F12 | Photos de kits associées à joueur/saison | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 82 | G01 | Activation/désactivation Live par club | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 83 | G02 | Ouverture T-15 et pilote unique | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 84 | G03 | Chronomètre, début/pause/reprise | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 85 | G04 | Événements de but et passe décisive | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 86 | G05 | Remplacements et temps de jeu | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 87 | G06 | Changement de formation en Live | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 88 | G07 | Notifications de buts en direct | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 89 | G08 | Finalisation récapitulatif du Live | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 90 | G09 | Compte rendu après match et correction | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 91 | G10 | Score, buteurs, passes, présence et clean sheet | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 92 | G11 | Vote anonyme de joueur du match | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Garder module off côté RPC et historique des votes. |
| 93 | G12 | Ouverture/clôture et résultat du vote | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 94 | H01 | Pronostiquer score d'un match | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 95 | H02 | Confidentialité des pronos avant résultat | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 96 | H03 | Fermeture T-15 configurable | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 97 | H04 | Cotes automatiques basées sur adversaire/historique | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 98 | H05 | Points exact, différence et issue | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 99 | H06 | Classement de saison, général et historique | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 100 | H07 | Rappel automatique personnalisé | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 101 | H08 | Désactivation pronostics et refus côté serveur | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 102 | H09 | Multiplicateur/prono portefeuille ×2 historique | Retirer reliquat | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Conserver compatibilité historique, retirer seulement contenu obsolète. |
| 103 | I01 | Statistiques collectives équipe | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 104 | I02 | Statistiques individuelles buts et passes | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 105 | I03 | Clean sheets et statistiques gardiens | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 106 | I04 | Participation, titularisation et banc | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 107 | I05 | Classements, filtres et podiums | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 108 | I06 | Carte joueur et historique des matchs | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 109 | I07 | Archives statistiques importées | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 110 | I08 | Désactivation de statistiques sans effacement | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 111 | J01 | Catalogue de badges et catégories | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 112 | J02 | Badges automatiques par seuil | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 113 | J03 | Badges événementiels et secrets | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 114 | J04 | Badges manuels par administrateur | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 115 | J05 | Armoire à badges et récompenses affichées | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 116 | J06 | Images, couleurs et badges stars | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 117 | J07 | Noms genrés, protégés, personnalisés | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 118 | J08 | Seuils en fonction du nombre de matchs | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier que seuils modifiés sont appliqués serveur au club A sans changer B. |
| 119 | J09 | Notification d'attribution et boîte de réception | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 120 | K01 | Bilan personnel de fin de saison | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 121 | K02 | Diapositives et animations partageables | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 122 | K03 | Aperçu administrateur avec données fictives | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 123 | K04 | Bouton visible entre deux saisons seulement | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 124 | K05 | Musique du bilan | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 125 | K06 | Nom Wrapped dans ressources/écran | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 126 | L01 | Abonnement Web Push et autorisation appareil | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 127 | L02 | Notifications d'ouverture des disponibilités | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 128 | L03 | Convocation, désistement, liste d'attente | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 129 | L04 | Changement, annulation ou report de match | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 130 | L05 | Composition publiée | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 131 | L06 | Pronostics, vote HDM et résultat | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 132 | L07 | Badge débloqué | Option | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier coupure UI + RPC/cron/Edge et restauration sans perte. |
| 133 | L08 | Message libre administrateur et sélection destinataires | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 134 | L09 | Préférences individuelles et coupe-circuit club | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 135 | L10 | Historique notifications et pastille non lue | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 136 | L11 | Service worker, manifeste et installation PWA | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 137 | L12 | Météo et push via tâche planifiée | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 138 | M01 | Tableau admin comptes en attente | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 139 | M02 | Éditer membres, effectif, badges et profils | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 140 | M03 | Éditer matchs, saisons et paramètres | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 141 | M04 | Envoi de notification libre | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Vérifier parcours réel et conserver comportement actuel. |
| 142 | M05 | Gestion du statut d'abonnement et essai 30 jours | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 143 | M06 | Prix indicatif 10 euros/joueur/an | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 144 | M07 | Paiement, facturation et renouvellement | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 145 | M08 | Console éditeur et opérateur de plateforme | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 146 | M09 | Quotas stockage et fichiers | Paramétrer | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Valider plage, défaut AS Grinta, persistance club A/B et droits admin. |
| 147 | M10 | Sauvegarde, restauration et supervision | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 148 | M11 | Journal d'incidents et support | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 149 | M12 | Gestion des comptes d'un club payant suspendu | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 150 | N01 | Isolation par club tables PostgreSQL | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 151 | N02 | Isolation par club Storage | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 152 | N03 | Isolation par club Realtime et caches | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 153 | N04 | Fonctions privilégiées SECURITY DEFINER | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 154 | N05 | Endpoint publics, Web Push et anti-abus | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 155 | N06 | Migrations installées vs dépôt | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 156 | N07 | État des Edge Functions commerciales | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 157 | N08 | Tables et migrations testées en CI | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 158 | N09 | Déploiement site commercial actuellement désactivé | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 159 | N10 | Confidentialité du dépôt et de son historique | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 160 | N11 | Informations légales incomplètes | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 161 | N12 | Compatibilité des anciennes routes, RPC et clients | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |
| 162 | N13 | Dépendances Flutter/JS et licences médias | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 163 | N14 | Performance à 2, 20, 200 clubs | Adapter | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Comparer code/règles AS Grinta, adapter puis tester régression. |
| 164 | N15 | Protection antifuite profils et exports | Garder | **NON VÉRIFIÉ** (écran) | **NON VÉRIFIÉ** | Obligatoire : maintenir contrôle serveur/RLS et tests. |

## Règle de clôture des tests
- Une ligne ne passe à **OK** que si son scénario a été exécuté avec le rôle indiqué et les données enregistrées, puis relu en base lorsque pertinent.
- Une ligne ne passe à **KO** que si résultat obtenu différent du résultat attendu a été observé, reproduit, et si une preuve est enregistrée.
- Des contrôles DB faits sans session authentifiée sont **des contrôles d'inventaire**, pas des tests des droits d'un utilisateur.
- L'absence d'un élément dans le code actuel est documentée comme périmètre non livré, sans inventer une anomalie d'interface.

## Tests par match (à répéter sur les 30 rencontres)
| Étape | Scénario | Mode de preuve | Résultat actuel |
|---|---|---|---|
| T01 | Création, édition, report, annulation | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T02 | Disponibilités, absences, hésitations et commentaires privés | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T03 | Liste d'attente trois modes et +1 | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T04 | Convocations moins de 11 / surnombre / remplacement tardif | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T05 | Toutes formations, simulation et publication | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T06 | Pronostics avant, pendant, après fenêtre; cotes et barème | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T07 | Live coach/admin, événements, remplacements, erreurs | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T08 | Compte rendu, buteurs et corrections hors délai | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T09 | Étoile du match, vote sur soi, égalité, clôture | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T10 | Badges, statistiques et calculs indépendants | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
| T11 | Notifications actives puis désactivées | Écran authentifié et relecture DB / preuve capture | **NON VÉRIFIÉ (30/30 à faire)** |
