# Audit des fonctionnalités : d'AS Grinta à l'appli pour tous les clubs

Rédigé le 12/11/2026 (fil « Auditer AS Grinta pour tous les clubs »).
Sert de base au fil « Adapter l'appli pour tous les clubs ».

## Principe retenu (décision de Samih)

- **Toutes les fonctionnalités d'AS Grinta restent.** Ce qui était propre à
  AS Grinta, ce sont ses **règles** (horaires, mode de liste d'attente, mode
  live…) et son **contenu** (joueurs, historique, noms, maillots).
- Les règles deviennent des **réglages du club**, modifiables par son admin,
  avec la valeur d'AS Grinta comme valeur par défaut.
- Les fonctions optionnelles peuvent être **activées / désactivées** par l'admin.
- Le contenu d'AS Grinta est **retiré** : un nouveau club démarre vide.

## Légende

| Symbole | Sens |
|---|---|
| ✅ | Gardé tel quel : convient déjà à tous les clubs |
| 🔧 | Gardé mais adapté / réglable par club |
| ❌ | Retiré (contenu ou règle propre à AS Grinta) |

État d'avancement d'un 🔧 : **Fait** (dans `main`), **En cours** (autre fil),
**À faire**.

Méthode : lecture du code et des migrations de ce dépôt (`main` au commit
`aa5b4c7`) et comparaison avec le dépôt AS Grinta. Rien n'a été lancé ni testé
dans cet audit (voir la dernière section).

---

## 1. Comptes, inscription, rôles

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Inscription par code / lien d'invitation du club | 🔧 | Fait | Chaque club a son code, l'admin peut le changer. |
| Création d'un club (le créateur devient admin) | 🔧 | Fait | Nouveau parcours, inexistant dans AS Grinta. |
| Validation des comptes par l'admin | ✅ | — | |
| Connexion par identifiant (prénom + initiale) + mot de passe | 🔧 | **À faire** | Les identifiants sont uniques **sur toute la plateforme**, pas par club. Au-delà de 20 « Thomas D. » tous clubs confondus, l'inscription échoue (« Impossible de générer un identifiant »). Avec beaucoup de clubs, ça arrivera. Il faut soit des identifiants par club, soit passer à l'e-mail comme identifiant principal. |
| E-mail facultatif (confirmation, mot de passe oublié) | 🔧 | Fait | Ajouté pour la version commerciale. |
| Connexion Facebook | 🔧 | Fait (code) | Bouton présent ; le fournisseur Facebook n'est pas encore configuré sur la base commerciale. Pour l'App Store, « Se connecter avec Apple » deviendra obligatoire. |
| Acceptation CGU / confidentialité, déclaration d'âge (15 ans ou accord parental) | 🔧 | Fait (code) | Les textes légaux ont encore des champs à compléter (SIRET, coordonnées). |
| Téléchargement de ses données, suppression de son compte | 🔧 | Fait | Obligation RGPD. |
| Rôles : Utilisateur et Admin | ✅ | — | Suffisant pour un club test. Plus tard, un rôle intermédiaire (ex. « délégué » qui fait les compositions sans gérer les comptes) pourra être utile. |
| Attributs sportifs Coach et Gardien | ✅ | — | |
| Un compte = un joueur de l'effectif | 🔧 | Fait | AS Grinta gérait deux listes séparées ; fusionnées ici. Joueurs sans compte toujours possibles. |
| « Voir l'app comme un joueur » (aperçu admin) | ✅ | — | |

## 2. Identité du club

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Nom et nom court du club partout dans l'appli | 🔧 | Fait | Remplace « AS Grinta » écrit en dur. Notifications corrigées aussi (PR #23). |
| Logo / écusson | 🔧 | Fait | Écusson neutre par défaut. |
| Couleurs du club (l'appli s'habille aux couleurs) | 🔧 | Fait | |
| Adresse du terrain à domicile | 🔧 | Partiel | Mémorisée seulement via « retenir comme adresse par défaut » sur un match. À ajouter dans Réglages du club (utile pour la météo). |
| Nom de l'application | 🔧 | **À faire** | Provisoire « Club ». Sujet du fil direction artistique. |
| Maillots proposés pour un match | 🔧 | **À faire** | Trois dessins fixes Blanc / Orange / Bleu = les maillots d'AS Grinta. Chaque club doit pouvoir choisir ses propres maillots (couleurs, nombre). |
| Exemples dans les champs (« US Pibrac Loisirs », « Stade de Pibrac ») | 🔧 | À faire | Petits textes d'exemple locaux à rendre neutres. |

## 3. Calendrier et matchs

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Saisons (ouverture, archivage, consultation des anciennes) | ✅ | — | La saison est supposée aller de juillet à juin (bilan, historique des postes). Correct pour la France. |
| Matchs : championnat (avec journée), coupe, amical, « entre nous » | ✅ | — | |
| Événements du club (hors match) | ✅ | — | |
| Heure de rendez-vous avant le match | ✅ | — | |
| Fenêtre « Prochain match » à J-6 12 h | 🔧 | Fait | Réglable (jours + heure). |
| Suppression d'un match (fenêtre limitée) | ✅ | — | |
| Abonnement agenda (lien .ics) | ✅ | — | Petit reste : l'identifiant interne des événements contient « sporteasy-grinta » (nom d'un concurrent). Invisible pour l'utilisateur mais à neutraliser. |
| Bibliothèque « Équipes & stades » (adversaires, adresses) | ✅ | — | Vide pour un nouveau club. |
| Historique des saisons passées | 🔧 | **En cours** | L'historique importé d'AS Grinta est retiré. Une saisie simple de matchs passés par l'admin est en cours dans le fil « Ajouter listes d'attente et saisie d'historique ». |
| Fuseau horaire | 🔧 | **À faire (non bloquant)** | « Europe/Paris » écrit en dur (~50 endroits côté base, quelques-uns dans l'appli). Sans effet pour France métropolitaine, Belgique, Suisse, Luxembourg. Bloquant seulement pour un club des DOM-TOM ou hors Europe. |

## 4. Disponibilités, effectif, liste d'attente

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Disponibilités (présent / absent) | ✅ | — | |
| Ouverture des disponibilités (J-6 12 h par défaut, l'admin peut avancer ou retarder par match) | 🔧 | Fait | Réglable par club. |
| Indisponibilités déclarées à l'avance | ✅ | — | |
| Nombre de convoqués (14 chez AS Grinta) | 🔧 | Partiel | Modifiable match par match ; la valeur par défaut du club (14) n'a **pas d'écran** pour la changer. À ajouter dans Réglages du club. |
| Liste d'attente : mode de tri | 🔧 | **En cours** | AS Grinta = « par présence l'an dernier ». Trois modes au choix (choix de l'admin / ordre d'arrivée / présence) en cours dans l'autre fil. |
| Liste d'attente : heure limite (J-1 12 h) | 🔧 | Fait | Réglable. |
| Invités de match (sans compte) | ✅ | — | |
| Effectif et composition gelés à T-15 | 🔧 | Fait | Suit la règle « fermeture des pronostics » (réglable). |
| Activer / désactiver la gestion sportive (dispos, convocations, compo) | 🔧 | À décider | Toujours active aujourd'hui. Un club qui ne veut que les pronos et les stats ne peut pas la couper. Pas prioritaire. |

## 5. Composition

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Composition sur terrain, 26 dispositifs | 🔧 | **À faire (décision)** | Tous les dispositifs sont du **foot à 11**. Un club de foot à 7, à 8 (jeunes) ou futsal ne peut pas faire sa compo. Les matchs « entre nous » gèrent déjà de 1 à 11 joueurs : la base existe. À rendre réglable : « format de jeu du club » (11 / 8 / 7 / 5). |
| Dispositif par défaut (4-2-1-3) | 🔧 | À faire | Préférence d'AS Grinta ; à rendre réglable ou à dériver du format. |
| Simulation automatique d'un onze | ✅ | — | Les postes de référence se construisent depuis les matchs du club (profils AS Grinta retirés). |
| Présentation animée de la compo (vidéo du stade) | ✅ | — | Textes AS Grinta déjà retirés de la vidéo (PR #11). Origine de la vidéo à confirmer côté droits (fil juridique). |
| Matchs « entre nous » (deux équipes internes) | ✅ | — | |

## 6. Mode live

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Live : chrono, buts + passeurs, remplacements, temps de jeu | ✅ | — | |
| Activer / désactiver le live | 🔧 | Fait | Coupé dans l'appli **et** refusé par le serveur. |
| Ouverture du live à T-15 | 🔧 | Fait | Même réglage que la fermeture des pronostics. Pourrait être séparé si un club le demande. |
| Pilotage du live par le coach | ✅ | — | |
| Alertes de but aux joueurs | ✅ | — | Suivent l'interrupteur du live. |

## 7. Après le match

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Compte rendu validé (score, buteurs, passeurs, présences) | ✅ | — | |
| Délai de correction du résultat (24 h) | 🔧 | Fait | Réglable. |
| Vote Homme du match (anonyme) | 🔧 | Fait | Activable / désactivable, durée réglable, refusé par le serveur si coupé. |
| Nom « Homme du match » | 🔧 | **À faire** | Écrit en dur (~36 endroits). Inadapté à une équipe féminine ou mixte. À rendre neutre ou réglable (ex. « Joueur·se du match », « MVP »). Même remarque pour quelques badges (« Monsieur Présent », « Monsieur Victoire »). |

## 8. Pronostics

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Pronostics de score et classement | 🔧 | Fait | Activable / désactivable, refusé par le serveur si coupé. Fermeture réglable (T-15). |
| Cotes calculées automatiquement (historique contre l'adversaire + forme) | ✅ | — | Pour un club neuf sans historique, les cotes seront neutres au début : normal, à expliquer dans l'aide. |
| Barème (score exact ×2, bon écart ×1,5…) | ✅ | — | Gardé identique pour tous. Réglable plus tard si demandé. |
| Rappel de prono le jour du match à 16 h | 🔧 | Fait | Heure réglable. |
| Multiplicateur ×2 / portefeuille | ❌ | Déjà retiré | Déjà absent d'AS Grinta ; il en reste des traces techniques sans effet. |

## 9. Statistiques et fiches joueurs

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Stats équipe et joueurs (buts, passes, clean sheets, matchs, HDM) | 🔧 | Fait | Activable / désactivable (masqué dans l'appli seulement, sans risque). |
| Classements, saison en cours / précédente / toutes saisons | ✅ | — | |
| Fiche joueur, photos | ✅ | — | Photos cloisonnées par club. |

## 10. Badges

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Badges automatiques (65 modèles) et manuels, armoire | 🔧 | Fait | Gestion ouverte à tout admin (AS Grinta : deux comptes précis). Activable / désactivable. |
| Noms des badges | 🔧 | Partiel | Noms protégés ou internes remplacés (« Ballon d'or », « Mobutu », « Traître »…). Il reste des noms genrés (voir § 7). Refonte visuelle complète : fil direction artistique. |
| Images des badges | 🔧 | Fait | Aucune image d'AS Grinta livrée ; chaque club peut mettre les siennes. |
| Seuils des badges (ex. 30 matchs dans la saison) | ✅ | — | Pensés pour une saison d'environ 25-30 matchs. Un club qui joue peu en débloquera moins : acceptable, réglable plus tard. |

## 11. Bilan de fin de saison

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Bilan personnel animé, partageable | 🔧 | Fait | Activable / désactivable. Pas de musique livrée. Le mot « Wrapped » (associé à Spotify) est utilisé en interne ; vérifier qu'il n'apparaît pas à l'écran (fil juridique / DA). |

## 12. Notifications

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Ouverture des dispos, match annulé / déplacé, liste d'attente, convocation | ✅ | — | Suivent les réglages d'horaires du club. |
| Rappel prono, vote HDM et résultat, compo en ligne, badge, changement de dispo (admins) | ✅ | — | Chaque joueur règle les siennes. |
| Message libre de l'admin à tout ou partie du club | ✅ | — | |
| Nom du club dans les notifications | 🔧 | Fait | PR #23. |
| Coupe-circuit des notifications | 🔧 | Fait | Propre à chaque club. |
| Notifications sur téléphone (web push) | ✅ | À tester | Jamais testées sur la base commerciale. Sur iPhone, l'appli doit être ajoutée à l'écran d'accueil. |

## 13. Météo

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Météo du match (Open-Meteo, gratuit) | 🔧 | Fait | Activable / désactivable (masquée dans l'appli ; le serveur continue de la calculer, sans coût). Dépend de l'adresse du terrain (voir § 2). |

## 14. Administration du club

| Fonction | Classement | État | Détail |
|---|---|---|---|
| Réglages du club : identité, logo, couleurs, invitation, fonctionnalités, règles | 🔧 | Fait | Nouvel écran. À compléter : nombre de convoqués par défaut, adresse du terrain, format de jeu, maillots, mode de liste d'attente (en cours). |
| Comptes, comptes en attente, effectif, saison | ✅ | — | |
| Gestion des badges | 🔧 | Fait | |
| Abonnement du club (essai 30 jours, rappel, suspension par l'éditeur) | 🔧 | Fait (sans paiement) | Prix 10 €/joueur/an non validé ; paiement en ligne non branché. |
| Console de l'éditeur (Samih) | 🔧 | Fait | Compte éditeur pas encore déclaré sur la base commerciale. |

---

## Ce qui est retiré

Aucune **fonctionnalité** n'est retirée. Seul le contenu ou les règles propres à
AS Grinta le sont :

| Élément retiré | État |
|---|---|
| Comptes, joueurs, matchs, historique et stats d'AS Grinta | Fait (base neuve vide) |
| Postes de référence des joueurs d'AS Grinta | Fait |
| Droits de gestion des badges réservés à deux comptes | Fait |
| Noms de badges internes ou protégés | Fait |
| Photos de maillots à logos, textes du club dans la vidéo du stade | Fait |
| Lien et adresses vers le site AS Grinta (agenda, notifications) | Fait |
| Multiplicateur ×2 | Déjà absent d'AS Grinta |
| Trois maillots fixes aux couleurs d'AS Grinta | **À faire** (§ 2) |
| Dispositif par défaut d'AS Grinta | **À faire** (§ 5) |
| Exemples « Pibrac », identifiant d'agenda « sporteasy-grinta » | **À faire** |

Les noms techniques contenant « grinta » dans le code (ex. colonne
`score_as_grinta`) restent volontairement : invisibles pour les clubs, les
renommer serait risqué pour un gain nul.

## Limites de fond (décisions de produit)

1. **Un espace = une seule équipe.** La base n'a pas de notion d'« équipe »
   dans un club. Un vrai club avec équipe A, B, vétérans, jeunes devra créer un
   espace par équipe (chacun avec son abonnement). Recommandation : garder
   ainsi pour le club test et les premiers clubs (cible naturelle : équipes
   loisirs / vétérans / foot entre amis, comme AS Grinta) ; ajouter plusieurs
   équipes par club seulement si la demande est réelle, car c'est un gros
   chantier.
2. **Foot à 11 uniquement** pour les compositions officielles (§ 5).
   Recommandation : ajouter le réglage « format de jeu » avant de démarcher
   des clubs de foot à 7 ou à 5.
3. **Identifiants uniques sur toute la plateforme** (§ 1). Recommandation :
   à corriger avant d'avoir plusieurs dizaines de clubs.
4. **Vocabulaire masculin** (« Homme du match », certains badges) (§ 7).
5. **Fuseau horaire de Paris** (§ 3). Non bloquant en France.
6. **Français uniquement**, prix en euros. Suffisant pour la cible actuelle.

## Liste de travail proposée pour le fil « Adapter l'appli »

**Avant le club test**
1. Réglage « nombre de convoqués par défaut » dans Réglages du club.
2. Réglage « adresse du terrain à domicile » dans Réglages du club.
3. Maillots du club définis par l'admin (couleurs) au lieu des trois maillots fixes.
4. Neutraliser « Homme du match » et les badges genrés (en lien avec le fil DA pour le nom retenu).
5. Exemples « Pibrac » et identifiant d'agenda « sporteasy-grinta » neutralisés.
6. Finir la liste d'attente 3 modes et la saisie d'historique (fil en cours).

**Avant d'ouvrir à plusieurs clubs**
7. Identifiants par club ou connexion par e-mail (limite des 20 homonymes).
8. Format de jeu du club (11 / 8 / 7 / 5) avec les dispositifs correspondants et un dispositif par défaut réglable.
9. Connexion Apple si publication sur l'App Store.

**Plus tard, si un club le demande**
10. Fuseau horaire par club.
11. Plusieurs équipes dans un même club.
12. Rôle intermédiaire (délégué), barème des pronos et seuils de badges réglables, interrupteur de la gestion sportive.

## Ce qui n'a pas été vérifié

- Cet audit est une **lecture du code**. Aucune fonction n'a été lancée, ni dans
  l'appli ni sur la base commerciale. Le bon fonctionnement réel de chaque
  fonction relève du fil « Vérifier chaque fonctionnalité et ses limites ».
- La production AS Grinta n'a **pas** été consultée (règle : ne pas y toucher).
  Si une fonction existe en production sans être dans le code copié le
  10/11/2026, elle n'apparaît pas ici.
- Le cloisonnement entre clubs est supposé correct d'après les travaux
  précédents (tests de charge 200 clubs) ; sa vérification sur la vraie base
  relève du fil sécurité.
