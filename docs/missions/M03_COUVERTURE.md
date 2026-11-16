# M03 — Couverture de l’inventaire M01

Version : `5f404e70f70b4e99d754f7064b567d027d66fe03` ; relevé du 16/11/2026. Source : [inventaire M01](../AUDIT_FONCTIONNALITES_DETAILLE.md). **164/164 identifiants tracés ; 0 verdict E2E accordé par cette mission.** Ce décompte ne signifie pas 164 fonctions approuvées pour le pilote. Les intitulés historiques sont conservés pour traçabilité ; M01 doit confirmer les exigences 2027, en particulier A07, C09, F09, H09, M05–M07 et N09.

Chaque ligne reçoit un résultat explicite. Les preuves automatisées et limites sont dans [le rapport](M03_RECETTE.md) ; elles ne transforment pas le verdict écran en PASS. Lors de l’exécution, consigner SHA, environnement, rôle fictif, entrées, étapes, attendu, obtenu, capture/log expurgé, défaut et retest. La colonne exigence reprend une demande de vérification M01, pas un comportement constaté.

| ID M01 | Fonction de référence | Exigence / vérification M01 | Protocole | Verdict E2E M03 |
|---|---|---|---|---|
| A01 | Créer un club et son compte administrateur | Valider création réelle, doublons, rollback si échec | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A02 | Rejoindre un club par code ou lien partagé | Confirmer code, expiration/rotation et deep-link PWA | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A03 | Changer le code d'invitation | Conserver et vérifier effet immédiat sur anciens liens | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A04 | Inscription joueur avec validation administrateur | Tester attente, refus et activation avec deux clubs | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A05 | Génération de l'identifiant prénom + initiale | Résoudre homonymes à l'échelle multiclub et prévoir migration douce | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A06 | Connexion identifiant et mot de passe | Tester session, expiration, erreurs et reconnexion | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A07 | Connexion Facebook | Conditionner à OAuth effectivement configuré; masquer sinon | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A08 | Adresse e-mail facultative et confirmation | Valider délivrabilité, confirmation, expiration et doublons | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A09 | Mot de passe oublié et réinitialisation | Tester avec/sans e-mail confirmé et jetons expirés | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A10 | Mot de passe initial imposant un changement | Conserver obligation et tester accès refusé tant que non changé | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A11 | Acceptation CGU, politique et âge | Compléter textes et prouver version acceptée selon parcours | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A12 | Changer son profil et sa photo | Tester édition, redimensionnement, erreurs d'envoi | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A13 | Exporter ses données personnelles | Tester exactitude, périmètre, format et droits | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A14 | Supprimer son compte et gérer les données historiques | Tester anonymisation, statistiques, objets et sessions | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A15 | Déconnexion, révocation push, changement de compte | Vérifier purge cache et abonnement appareil | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A16 | Accès club suspendu ou compte en attente | Écran adapté, interdiction serveur, voies de support | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| A17 | Compte unique rattaché à un seul club | Rendre visible la limite; éviter bascule silencieuse | [S01](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B01 | Nom et nom court sur tous les écrans | Éradiquer mentions visibles AS Grinta y compris exports/notifs | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B02 | Écusson du club et valeur neutre par défaut | Tester ajout, remplacement, suppression, cache | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B03 | Couleurs du club et contrastes | Tester combinaisons accessibles pour widgets/animations | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B04 | Nom commercial et icône installée | Décider avec fil 5 et garder distinction produit/club | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B05 | Adresse du terrain à domicile | Ajouter écran de réglage, préremplir matchs et météo | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B06 | Nombre de convoqués par défaut | Exposer usual_squad_size dans administration | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B07 | Règles d'ouverture/fermeture et délais | Documenter bornes, rétroactivité et horaire affiché | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B08 | Choix des modules facultatifs | Vérifier comportement sans perte de données et refus côté serveur | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B09 | Changements de paramètres en temps réel | Tester invalidation du cache, plusieurs appareils, écrans ouverts | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B10 | Fuseau horaire du club | Conserver Paris pour cible initiale; traiter IANA pour hors-fuseau | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B11 | Langue, devise, formats de date | Limiter marché FR pour lancement puis plan internationalisation | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| B12 | Un espace équivaut à une seule équipe | Documenter limite; prévoir architecture si équipe A/B | [S02](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C01 | Ouvrir et archiver une saison | Tester clôture unique, changement et historique | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C02 | Cycle saisonnier juillet-juin | Vérifier besoin de saisons personnalisées avant international | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C03 | Fichier joueurs avec/sans compte | Tester création et rattachement sans doublon | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C04 | Fusion de l'effectif au rattachement du compte | Vérifier changement nom, désactivation, retour saison suivante | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C05 | Attribut coach sans place dans quota | Conserver disponibilité, vote, prono et pilotage Live | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C06 | Attribut gardien | Vérifier compositions, statistiques et photos | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C07 | Invités sans compte permanent | Tester réutilisation, archivage, place dans match, suppression | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C08 | Historique canonique des joueurs et alias | Conserver rapprochement prudent des homonymes | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C09 | Trois photos de maillot par joueur | Conserver option visuelle, adapter aux maillots du club | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C10 | Statuts membre actif, en attente, départ | Vérifier traces passées et permissions | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C11 | Administration des profils et approbation | Tester toutes actions avec non-admin | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| C12 | Aperçu 'voir comme joueur' | Tester séparation prévisualisation/droits réels | [S03](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D01 | Créer un match championnat, amical ou « entre nous » ; **coupe non implémentée** | Valider les trois types présents, et n'ajouter « coupe » qu'après décision produit et tests serveur/client | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D02 | Journée de championnat | Gérer doublons, valeurs manquantes, autres compétitions | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D03 | Domicile/extérieur, stade et adversaire | Conserver bibliothèque équipes/stades, édition/suppression | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D04 | Horaire, lieu et heure de rendez-vous | Tester modification avant/après ouverture, report | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D05 | Calendrier mensuel, passé, prochain, live | Tester focus, chargement paginé, responsive | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D06 | Fenêtre 'prochain match' J-6 midi par défaut | Tester horaires locaux + valeurs admin | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D07 | Événements de club hors match | Tester créer, éditer, supprimer, visibilité | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D08 | Flux calendrier .ics et liens publics | Nettoyer identifiants sporteasy-grinta, tester révocation et annulations | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D09 | Suppression de match et historique des annulations | Tester verrou, cascade, flux ICS, push | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D10 | Historique de matchs importés | Conserver lecture seule, aucune contamination pronos/live | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D11 | Saisie manuelle d'anciens matchs | Vérifier travaux parallèles et critères d'import | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D12 | Calcul et affichage météo du match | Dépend adresse; vérifier repli, localisation et API | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| D13 | Affichage score résultat et compétition | Tester score inhabituel, match annulé, chrono | [S04](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E01 | Réponse présent/absent au match | Tester concurrence, rechargement et historiques | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E02 | Ouverture automatique ou anticipée des réponses | Tester J-6, dérogation match, fermeture | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E03 | Périodes d'indisponibilité anticipées | Tester bornes incluses, chevauchement, report et retrait | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E04 | Motif d'indisponibilité privé | Tester visibilité joueur/admin uniquement | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E05 | Disponibilités sans réponse et relances | Configurer horaire, éviter spam/doublons | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E06 | Quota convoqués, remplaçants et coach | Défaut configurable; dépassement contrôlé | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E07 | Liste d'attente par priorité saison précédente | Rendre l'algorithme lisible et compatible autres modes | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E08 | Liste d'attente à 3 modes | Consolider branche parallèle, tests après migration | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E09 | Passages +1 et compteur en attente | Valider idempotence, fenêtre J-1, rétroactivité | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E10 | Réorganisation manuelle / forcée par admin | Aligner choix temporaires et moteur automatique | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E11 | Départ, retour, promotion, rétrogradation | Tester simultanéité et notification seulement sur changement | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E12 | Effectif publié, gel T-15, exception justifiée | Tester verrou et correction serveur | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E13 | Invités dans l'effectif du match | Tester quotas, éligibilité simulation et doublons | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E14 | Match 'entre nous': tous les présents convoqués | Préserver exception au moteur de liste | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| E15 | Validation et notifications effectif | Tester transitions de publication et ciblage | [S05](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F01 | Éditeur de terrain, placement et remplaçants | Tester glisser, remplacement, poste vide, petit écran | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F02 | Catalogue de 26 formations foot à 11 | Ajouter formats 5/7/8 si marché visé; conserver 11 | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F03 | Dispositif initial 4-2-1-3 | Défaut défini par club ou format | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F04 | Simulation de composition optimale | Vérifier priorités, gardien, remplaçant, historique absent | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F05 | Profils de postes calculés via matchs passés | Tester recrue et historique ancien, identités | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F06 | Publication et correction de composition | Vérifier verrou, droits et exceptions | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F07 | Compositions de deux équipes 'entre nous' | Tester équipes déséquilibrées, joueurs 1-11 | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F08 | Animation d'entrée et stade vidéo | Préserver ergonomie, fluidité et vérifier droits média | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F09 | Mini-vidéos individuelles détourées 3 à 5 secondes par joueur (souhait produit, distinct de l'animation de stade) | Aucun parcours d'import/admin et stockage vidéo personnel vérifié ; définir spécification, fallback et coûts avant implémentation | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F10 | Portrait fixe si joueur sans mini-vidéo | Préserver le comportement photographique actuel et exiger fallback lorsque F09 sera réellement réalisé | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F11 | Choix du maillot du match | Remplacer enum France/Orange/Bleu par catalogue propre club | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| F12 | Photos de kits associées à joueur/saison | Associer variantes à catalogue de club, conserver anciens matchs | [S06](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G01 | Activation/désactivation Live par club | Tester refus RPC et écran masqué | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G02 | Ouverture T-15 et pilote unique | Conserver règle par défaut; tester deux pilotes | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G03 | Chronomètre, début/pause/reprise | Tester changement appareil, coupure, horloge | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G04 | Événements de but et passe décisive | Tester ajout, annulation, but contre son camp, doublons | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G05 | Remplacements et temps de jeu | Tester salves, joueurs tardifs, gardien, banc | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G06 | Changement de formation en Live | Tester état concurrent et historique d'événements | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G07 | Notifications de buts en direct | Coupler au réglage Live, préférences et permissions | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G08 | Finalisation récapitulatif du Live | Valider idempotence et transfert compte rendu | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G09 | Compte rendu après match et correction | Vérifier fenêtre 24 h configurable, conflits | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G10 | Score, buteurs, passes, présence et clean sheet | Vérifier cohérence entre live, final, stats, badges | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G11 | Vote anonyme de joueur du match | Neutraliser vocabulaire, préserver anonymat et anti-double vote | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| G12 | Ouverture/clôture et résultat du vote | Tester à la validation, délai et ex æquo | [S07](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H01 | Pronostiquer score d'un match | Tester fenêtre, mise à jour et suppression avant verrou | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H02 | Confidentialité des pronos avant résultat | Vérifier API, vues et écran adversaire | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H03 | Fermeture T-15 configurable | Tester UTC/Paris et changements de date | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H04 | Cotes automatiques basées sur adversaire/historique | Tester club neuf sans match, résultat rare et archive | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H05 | Points exact, différence et issue | Documenter barème et cas égalités/annulations | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H06 | Classement de saison, général et historique | Tester changements rétroactifs, homonymie et égalités | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H07 | Rappel automatique personnalisé | Tester heure club, opt-out et idempotence cron | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H08 | Désactivation pronostics et refus côté serveur | Tester POST direct, accès anciens classements | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| H09 | Multiplicateur/prono portefeuille ×2 historique | Conserver compatibilité tant que dépendances non prouvées; retirer uniquement traces mortes | [S08](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I01 | Statistiques collectives équipe | Tester saison courante/précédente/global | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I02 | Statistiques individuelles buts et passes | Tester corrections d'archives et joueurs sans compte | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I03 | Clean sheets et statistiques gardiens | Vérifier cas de remplacement/score encaissé | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I04 | Participation, titularisation et banc | Conserver calcul historique, invités et coach | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I05 | Classements, filtres et podiums | Tester rang ex æquo, pagination et saisons | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I06 | Carte joueur et historique des matchs | Vérifier photo, badges, réalisations, saisons vides | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I07 | Archives statistiques importées | Dissocier origine importée et données actuelles | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| I08 | Désactivation de statistiques sans effacement | Tester masquage et routes directes, data conservée | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J01 | Catalogue de badges et catégories | Vérifier modèles à l'ouverture d'un club vide | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J02 | Badges automatiques par seuil | Tester recalcul, saison/total, rétrocorrection | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J03 | Badges événementiels et secrets | Tester combinaisons et non divulgation | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J04 | Badges manuels par administrateur | Vérifier audit et refus joueur | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J05 | Armoire à badges et récompenses affichées | Conserver présentation et règles de visibilité | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J06 | Images, couleurs et badges stars | Conserver visuels par club, vérifier droits de fichiers | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J07 | Noms genrés, protégés, personnalisés | Neutraliser libellés puis permettre personnalisation | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J08 | Seuils en fonction du nombre de matchs | Étudier réglages pour saisons courtes sans changer défauts | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| J09 | Notification d'attribution et boîte de réception | Tester doublons, lecture et opt-out | [S09](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K01 | Bilan personnel de fin de saison | Tester éligibilité, données nulles et saison archivée | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K02 | Diapositives et animations partageables | Préserver rendu mobile/tablette et export | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K03 | Aperçu administrateur avec données fictives | Indiquer clairement démo et jamais créer vraies stats | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K04 | Bouton visible entre deux saisons seulement | Vérifier cycle de vie et accès direct | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K05 | Musique du bilan | Fichier audio absent d'après code; activer uniquement avec licence, repli silencieux | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| K06 | Nom Wrapped dans ressources/écran | Auditer marque visible, décider fil 5/7 | [S10](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L01 | Abonnement Web Push et autorisation appareil | Tester iOS PWA, Android Chrome, desktop, révocation | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L02 | Notifications d'ouverture des disponibilités | Tester par heure et club avec tâches différées | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L03 | Convocation, désistement, liste d'attente | Vérifier véritable changement de statut uniquement | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L04 | Changement, annulation ou report de match | Tester ciblage et deep-link sur fiche actuelle | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L05 | Composition publiée | Tester horaires, gel et préférences | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L06 | Pronostics, vote HDM et résultat | Tester limites/horaires et exclusions | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L07 | Badge débloqué | Tester une seule annonce par attribution | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L08 | Message libre administrateur et sélection destinataires | Tester périmètre, quota et contrôle admin | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L09 | Préférences individuelles et coupe-circuit club | Tester opt-out serveur sans réinscription | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L10 | Historique notifications et pastille non lue | Tester lecture, suppression, synchronisation | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L11 | Service worker, manifeste et installation PWA | Tester cache, version, session et liens profonds | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| L12 | Météo et push via tâche planifiée | Confirmer cron/secrets/accès API, surveiller erreurs | [S11](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M01 | Tableau admin comptes en attente | Tester tri, activation, refus, suppression | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M02 | Éditer membres, effectif, badges et profils | Contrôler droits RPC, journal d'actions | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M03 | Éditer matchs, saisons et paramètres | Tester effets collatéraux et validation serveur | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M04 | Envoi de notification libre | Vérifier authentification et destinataires | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M05 | Gestion du statut d'abonnement et essai 30 jours | Tester expiration, suspension, reprise, calendrier | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M06 | Prix indicatif 10 euros/joueur/an | Décision commerciale à prendre; pas de prix définitif | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M07 | Paiement, facturation et renouvellement | Aucun Stripe intégré, prévoir webhooks idempotents | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M08 | Console éditeur et opérateur de plateforme | Configurer opérateur et MFA/support sans accéder à autre club | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M09 | Quotas stockage et fichiers | Mesurer selon clubs, limiter vidéos, prévoir purge | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M10 | Sauvegarde, restauration et supervision | Configurer secrets CI, exécuter restauration test | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M11 | Journal d'incidents et support | Documenter procédures, données personnelles et alertes | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| M12 | Gestion des comptes d'un club payant suspendu | Vérifier accès aux données/export avant effacement | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N01 | Isolation par club tables PostgreSQL | Tests A/B directs sur REST/RPC, RLS et fonctions definer | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N02 | Isolation par club Storage | Tester chemins devinés et accès public des buckets | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N03 | Isolation par club Realtime et caches | Tester changement de session, connexions simultanées | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N04 | Fonctions privilégiées SECURITY DEFINER | Auditer 157 RPC exécutables par authenticated et contrôles internes | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N05 | Endpoint publics, Web Push et anti-abus | Tester secrets, signature, taux, spam et payload | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N06 | Migrations installées vs dépôt | 19 versions présentes y compris blocage live 20261112050000 | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N07 | État des Edge Functions commerciales | Huit fonctions ACTIVE; vérifier secrets et end-to-end | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N08 | Tables et migrations testées en CI | Lancer contrôles GitHub avant fusion puis reproduire sur base isolée | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N09 | Déploiement site commercial actuellement désactivé | Maintenir désactivé tant que checklist lancement non passée | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N10 | Confidentialité du dépôt et de son historique | Traiter l'historique potentiellement sensible selon fil juridique/sécurité | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N11 | Informations légales incomplètes | Compléter éditeur, SIRET, hébergeur, délais, consentement | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N12 | Compatibilité des anciennes routes, RPC et clients | Ne retirer aucune API sur simple nom 'legacy' | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N13 | Dépendances Flutter/JS et licences médias | Scanner SBOM, versions, vidéos, images et typographies | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N14 | Performance à 2, 20, 200 clubs | Tester contention, frais, cron, photos et ralentissements réels | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
| N15 | Protection antifuite profils et exports | Vérifier permissions sur compte inactif et lien deviné | [S12](M03_SCENARIOS.md) | NON EXÉCUTÉ |
