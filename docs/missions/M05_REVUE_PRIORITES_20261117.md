# M05 — Revue UX prioritaire : Homme du match et inscription

## Sources, portée et verdict

Revue du 17/11/2026 : PR #178 au SHA `21c574d5069261a6b1e44291a66815194bb558db`, base main `4ac75c14d077bc2bf8bc6e3278023d0db8948932`, issue #160 et commentaires M00/M03. AGENTS, HANDOFF et CHANTIER déjà lus ; leurs anciennes décisions ne prévalent pas sur #160. Original AS Grinta et Carte soirée exclus. Branche UX empilée sur #178 : ne pas intégrer indépendamment de cette dépendance.

**Verdict : remplacement présent dans les sources examinées ; absence de régression visuelle complète non démontrée. #160 reste non livré côté client/serveur.** Cette PR prépare un panneau de confirmation réutilisable et le contrat UX, sans ouvrir de route ni simuler une validation de compte. M02 branche les états réels avec M04. Aucun changement aux identifiants historiques, règles de vote, résultats, RPC, migrations ou données.

## Preuves effectivement obtenues

| Contrôle | Résultat et portée exacte |
| --- | --- |
| Inspection diff #178 | 46 fichiers, sources UI/serveur et tests ; aucun média binaire de badge, son ou vidéo changé. Les modifications de libellés n'établissent pas à elles seules la stabilité de leur rendu. |
| Recherche active | `rg -n -i 'étoile.{0,15}match\|etoile.{0,15}match\|étoiles.{0,15}match' lib assets web supabase/functions test` : aucun résultat sur le SHA audité (regex exécutée avec alternatives). Les étoiles décoratives demeurent dans les composants de badges. |
| CI #178 | Flutter 44083530503, SQL/RLS 44083530644, HTTP JWT 44083530572, restauration synthétique 44083530614, runtime 44083530410 et garde 44083530259 observés réussis sur 21c574d. Charge 44083530426 encore en cours lors du relevé. Pas une preuve de réception push ou de rendu sur téléphone. |
| Vérification locale du correctif UX | Formatage Dart SDK 3.13.7 exécuté en langage 3.4 ; avertissement flutter_lints non résolu. `git diff --check` exécuté. |
| Exécution Flutter locale | SDK retrouvé, lancement tenté : attente du verrou puis construction de l'outil et résolution de dépendances. Aucun résultat d'analyse/test/build obtenu au moment de ce rapport. Les tests ajoutés restent NON VALIDÉS jusqu'à CI du nouveau SHA. |
| Captures | **Aucune capture de l'application ou du panneau obtenue dans ce lot. Aucun test sur iPhone/Android physique, lecteur d'écran ou boîte mail.** Pas de maquette présentée comme preuve de rendu Flutter. |

Les historiques immuables SQL/docs et noms techniques `etoile_du_match`, `mvp`, `motm`, `club_id` ne sont pas des libellés actifs à renommer globalement.

## Audit des surfaces Homme du match

| Surface | Inspection de code | Contrôle restant / correction |
| --- | --- | --- |
| Fiche match et invitation au vote | `match_details_page.dart`, `match_detail_header_card.dart` : texte complet dans Flexible, sans limite de lignes pour l'action | Cible compacte seulement 2 px de padding vertical : **corrigée à une hauteur minimale de 48 px**. Tests ajoutés 320/360/390/768 px, libellé non ellipsé et callback, à exécuter. |
| Vote, états ouvert/enregistré/fermé/annulé | `sport_motm_vote_page.dart` : titre et états renommés | Accord incorrect « attribuée » **corrigé** ; résultat multiple « Hommes du match ex æquo ». Très longs noms de candidats et texte agrandi : à rejouer. |
| Composition terminée / historique | `completed_match_composition_card.dart`, `history_entry_page.dart` : libellés et explication de couronne renommés | Vérifier formulaire historique et liste des contributions, 0/1/plusieurs élus. La couronne reste préservée. |
| Statistiques et profil | `player_stat_ranking.dart`, `player_card_repository.dart`, `player_card_matches.dart` | Tooltip « Homme du match » présent ; cellules et noms longs à mesurer. Ne pas déduire que l'ellipsis du nom du joueur tronque le tooltip du trophée. |
| Badges et armoire | `badge_descriptor.dart` : métriques mvp/title_mvp_king inchangées, socle « HDM » saison/carrière ; noms fournis aussi par serveur | L'abréviation économise l'espace mais doit être explicitée par nom/description du badge. Examiner lecteur d'écran, petit emblème et badge personnalisé. Étoiles de palmarès conservées. |
| Saison / animations | `season_wrapped_repository.dart`, `wrapped_slides.dart` : nouveau libellé ; FittedBox/limites de lignes dans le composant | Les FittedBox peuvent réduire le texte : absence de débordement ne prouve pas lisibilité. Rejouer avec texte 200 %, préférences de réduction du mouvement et longues listes ; vérifier son facultatif. |
| Réglages et administration | `ClubModule.manOfTheMatch`, libellés serveur, formulaire d'archives | Interfaces alimentées par règles/RPC : lecture serveur effective requise après migration, pas uniquement recherche Dart. |
| Notifications | Préférences, choix de tests et historique système traités par #178 | Push OS susceptibles d'être tronqués selon navigateur ; message complet doit rester consultable dans l'historique. Aucun envoi réel réalisé. Action « Envoyer une notification » déjà ellipsée dans un autre bouton : dette existante, pas causée par le renommage. |

### Migration SQL #178 : portée UX et réserves à M02/M03

Migration additive `20261122000001_homme_du_match_partout.sql` : traduction des noms/descriptions de badges et templates, titres/corps des trois kinds HDM de l'historique système ; pas de réécriture des messages libres d'administrateurs ni nouvel envoi. OID, ACL, propriétaire, SECURITY DEFINER et configuration sont contrôlés lors du remplacement des définitions. Cette inspection et la CI SQL ne prouvent pas l'état distant.

**Accord restant côté SQL à corriger par le propriétaire de #178** : la substitution « Aucune Étoile du match collective » → « Aucun Homme du match collectif » conserve le suffixe ancien « n’est attribuée » lorsqu'il est présent dans le texte source (ancien helper 20261112150000). La correction Flutter de cette PR ne corrige pas ce chemin serveur. Ajouter un cas complet de remplacement et son test dans une nouvelle révision de #178 avant intégration, sans réécrire les migrations anciennes.

Vérifier après migration, dans environnement isolé : ancien badge → nouveau nom, futurs templates, notification HDM historique → texte actuel, message libre identique, attribution/ex æquo/candidats et compteurs inchangés. Tester aussi client plus ancien contre serveur renommé et reprise du cache. Les historiques copiés librement, captures anciennes, caches et push déjà reçus ne peuvent être corrigés par un simple renommage client.

## Corrections ciblées de la PR UX

1. Accord et résultats multiples ; cible vote de 48 px dans la fiche match.
2. Connexion et récupération : « équipe » dans les deux textes qui mentionnaient encore le club.
3. `EmailVerificationPanel` : composant de présentation prêt à brancher par M02, sans appel réseau ni accord de droits ; six états (attente, envoi, envoyé, échec, expiré, attente admin), e-mail sélectionnable, renvoi limité par état serveur, correction d'adresse et annonce liveRegion.
4. Tests ajoutés : quatre largeurs pour l'action HDM ; huit combinaisons largeur × taille de texte couvrant les six états e-mail ; callbacks et renvoi désactivé pendant délai serveur. Ce ne sont pas des tests E2E.

Des textes historiques « club » restent notamment dans auth_register_page, choose_club_page et consent_fields, ainsi que les écrans de réglages : inventaire à résorber par M02 lors du changement #160 et dans un lot séparé pour le reste de l'app. Aucun nouveau libellé de ce lot ne parle de club. Les routes et champs techniques sont conservés. Ne pas transformer automatiquement une clé ou route en texte « équipe ».

## Contrat d'interface #160 prêt pour M02

Réutiliser thème sombre, cartes, espacements et GrintaAuthSurface. Une colonne, largeur maximale 460 px, formulaire défilant, actions principales pleine largeur, saisies préservées en cas d'échec, pas de progression fictive ni d'inscription présentée comme finie avant accord serveur.

| Écran / état | Contenu exact proposé | Actions et comportement |
| --- | --- | --- |
| Entrée | « Rejoindre une équipe » / « Créer une équipe » | Invitation préremplie si disponible ; code non perdu lors d'un retour. |
| Compte | « Prénom », « Nom », « Adresse e-mail », « Date de naissance », « Mot de passe », « Confirmer le mot de passe » | Indiquer « Tous ces champs sont obligatoires ». E-mail : clavier email, autofill, sans correction automatique ; mot de passe : affichage réversible accessible et gestionnaire de mots de passe. |
| Aide e-mail | « Utilise une adresse que tu peux consulter. Un lien permettra de la confirmer. » | Ne pas confondre identifiant de connexion et adresse. Aucun domaine technique montré. |
| Naissance | « JJ/MM/AAAA » ; « Les équipes pilotes accueillent uniquement des personnes de 18 ans ou plus. » | Saisie clavier et calendrier accessibles ; aucune date par défaut réputée acceptée. Valider date réelle/future/âge, puis serveur autoritaire. La date complète reste privée. |
| Erreurs de champ | « Saisis une adresse e-mail valide. » / « Saisis une date de naissance valide au format JJ/MM/AAAA. » / « Tu dois avoir au moins 18 ans pour participer à cette phase pilote. » | Message lié au champ ; focus sur la première erreur ; pas seulement SnackBar ou couleur. Conserver les champs non sensibles, ne pas journaliser naissance/e-mail. |
| Consentements | « J’accepte les conditions d’utilisation » ; créateur : « Je suis autorisé à engager cette équipe et j’accepte les conditions d’abonnement. » | Cases distinctes, non précochées, liens légaux accessibles ; retirer l'ancien choix 15 ans, pas de consentement marketing imposé. M07 valide les textes définitifs. |
| Soumission | « Créer mon compte » / « Créer mon équipe » puis « Création en cours… » | Un seul envoi ; erreur réseau récupérable et idempotence ; pas de redirection métier tant que le serveur refuse l'accès. |
| Après création | « Confirme ton adresse e-mail » + adresse réelle sélectionnable et identifiant copiable | Si échec d'envoi, dire « Ton compte est créé, mais l’envoi du lien a échoué. » ; ne pas affirmer que le courriel a été envoyé. Garder accès aide/légal/déconnexion. |
| Attente e-mail | Panneau livré : instruction d'ouvrir le lien, vérifier indésirables | « Renvoyer le lien », « Corriger mon adresse e-mail », « J’ai confirmé mon adresse » (rafraîchissement serveur par écran parent) ; aucun de ces boutons ne valide localement le compte. |
| Correction | « Corriger mon adresse e-mail » et « Enregistrer et envoyer un lien » | Afficher l'adresse actuelle, préserver le brouillon en cas d'erreur. Changement confirmé par serveur ; anciens liens invalidés selon contrat M02/M04. Ne jamais exposer l'existence d'un autre compte. |
| Renvoi | « Envoi en cours… », puis « Un nouveau lien a été envoyé. Utilise le plus récent. » ou échec explicite | Délai « Renvoyer dans N s » fourni par serveur ; pas de timer contournant le rate limit. Correction reste disponible hors envoi ; pas de compte à rebours annoncé chaque seconde au lecteur d'écran. |
| Lien expiré/invalide | « Ce lien a expiré ou a déjà été utilisé. Demande un nouveau lien. » | Diriger vers connexion puis étape de confirmation, pas vers profil métier interdit. L'état déjà confirmé doit être distingué par serveur et présenté comme tel. |
| Lien correct | « Adresse confirmée » | Si session absente : « Se connecter » ; si autre compte connecté : ne pas changer son équipe/rôle. Actualiser les droits serveur. |
| Approbation admin restante | « En attente de l’équipe » ; « Ton adresse est confirmée. Un administrateur doit encore accepter ton arrivée dans l’équipe. » | Rafraîchir le statut, déconnexion et aide ; ne pas reproposer la confirmation e-mail déjà effectuée. Fondateur : suivre le résultat serveur sans inventer une approbation par un administrateur inexistant. |

M02 doit conserver les comptes historiques ; un refus d'accès doit distinguer manque de confirmation et approbation en attente. Éviter d'exposer les coordonnées de l'administrateur pour expliquer l'attente. `ConfirmEmailPage` actuel renvoie vers profil après lien invalide et explique seulement la récupération : ces textes/actions sont à adapter avec le garde de routes #160.

### Matrice de recette à exécuter avant validation UX

- 320, 360, 390, 768 px ; portrait/paysage ; texte 100/200 % ; petit écran avec clavier visible et dernier champ/action atteignables.
- Clavier : ordre logique, entrée/suivant, focus visible, premier champ invalide, pas de piège ; VoiceOver/TalkBack : labels, requis, erreurs, sélection et états annoncés une fois.
- Confirmations même/autre appareil, session absente/expirée, lien expiré/réutilisé, correction erronée, panne réseau, renvoi limité/double clic, attente admin et comptes existants.
- Deux équipes fictives dans une stack isolée pour le test E2E ; aucune API métier accessible avant confirmation via UI ou requête directe. M03/M04 possèdent cette preuve.
- HDM : ouvert, voté, fermé, aucun vote, plusieurs élus, invités, module désactivé, ancienne saison ; notifications longues et historique. Tester badges/animation à leurs tailles réelles et réduction des animations.

Chaque résultat doit porter SHA, appareil/viewport, OS, type de test (simulé ou réel), attendu/obtenu et preuve expurgée. Aucun succès supposé faute de capture. **Aucun GO pilote issu de cette revue.**

## Transmission

M02 : brancher le panneau et le contrat #160 avec contrôles serveur ; reprendre les copies « équipe » dans les écrans réellement modifiés. M03 : exécuter les tests ajoutés et la matrice, corriger sa PR #177 dans sa propre branche. M07 : textes/confidentialité naissance. M00 : cette PR est empilée sur #178, sans fusion/publication ; recette physique et conformité restent ouvertes. Aucun coût, compte réel, e-mail/push envoyé ni mutation Supabase dans ce lot.
