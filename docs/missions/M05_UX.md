# M05 — Expérience utilisateur, identité et accessibilité

## État du lot

- Rapport du 16 novembre 2026 (Europe/Paris), mission 05, plan [PR #147](https://github.com/samihchaa-wq/Application-football-/pull/147).
- Source applicative examinée : main `5f404e70f70b4e99d754f7064b567d027d66fe03`. Environnement : checkout local commercial, Python, ffmpeg/ffprobe ; aucun compte ni accès aux données utilisateur.
- **Documenté et contrôles locaux partiels exécutés. Aucun correctif applicatif livré, aucun test utilisateur observé, aucune validation mobile ni publication pour ce lot.**
- AGENTS.md, HANDOFF, CHANTIER, Fil 05 de la branche `docs/pilotage-mars-ete-2027`, audit M05 historique, kit M08 et README de la marque consultés.
- L'audit historique M05 décrit encore les anciens bleus/jaunes. La référence actuelle est [l'identité du 15 novembre](../branding/petit-filet/README.md) : anthracite, rouge, argent, logo PF. Conserver cette identité, les composants, badges et animations ; aucune refonte proposée.
- HANDOFF/CHANTIER sont des photographies anciennes : le workflow `auto_release_commercial.yml` écoute désormais les push main. Aucune fusion demandée. AS Grinta original et Carte soirée n'ont pas été modifiés ni utilisés comme environnement de test.

## Parcours annotés — lecture du code, pas réussite observée

| Étape | Chemin ou source | Constat / point à observer |
| --- | --- | --- |
| Dirigeant découvre le produit | Connexion → Créer mon compte → Créer un club ; `auth_sign_in_page.dart`, `auth_register_page.dart` | Le premier bouton annonce un compte, la création du club est au second écran. Observer si le dirigeant trouve seul cette entrée. |
| Création | Formulaire club, identité, mot de passe, e-mail facultatif, consentements | Les champs ont des libellés et plusieurs aides. L'e-mail facultatif est expliqué comme moyen de récupération ; vérifier le cas sans e-mail et les messages d'échec. |
| Fin d'inscription | Dialogue avec identifiant sélectionnable, bouton Compris puis connexion | Aucun bouton explicite de copie dans ce dialogue. Le texte demande d'inviter depuis « Administration » ; vérifier cohérence avec les intitulés actuels. |
| Club vide et saison | Calendrier ; Paramètres → Créer une saison, Effectif, Réglages du club | Le calendrier vide dit seulement que les matchs apparaîtront après programmation ; aucun chemin de démarrage dans cet état. Les actions existent ailleurs. |
| Inviter / accepter | Paramètres → Effectif (`/admin`) → Lien d'inscription ; `admin_page.dart` | Observer copie, ouverture du lien depuis messagerie et attente de validation. Ne jamais publier un lien actif dans les preuves. |
| Premier match | Bouton Créer un match du calendrier ; formulaires calendrier/match | Vérifier absence de saison, adversaire absent, lieu et convocations. L'absence de prérequis doit orienter vers leur création, avec retour au brouillon. |
| Composition | Fiche match → effectif/composition | L'éditeur comporte des actions au toucher et du glisser-déposer. Leur présence ne prouve pas l'utilisation clavier/lecteur d'écran. |
| Live puis compte rendu | Routes match/Live ; `match_live_running_page.dart` | Observer prise en main du chrono, remplacement, correction puis validation finale ; erreurs réseau et double action à couvrir avec M03. |
| Joueur invité | Lien → inscription → identifiant → connexion → attente éventuelle | Message de validation manuelle déjà présent. Observer si le joueur comprend qui doit agir et conserve son identifiant. |
| Participation / consultation | Calendrier → fiche → disponibilité, composition, Live, résultats, statistiques | Vérifier fenêtres temporelles et modules désactivés : expliquer une fermeture, distinguer lecture et modification. Ne pas dépendre uniquement d'une notification. |

Chemins basés sur `lib/app/router/app_router.dart`, `lib/features/more/presentation/more_page.dart`, pages auth/admin/matches. Les liens et intitulés doivent être recontrôlés sur le SHA de chaque correctif M02.

## Spécifications transmises à M02 et critères M03

Priorités proposées : P1 = friction majeure sur entrée essentielle à traiter avant pilote ; P2 = amélioration. Aucun P0 démontré par cet audit. Les hypothèses restent à reproduire en rendu.

| ID / priorité | Preuve et diagnostic | Correction attendue, sans refonte | Critère de retest |
| --- | --- | --- | --- |
| M05-01 / P1 proposée | `matches_page.dart:150` : état vide purement informatif ; actions saison/club dispersées dans MorePage | Pour admin sans saison : « Créer une saison » ; avec saison sans match : « Créer le premier match », et accès invitation. Joueur : message expliquant que son dirigeant programme les matchs. Réutiliser composants partagés. | Admin neuf accomplit saison → invitation → premier match sans consigne orale ; joueur ne voit aucune action administrative. Tester absence de saison et saison vide séparément. |
| M05-02 / P1 proposée | `auth_register_page.dart:195` renvoie vers « Administration », alors que MorePage montre Effectif et Réglages du club | Donner le chemin réel « Paramètres → Effectif → Lien d'inscription » après confirmation du menu sur candidat. Ajouter copie explicite de l'identifiant avec retour accessible ; conserver connexion par identifiant. | Identifiant copiable et annoncé au lecteur d'écran ; nouvel utilisateur retrouve le lien sans chercher une entrée inexistante. Petit écran et texte agrandi inclus. |
| M05-03 / P1 à qualifier | E-mail facultatif, récupération par adresse confirmée déjà codée ; délivrabilité non essayée | Dans le lot Auth M02, distinguer sans adresse, adresse non confirmée, lien expiré et panne réseau. Préserver réponse neutre aux demandes de récupération ; ne pas promettre un e-mail effectivement reçu sans preuve. | Reprise du parcours sans perte de saisie ; aucune divulgation d'existence de compte ; tests isolés puis délivrabilité autorisée avec M09. |
| M05-04 / P1 à qualifier | Éditeur composition avec toucher/glisser ; accessibilité effective inconnue | Vérifier puis fournir sélection du joueur et du poste sans glisser obligatoire, noms et états annoncés, focus visible et restauration du focus après dialogue. | Même composition réalisable au clavier et lecteur d'écran ; zéro action exclusivement visuelle. Aucun succès déclaré avant essai. |
| M05-05 / P2, P1 si tâche bloquée | AuthSurface défile et tient compte du clavier ; SegmentedButton/boîte de confirmation à tester | À 320 et 360 px et texte 200 %, tous champs/actions restent accessibles, dialogues défilants si nécessaire. Préserver saisie après erreur. | Zéro débordement empêchant lecture/action, bouton final atteignable clavier ouvert ; navigation avant/arrière conserve le contexte. |
| M05-06 / P1 à qualifier | Réduction des animations partiellement câblée dans thème, splash et composants ; pas de preuve globale vidéo/bilan | Tester préférence système ; garder une composition textuelle/statique, pause/fermeture accessibles, son facultatif. Ne pas supprimer l'animation normale. | Tâche réalisable sans mouvement ni son ; aucune lecture vidéo nécessaire à l'accès aux titulaires/remplaçants. |
| M05-07 / P1 à qualifier | Calendrier affiche `state.error!` directement dans une carte | Auditer les erreurs réellement remontées ; humaniser les messages techniques si nécessaires, expliquer action de reprise et conserver les données déjà chargées. | Panne/reprise réseau : message compréhensible et réessai sans doublon ; aucun SQL/jeton exposé. |

Coordination : M02 possède déjà comptes/invitations/récupération selon son commentaire sur #147 ; aucun de ces fichiers modifié ici. M01 conserve ses identifiants : M05-xx complète F2-00/F2-09 et T01–T05 cités par M02, sans les renommer. M03/M08 valident les résultats avant clôture. Ce rapport n'affirme pas que les autres conversations ont reçu ou exécuté une relance.

## Contrôles réellement exécutés et limites

| Contrôle local | Résultat | Limite |
| --- | --- | --- |
| Calcul Python sRGB des constantes du thème | Blanc/rouge bouton : 5,154 ; lien/surface haute : 5,479 ; texte discret/surface haute : 6,719 | Trois paires opaques seulement ; ne prouve ni toutes couleurs club, ni transparences, ni toute conformité. |
| Lecture des tests de contraste existants | `test/core/theme/club_accent_contrast_test.dart` et `availability_colors_contrast_test.dart` présents | Tests Flutter **non exécutés** dans ce lot ; SDK Flutter/Dart non disponible dans PATH. |
| `bash scripts/audit_stadium_media.sh /tmp/m05-stadium-audit` | Exécuté avec succès : deux planches de cinq images et poster, empreintes SHA256 et caractéristiques produits | Inspection visuelle des deux planches et du poster effectuée : pas de lettrage AS Grinta visible sur cet échantillon ; pas de garantie sur chaque image des vidéos. Drapeaux bleus/jaunes toujours visibles, aucune recoloration demandée. |
| Mesure des fichiers source | MP4 principal 2 860 048 octets ; 720p 1 339 958 ; audio 1 024 879 ; quatre TTF environ 345 ko | Pas une mesure de transfert effectif. Version légère environ 53 % plus petite ; tester sélection et cache réel avec M09. |
| Lecture thème et auth | Boutons principaux minimum 48 px ; infobulles mot de passe, autofill, scroll/clavier présents | Pas de mesure des zones tactiles de tous composants. |
| Réseau / charge mobile / lecteurs d'écran | **Non exécuté** | Aucun essai navigateur, iPhone/PWA, Android, VoiceOver/TalkBack, clavier, latence ou autonomie utilisateur observée. |
| CI / déploiement de ce lot | **Non vérifié / non déployé** | Le succès antérieur d'un job de publication ne valide pas ce rapport ni les parcours. |

Les trois contrastes sont des mesures d'ingénierie, pas une qualification juridique. M07 doit qualifier les obligations applicables. Aucun droit média n'est déduit de l'absence de marque à l'image.

## Ressources et provenance à transmettre à M07

| Famille | Sources présentes | Preuve / incertitude à résoudre |
| --- | --- | --- |
| Logo produit et icônes PWA | `docs/branding/petit-filet/README.md`, source `logo_final_clean.webp`, script `tool/branding/petit_filet_assets.py`, exports assets/web | Documentation indique logo transmis par propriétaire le 15/11 ; origine des éléments et droits commerciaux à confirmer. Déclinaison technique ≠ preuve de propriété. |
| Police Oswald | Quatre TTF et `assets/fonts/OFL-Oswald.txt`, déclaration pubspec | Notice OFL présente ; M07 vérifie distribution, correspondance des binaires et notices finales. |
| Police interface / icônes Material | Thème Flutter et `uses-material-design` | Dépendances et notices du build à inventorier ; police de repli variable selon appareil. |
| Maillots et décor | `assets/composition/`, `docs/branding/maillots/` | Sources graphiques et vidéo : licence/autorisation d'origine à prouver. Nettoyage du lettrage ne prouve pas les droits. |
| Musique | `assets/audio/wrapped.mp3`, README, `tool/generate_wrapped_music.py` | README affirme synthèse sans échantillon. Attribution/auteur, correspondance script→binaire et conditions à vérifier ; ne pas reprendre l'affirmation de propriété comme avis juridique. |
| Photos, logos/stades chargés par clubs | Fonctionnalités club et portraits | Aucun fichier utilisateur examiné ; obtenir droits image, règles mineurs, information, suppression avec M07/M04. |
| Badges, emojis, trophées, animations | `badge_emblem_body.dart`, composants Flutter, Wrapped, `assets/images/icons/` | Distinguer dessin procédural, fichier importé et emoji système ; provenance de chaque import à compléter, rendu emoji selon OS. |

Ne publier aucune identité, photo utilisateur, invitation active ni pièce justificative personnelle dans ce dépôt public. M07 conserve les justificatifs sensibles hors rapport public.

## Protocole de recette et démonstration M03/M08/M06

**Préparation** : environnement isolé autorisé, club fictif vide A et club B, admin et joueur distincts ; pas de donnée originale ni de véritable invitation externe. Figer SHA, URL et schéma avant séance. Ne pas créer ces comptes en production pour ce protocole sans autorisation.

**Séance observée** : un dirigeant et un joueur découvrent l'app sans aide orale. Consignes : « Crée ton club, une saison, invite un membre puis programme un match » ; « Rejoins ton club, retrouve le match et réponds à ta disponibilité ». Ensuite composition → Live → remplacement → compte rendu → consultation des résultats. Pour tester hors fenêtre réelle, utiliser horloge/données de test isolées ; ne pas modifier les dates commerciales.

Matrice à exécuter : iPhone Safari puis PWA, Android Chrome puis PWA, ordinateur clavier ; largeur 320/360/390 px, portrait/paysage, texte 200 %, préférence de mouvement réduit, réseau lent/coupé/repris, retour depuis messagerie. VoiceOver et TalkBack vérifient intitulés, ordre, états, focus et annonce des erreurs. Contrôler personnalisation A/B, maillots joueurs/gardien et historique, modules désactivés, comptes en attente et chargement des médias.

Journal par tâche : code participant anonyme, appareil/OS, version, préconditions, début/fin, réussite/échec, aides, hésitations, attendu/observé, capture expurgée, défaut M05-xx, correctif et retest. Seuil proposé : zéro tâche essentielle bloquée, zéro aide orale pour création/jonction et première disponibilité ; mesures de temps informatives, à convenir avec M08. **Aucune ligne ne vaut résultat tant qu'elle n'est pas exécutée.**

Démonstration simple proposée (10 minutes, à répéter avant présentation) :
1. Présenter le calendrier et la marque, puis identité personnalisée du club.
2. Dirigeant : saison, invitation, validation du joueur et premier match.
3. Joueur : connexion, disponibilité et consultation composition.
4. Dirigeant : Live, remplacement puis compte rendu validé ; joueur : résultats et statistiques.
5. Montrer les réglages et le recours en cas de difficulté, sans promettre de fonctions non éprouvées.

## Transmission et prochaine action

- M00 : lot documentaire terminé ; mission globale **en cours**, autonomie non démontrée, aucun GO pilote issu de ce lot.
- M02 : traiter M05-01/02 dans les parcours de démarrage, M05-03 dans son lot Auth ; qualifier 04–07 sur rendu avant correction.
- M03 : exécuter protocole et tests existants sur chaque SHA correctif ; M08 : observation sans aide et retest terrain.
- M07 : compléter le registre de droits et qualifier accessibilité ; M06/M08 : répéter le guide.
- Aucun arbitrage esthétique ni dépense nécessaire pour ce lot. Prochaine preuve attendue : correctif M02 lié à ces critères et première séance mobile observée.
