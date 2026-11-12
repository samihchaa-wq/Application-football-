# Mission 08 — Kit d'exécution des séances pilotes (sans données réelles)

> **12/11/2026 — Modèles prêts à utiliser, aucune séance exécutée.**
> Source du plan : [PILOTE_CLUBS_UX.md](PILOTE_CLUBS_UX.md).
> Coordination : [Mission 00 / CHANTIER.md — PR #29](https://github.com/samihchaa-wq/Application-football-/pull/29), [mission 01 — PR #25](https://github.com/samihchaa-wq/Application-football-/pull/25), [mission 03 — PR #26](https://github.com/samihchaa-wq/Application-football-/pull/26).
> Ce document ne remplace **ni** les validations E2E du fil 03 **ni** les contrôles de séparation A/B du fil 04. Il sert uniquement à préparer, observer et comparer l'autonomie réelle des utilisateurs.

## 1. État des prérequis et propriétaires

| Sujet | Responsable | Situation au 12/11 | Porte concernée |
| --- | --- | --- | --- |
| Diffusion du site commercial | Fil 00 / 03 / 04 | PR #24 de réactivation Pages ouverte ; **aucun lancement confirmé ici** | G0 |
| Configuration Auth, redirections, e-mails | Fil 03 / 04 | Connexion et récupération réelles non validées | G0 |
| Base commerciale / isolation A-B / Storage / fonctions privilégiées | Fil 04 + 03 | Tests locaux et lecture de schéma ne sont pas des E2E commerciaux ; **preuve distante manquante** | G1 |
| Sécurité des données dans le dépôt GitHub public | Fil 04 / 07 / 00 | Risque soulevé dans CHANTIER.md ; remédiation non constatée | G0 |
| Identité neutre et droits des médias | Fil 05 / 07 | Contrôle à obtenir avant équipes externes | G2 |
| Mentions, information et consentement pilote | Fil 07 | Non validés dans ce fil | G2 |
| Support et traitement des incidents | Fil 09 | Canal et engagement à définir | G2 |
| Recrutement d'équipes et conditions de test | Fil 06 / propriétaire | Aucun club contacté ; accord préalable nécessaire | G2 |
| Parcours découverte → premier match | Fil 08 (UX), fil 03 (technique) | Reconstitué depuis le code ; **jamais observé** | G1 puis G2 |

**Aucun statut ci-dessus ne permet d'affirmer que le lancement est autorisé.** Les PR #24, #25, #26, #29 et #30 ne sont pas nécessairement fusionnées ; relire leur état au moment de l'exécution.

## 2. Programme des observations

**Préparation fictive :** clubs A/B distincts ; 1 administrateur et 6–8 joueurs fictifs par club, selon accord écrit du propriétaire pour toute création sur Supabase commerciale. Les tests de sécurité interclubs appartiennent aux fils 03/04 ; le fil 08 reçoit leurs résultats et n'essaie pas de contourner leurs gardes.

**Pilote réel proposé après G1 :** 3 équipes de football à 11, 15–30 membres chacune ; par club, observer au minimum 1 administrateur responsable et 5 joueurs consentants (dont si possible une personne peu familière des applications de club). Le suppléant admin sert à tester la reprise, sans lui imposer un rôle absent du produit. Prévoir des utilisateurs Android, iOS et navigateur ; ne pas multiplier les variantes si le cadre légal et la capacité de support ne le permettent pas.

### Séance A — Première découverte administrateur (30 à 45 min ; non réalisée)

Consigne identique pour tous : « Vous découvrez cette application et souhaitez gérer votre équipe. Créez votre club, ouvrez une saison, invitez un membre et programmez un match amical. À chaque étape, agissez comme vous le feriez seul chez vous. »

L'observateur ne décrit **aucun chemin de menu** à l'avance. Il peut relancer par « Que chercheriez-vous maintenant ? », mais consigne comme **aide** toute indication du bouton ou de l'écran à utiliser. Arrêter la séance en cas de problème de sécurité, de données tierces visibles ou de collecte non autorisée.

Étapes observées :
1. Identifier spontanément « Créer mon compte » puis « Créer un club ».
2. Compléter le formulaire, comprendre les consentements, noter et retrouver l'identifiant attribué.
3. Se reconnecter, dire à voix haute ce qui doit être fait en premier sur un club vide.
4. Trouver « Réglages du club » et reconnaître les réglages sans forcément tout changer.
5. Créer une saison ; comprendre les notions de saison ouverte et d'effectif.
6. Copier et partager le lien d'invitation vers un canal de test approuvé, sans l'exposer publiquement.
7. Créer l'adversaire et programmer le premier amical ; vérifier l'affichage sur le calendrier.

**Échec UX** : une étape obligatoire reste introuvable après deux tentatives spontanées, l'observateur doit guider l'utilisateur, ou l'utilisateur pense avoir terminé alors que la donnée n'a pas été enregistrée. Un échec technique (API indisponible) est classé séparément ; les deux peuvent coexister.

### Séance B — Première découverte joueur (15 à 25 min ; non réalisée)

Consigne : « Vous recevez un lien du club. Inscrivez-vous, puis trouvez le prochain match et indiquez si vous serez présent. »

Observer : ouverture du lien et code, compréhension de l'attente de validation, retour après activation, lecture du prochain match, réponse de disponibilité, reconnexion, visibilité des modules activés. **Ne pas demander** l'accès au compte d'un autre utilisateur. Mesurer les difficultés liées au choix PWA/notifs à part, pour ne pas transformer une restriction OS en faute de l'utilisateur.

### Séance C — Après le vrai premier match (15 min ; non réalisée)

Demander à l'administrateur de retrouver le match passé, renseigner le résultat et vérifier que les membres trouvent les informations prévues ; analyser les fonctions réellement activées. Ne pas exiger qu'un club teste le Live ou les pronostics s'il ne souhaite pas les utiliser. Noter les interruptions, corrections du résultat et besoin d'aide extérieure.

## 3. Table de correspondance intermissions

**Txx** = scénario de la mission 08 dans PILOTE_CLUBS_UX ; **Fxx** = périmètre de la matrice QA de la mission 03 (PR #26) ; **A/B/C** = familles du registre détaillé de mission 01 (PR #25). Ces correspondances concernent les **objectifs de vérification**, pas des tests hérités ni des résultats.

| Mission 08 | Mission 03 (à faire valider techniquement) | Mission 01 (fonction soumise à examen UX) | Indicateur UX complémentaire |
| --- | --- | --- | --- |
| T01 création/reconnexion | F01, F02 | A01, A05, A06 | Temps et autonomie |
| T02 interruption, erreurs et récupération | F02, F31 | A08, A09 | Compréhension du message et reprise |
| T03 identité/modules du club | F05, F06 | B01, B02, B03, B07, B08 | Trouvabilité des réglages |
| T04 saison et effectif | F07, F11 | C01, C03, C04 | Ordre des actions compris |
| T05 inscription invitée / validation admin | F01, F02, F03 | A02, A04 | Attente comprise par les deux rôles |
| T06 code invalide/renouvelé | F01, F02 | A02, A03 | Capacité à corriger seul |
| T07 premier match | F08, F19 | D01, D03, D04, H04 | Temps et champs bloquants |
| T08 disponibilité | F10, F11 | E01, E02, E06 | Taux d'action sans aide |
| T09 lien agenda/pronos | F09, F19 | D08, H01, H04 | Repérage de la fonctionnalité |
| T10 notifications et PWA | F24, F30 | L01, L11 | Compréhension de la permission |
| T11 clôture | F17, F18, F20 | G09, G10, G11 | Clôture sans intervention |
| T12 A/B | F03, F04 | A02, A17 | **Contrôle de sécurité fil 04, pas une séance UX** |
| T13 profils/permissions | F03, F27 | A04, A16, M01 | Messages adaptés au rôle |
| T14 appareil et reconnexion | F30, F31 | A06, A15, L11 | Reprise des actions |
| T15 accessibilité mobile | F34 | B03, L11 | Lisibilité, navigation clavier/tactile |
| T16 deux administrateurs | F08, F27, F31 | C11, M03 | Confirmation claire des conflits |
| T17 modules désactivés | F06, F16 | B08, B09, G01, H08 | Compréhension des conséquences |
| T18 sans e-mail | F02 | A08, A09 | Compréhension de la récupération |

**Note au fil 00 :** aucun Txx n'est encore une preuve d'essai. Le fil 08 transmet au fil 03 une demande de validation via les identifiants Fxx et aux fils 02/05 les frictions **observées**, pas les hypothèses initiales.

## 4. Modèle réutilisable pour une séance — ne pas saisir de noms réels dans GitHub

```text
FICHE OBSERVATION UX — PILOT-OBS-____
Date : ____  Version/commit : ____
Environnement : LOCAL FICTIF / COMMERCIAL FICTIF AUTORISÉ / PILOTE RÉEL AUTORISÉ
Club pseudonymisé : PIL-__  Rôle : ADMIN / JOUEUR
Appareil et navigateur (sans identifiants uniques) : ____
Consentement/notice pilote confirmés : OUI / NON → STOP
Scénario Txx : ____
Début / fin (durée calculée manuellement) : ____
Réussite sans aide : OUI / NON
Aide de l'observateur : AUCUNE / INDICE GÉNÉRAL / CHEMIN DE MENU / ACTION FAITE À SA PLACE
Tâche réellement enregistrée : OUI / NON / NON VÉRIFIÉ
Hésitations observables (sans données personnelles) : ____
Erreur / message / blocage : ____
ID incident associé (si nécessaire) : ____
Verbatim anonyme facultatif, avec accord : ____
Proposition de correction ? FAIT OBSERVÉ / HYPOTHÈSE / PRÉFÉRENCE
```

### Séparer les quatre statuts d'une anomalie

1. **Hypothèse** : seule la lecture du code indique un risque.
2. **Observée** : une personne a rencontré la difficulté, sans reproduction indépendante.
3. **Reproduite** : le fil 03 ou 04 a validé les étapes et l'état technique.
4. **Corrigée et revalidée** : preuve du fix technique, puis nouvelle séance UX sans guidage.

Ne jamais qualifier une hypothèse de « bug confirmé ». Pour les suggestions, compter la diversité des clubs, pas seulement la répétition par une même personne.

## 5. Gabarit de transmission au fil 00 — à utiliser lors de chaque jalon

```text
MISSION : 08 — Clubs pilotes et UX
LIVRABLE / PR : ____________
STATUT : DOCUMENTÉ / TEST TECHNIQUE / TEST RÉEL / BLOQUÉ
PREUVE : URL GitHub + SHA + scénario Txx + résultat
TESTS EFFECTUÉS : __ (séparer de tests CI effectués par d'autres fils)
INCIDENTS : ID + P0/P1/P2/P3 ; hypothèse ou reproduit
RISQUES / DÉPENDANCES : fil responsable, PR attendue
PROCHAINE ACTION : ____________
DÉCISION PROPRIÉTAIRE REQUISE : oui/non, formulation exacte
COÛT : aucun / estimation à approuver explicitement
```

## 6. Décisions non déléguées et conditions d'arrêt

- **Accord du propriétaire obligatoire** pour créer deux clubs fictifs et leurs comptes sur la base commerciale, utiliser des boîtes de test, déclencher des notifications, réactiver un déploiement ou contacter une équipe réelle.
- **Accord du propriétaire et avis des fils 06/07** avant toute campagne, recueil d'informations de vrais membres, incitation commerciale, publication de témoignage ou paiement.
- Arrêt ou non-ouverture du pilote si RLS/Storage/A-B non validés, si dossier contenant des données anciennes publiquement accessible sans décision, si Auth/e-mail échouent sur les parcours requis, si sauvegarde/restauration ou signalement d'incident sont absents.
- Le fil 00 **coordonne**, mais n'accorde pas à lui seul un consentement du propriétaire que celui-ci n'a pas donné ; il peut centraliser la demande.
- Revenir à un pilote gratuit limité uniquement après feux verts nécessaires. Le passage aux clubs payants requiert une décision distincte, écrite et informée.

## 7. Journal des séances

| Séance / club pseudonymisé | Date | Scénarios | Réalisé ? | Preuve | Décision |
| --- | --- | --- | --- | --- | --- |
| Préparation A/B | — | T01–T18 selon responsabilités | **Non** | Aucune | Accès / accord préalable |
| Pilote A | — | A/B/C | **Non** | Aucune | Attendre G1 |
| Pilote B | — | A/B/C | **Non** | Aucune | Attendre résultat A |
| Pilote C | — | A/B/C | **Non** | Aucune | Attendre résultat B |

**Aucune métrique fictive ne sera mélangée à des résultats réels.** Le premier rapport d'observation ne peut être complété qu'après séances et autorisations effectives.
