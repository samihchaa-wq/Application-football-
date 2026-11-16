# M07 — Conformité des pilotes et abonnement Petit Filet

Rapport du **16 novembre 2026 (Europe/Paris)**. Statut : **documenté, non validé professionnellement**.
Référence inspectée : `main` commercial `5f404e70f70b4e99d754f7064b567d027d66fe03` ; plan et Fil 07 de [PR #147](https://github.com/samihchaa-wq/Application-football-/pull/147), SHA `dd26ace17dc42c1af8bd9773f578f20e5a29067d`.
Environnement : copie locale du dépôt commercial ; recherche officielle France/UE. **Aucun accès à la base commerciale, test applicatif, déploiement, fusion, contact de club ou dépense.** AS Grinta original et Carte soirée exclus.

## Décision commerciale actualisée

La [correction impérative M00](https://github.com/samihchaa-wq/Application-football-/pull/147#issuecomment-6903574947) remplace le plan initial : **100 €/équipe/an dès souscription, sans année gratuite générale ; exception de 2–3 pilotes gratuits, périmètre et dates à contractualiser**. Ce choix est acquis ; ne pas redemander l'unité équipe/club. Les propositions antérieures de douze mois offerts sont retirées du présent dossier. La définition technique d'équipe, le traitement TVA et les conditions pilotes restent à préciser.

## Conclusion pour M00

**Pas de GO juridique démontré pour des pilotes avec données réelles.** La gratuité n'exonère ni du RGPD ni des droits sur les médias. Préparer les pilotes de mars/avril 2027 maintenant ; lever les points ci-dessous avant collecte réelle. Ce rapport complète les anciens audits sans les traiter comme des preuves actuelles.

Écarts statiques confirmés :
- `lib/features/legal/domain/legal_documents.dart:323–330` : essai de **30 jours**, puis **[10] €/joueur/an**, incompatible avec la dernière décision **100 €/équipe/an dès souscription**, avec exception pilote seulement. M06/M00 doivent synchroniser le plan et définir l'équipe facturable ; le traitement fiscal du prix reste à confirmer.
- Même fichier : coordonnées éditeur en crochets, microentreprise et franchise TVA présumées ; hébergement du site encore GitHub Pages. Faire vérifier les URL et fournisseurs réellement utilisés par M09 avant correction.
- `consent_fields.dart` : CGU et confidentialité dans une même acceptation ; déclaration « moins de 15 ans et un parent d'accord ». Ni autorisation média distincte ni preuve parentale suffisante démontrée par cet écran.
- `docs/legal/README.md` décrit cinq projets de textes, versions enregistrées et limites de réacceptation. Leur présence n'est pas une validation du contenu ni de leur acceptation effective.
- Contrairement au pré-audit du 12/11, **`docs/privacy-and-retention.md` décrit maintenant l'export et la suppression** ; ne pas répéter l'ancien constat de contradiction. Le document précise toutefois que les noms historiques et photos nécessitent des contrôles supplémentaires.
- Le motif libre d'absence peut être recopié dans un commentaire de participation. « Ne pas saisir de détail médical » et accès admin restreint ne suffisent pas à rendre licite une collecte de santé.

## 1. Registre de travail : finalités, rôles et bases à valider

Qualification proposée selon les décisions effectives, **pas selon le seul libellé d'un contrat** [S1]. L'éditeur peut cumuler plusieurs rôles ; l'authentification n'est pas automatiquement une finalité autonome de responsable de traitement.

| Finalité et données minimales | Rôle proposé | Base à établir par le responsable | Preuve / action |
| --- | --- | --- | --- |
| Effectifs, disponibilités, compositions, matchs, statistiques, badges et pronostics internes | Club responsable ; éditeur sous-traitant sur instructions | Contrat avec le membre si objectivement nécessaire ; sinon intérêt légitime documenté et mise en balance | M01 inventaire ; M07 validation finalité par finalité ; pas de consentement global imposé |
| Authentification nécessaire à ces services | Sous-traitance possible ; qualifier la gestion autonome du compte | Base du traitement servi ; rôle autonome seulement si fins propres établies | M02/M09 cartographier comptes multiéquipes, support et accès opérateurs |
| Sécurité autonome, prévention abus et journaux | Éditeur responsable pour ses fins propres ; club pour les siennes | Intérêt légitime, minimisation et durées justifiées | M04/M09 accès, incidents, contenu des logs |
| Contrat club, représentant et factures futures | Éditeur responsable | Intérêt légitime pour contacts de personne morale ; contrat si personne elle-même partie ; obligation légale pour pièces comptables | M06 identité acheteur, statut et TVA |
| Portrait, vidéo interne, publication publique et témoignage commercial | Club responsable de ses usages ; éditeur responsable d'une promotion propre | Base RGPD adaptée + autorisation d'image distincte selon usage | Supports, publics, durée et preuve séparés ; aucune réutilisation promotionnelle automatique |
| Alertes utiles au service / prospection | Distinguer notification demandée et publicité | Base du service pour alertes ; règles de prospection pour publicité | Autorisation navigateur ≠ consentement marketing ; M06/M02 |
| Motifs révélant santé, blessure ou handicap | Club responsable ; éditeur sous-traitant | **Base art. 6 ET condition art. 9** si collecte maintenue | Réduction recommandée ; validation spécialisée préalable [S2] |

Registres art. 30 à tenir côté éditeur (responsable ET sous-traitant) et clubs selon leurs obligations ; ne pas invoquer automatiquement l'exemption « moins de 250 salariés » pour ces traitements réguliers. Ajouter contacts, destinataires, transferts, mesures et durées dans un registre privé. Pas de coordonnées de joueurs dans GitHub public.

## 2. Obligations, qualification et conditions de levée

**O** = applicable si traitement décrit ; **C** = conditionnel à qualifier ; **R** = recommandation. « Avant pilote » est une porte de lancement du projet, pas une nouvelle catégorie légale. Aucune ligne n'est réputée levée sans preuve.

| ID | Nature / échéance | Exigence et état constaté | Responsable / preuve attendue |
| --- | --- | --- | --- |
| M07-01 | O avant collecte | Information art. 13/14 : finalités, bases, contacts, destinataires, durées, droits, CNIL ; information adaptée enfants ; import par admin à couvrir | M07/M02 : textes complétés et écrans accessibles avant collecte |
| M07-02 | O avant pilote | Accord art. 28 si sous-traitance ; instructions, sous-traitants ultérieurs et transferts | M07/M09 : contrat réellement conclu et annexes prestataires |
| M07-03 | O avant pilote | Sécurité art. 32 et confidentialité du Git public : statut non vérifié ici | M04 : audit confidentiel + essais négatifs A/B ; ne pas recopier données/secret dans tickets |
| M07-04 | O/C avant pilote | Santé : motif libre et copies dérivées ; restriction admin insuffisante | M01/M02 : proposer absence sans motif médical, inventorier copies ; M07 valider maintien éventuel et traitement des données déjà présentes |
| M07-05 | O/C avant médias réels | Droit à l'image + droits photographe/vidéaste + RGPD ; adversaires, spectateurs, voix et musique aussi concernés | M05/M08 : autorisations par usage et registre privé ; média non justifié à remplacer |
| M07-06 | C avant mineurs | Consentement numérique français à 15 ans uniquement dans le champ art. 8/LIL 45 ; capacité contractuelle et image distinctes | M07/M02/M08 : parcours parental proportionné, vérification autorité et information enfant ; pas de copie systématique de pièce d'identité |
| M07-07 | O avant pilote | Accès, rectification, effacement, limitation, opposition ; portabilité dans son champ seulement | M03 : export/suppression + anonymisation faits sportifs, médias, invités/imports et multiappareils ; délai RGPD en principe un mois |
| M07-08 | O avant pilote | Durées nécessaires documentées ; « 6 mois » dans projet ≠ justification ; notifications 90 jours décrites | M07/M09 : tableau de purge validé + sauvegardes, restauration sans réintroduire données effacées |
| M07-09 | O avant pilote | Procédure violation : sous-traitant informe club sans délai indu ; responsable notifie CNIL sous 72 h si risque ; personnes si risque élevé | M04/M09/M07 : registre de toutes violations, exercice fictif et contacts opérationnels [S1] |
| M07-10 | C avant traitement risqué | AIPD : documenter critères (mineurs, évaluation, santé, échelle), listes CNIL et risque résiduel ; DPO selon art. 37 | M07/M04 : analyse écrite ; ni automatique pour 3 clubs, ni exclue pour petite entreprise [S8] |
| M07-11 | O avant pilote | Éditeur identifiable, contact fonctionnel, mentions et contrat pilote cohérents | M06/M07 : identité/statut réels ; ne pas présumer EI micro ni franchise TVA [S5] |
| M07-12 | O/C avant usage | Cookies/SDK : stockage strictement nécessaire potentiellement exempt ; autres traceurs à qualifier | M02/M03 : audit réseau/stockage sur appareils ; consentement préalable si requis, refus/retrait effectifs |
| M07-13 | O/C avant diffusion | Droits/licences de toutes ressources, contributions, code IA et marque | M05/M07 : registre §5 ; aucune disponibilité de marque démontrée |
| M07-14 | C avant pilote | DSA : hébergement de contenus utilisateurs et éventuelle diffusion publique à qualifier ; petit acteur ≠ exemption totale | Juriste : périmètre hébergeur/plateforme ; M02 procédure signalement, motivation et retrait [S11] |
| M07-15 | C avant lancement concerné | Accessibilité : qualifier commerce électronique B2C, seuils/exemption micro de services et autres régimes | M05/M07 : analyse écrite ; améliorer parcours même si exemption [S10] |
| M07-16 | O/C avant abonnement | Offre, prix/unité, acceptation, refus, renouvellement, résiliation et réversibilité ; association pas systématiquement professionnel | M06/M07 : qualification acheteur et contrat ; art. L215-3 étend le chapitre aux non-professionnels [S6] |
| M07-17 | O/C avant facture | Statut, TVA, facture, impayés et obligations facturation électronique/e-reporting selon situation | Expert-comptable ; pas de prix HT/TTC ni régime fiscal présumé |
| M07-18 | C avant prospection | Personne physique bénévole ≠ contact professionnel automatiquement ; email public ≠ permission universelle | M06 : qualification canal/destinataire, information et opposition ; autorisation propriétaire distincte avant tout envoi [S7] |
| M07-19 | C avant évolution jeu | Pronostics : mises, gain, hasard et offre publique à examiner ensemble ; abonnement donnant accès peut changer analyse | M01/M06/juriste : conserver recommandation sans mises ni gains monétaires/convertibles ; lots à faire qualifier [S12] |

## 3. Conservation et chaîne technique : décisions à prendre

Tableau proposé, **non appliqué**. Le club doit déterminer les besoins sportifs ; le prestataire ne fixe pas arbitrairement toutes ses durées.

| Données | Règle proposée à valider | Contrôle attendu |
| --- | --- | --- |
| Effectif et compte actif | Durée nécessaire à l'adhésion/service ; revue à chaque saison | Départs, comptes dormants, changement d'équipe |
| Faits sportifs historiques | Durée justifiée par finalité ; anonymisation réelle si identification plus nécessaire | Nom, surnom, maillot et rapprochements : un ID nul n'est pas forcément anonyme |
| Photos/vidéos | Durée de l'usage autorisé, revue de saison et retrait géré | Originaux, miniatures, cache/CDN et liens partagés |
| Notifications | 90 jours décrits dans dépôt ; vérifier purge effective même sans nouveaux envois | Suppression navigateur, compte et tous appareils |
| Logs sécurité / preuve d'accord | Durées distinctes à justifier ; accès restreint | Aucun secret push ni contenu médical dans journaux |
| Fin de pilote/club | Fenêtre d'export proposée de 30 jours, puis retour/suppression selon instructions et obligations | Délai à contractualiser ; aucune suppression pour forcer paiement |
| Sauvegardes | Rétention bornée à fournir par M09, accès limité et chiffrement ; purge différée expliquée | Test DB/Auth/Storage et réapplication des effacements après restauration |

M09 doit fournir : fournisseurs effectivement activés (Supabase, hébergement web/CDN, GitHub/Actions/artefacts, SMTP, Web Push, monitoring ; paiement futur), entités, régions, finalités, DPA, sous-traitants ultérieurs, accès support hors EEE et mécanismes de transferts art. 44+. **Une région Paris ne prouve pas l'absence de transfert.** Aucun contrat fournisseur n'a été vérifié dans ce lot.

## 4. Textes préparatoires à faire relire — pas à publier tels quels

Ces clauses complètent `docs/JURIDIQUE_MODELES_A_VALIDER.md` et les cinq modèles Dart. Les champs à compléter sont volontairement visibles ; **aucune modification de leurs versions actives dans ce lot**.

### Mentions et information

Éditeur : [entité et forme réelles], [adresse], [immatriculation applicable], [contact fonctionnel], [directeur de publication]. Hébergeurs : [entités/adresses et fonctions réellement vérifiées]. TVA : [mention validée par le professionnel comptable]. Séparer information RGPD et acceptation contractuelle.

Notice membre proposée : « Le club [identité/contact] utilise vos données pour [finalités et bases détaillées]. Petit Filet [éditeur] les traite sur ses instructions pour [périmètre]. Pour ses finalités propres [liste], l'éditeur est responsable. Les données accessibles à [destinataires] sont conservées [durées/critères] ; transferts [pays/garanties]. Vous pouvez exercer vos droits auprès de [contact], et saisir la CNIL. Les champs [liste] sont nécessaires pour [raison et conséquence d'absence] ; les autres sont facultatifs. » Ajouter sources et catégories si import indirect, et informations supplémentaires requises selon cas.

### Convention pilote gratuite — exception réservée aux pilotes

« [Éditeur] et [club représenté par personne habilitée] conviennent d'un pilote Petit Filet du [date] au [date], pour [équipes/modules/limites]. Le suivi terrain de deux à trois mois est distinct de la durée de gratuité. La gratuité est exclusivement limitée à ce pilote, pour [équipes et dates expressément retenues]. Aucun paiement ni bascule payante ne résulte du silence du club. Une offre annuelle distincte sera proposée et ne prendra effet qu'après acceptation expresse par une personne habilitée. En cas de refus, [fin d'accès, export et suppression documentés]. Les conditions de sécurité, support [horaires/délais réalistes], signalement, suspension proportionnée et réversibilité figurent dans les annexes. »

Ne pas inclure une renonciation générale aux droits ni faire du témoignage public une contrepartie obligatoire. Responsable de support et procédure d'incident identifiés ; aucune garantie « 100 % fiable ». Responsabilité et assurance à examiner avec juriste, pas d'exclusion absolue.

### Annexe article 28 — contenu à compléter avant signature

Objet/durée/nature/finalités ; personnes et données ; instructions documentées et traitement des instructions illicites ; confidentialité des personnes habilitées ; mesures art. 32 ; autorisation et information des sous-traitants ultérieurs ; assistance aux droits et art. 32–36 ; notification de violation sans délai indu ; retour/suppression au choix du responsable sauf obligation légale ; informations et audits ; règles des transferts. Annexer mesures concrètes et liste de prestataires. Vérifier la clause existante limitant audits/frais : elle ne doit pas neutraliser les obligations art. 28.

### Autorisation média distincte

« Je [identité, ou qualité de représentant habilité] autorise [club/éditeur précisément nommé] pour [portrait / vidéo désigné], uniquement sur [application privée du club / support public précisément indiqué], pour [finalité], jusqu'au [date]. Les usages promotionnels font l'objet d'un choix distinct. Contact pour retrait/droits : [contact]. » Faire préciser les effets du retrait et les bases RGPD par le juriste. Pour mineur, prévoir titulaires de l'autorité parentale selon situation, association de l'enfant à la décision, preuve proportionnée et refus sans exclusion sportive injustifiée. Le seuil de 15 ans ne dispense pas des règles d'image avant 18 ans [S3–S4].

### Abonnement futur

Préciser acheteur et représentant, définition d'équipe facturable, rattachement au club, périmètre, prix HT/TTC et taxes, date de départ de gratuité et échéance, paiement, incidents, renouvellement et préavis, résiliation, support, responsabilité et sortie. Tarif décidé : 100 €/équipe/an dès souscription hors exception pilote, traitement TVA à préciser. Recommandation : passage du pilote au payant par acceptation expresse, sans prélèvement automatique à l'issue du pilote. Rétractation/garanties/médiation pour consommateurs et protections des non-professionnels à qualifier séparément : ne pas copier toutes les règles B2C aux associations ni les exclure globalement.

## 5. Registre initial des droits et licences

Inventaire local : **15 fichiers sous assets**, dont README et licence. Ce comptage n'inclut pas toutes dépendances, ressources web ni fichiers historiques. Droit d'auteur, droit à l'image, marque et licence fournisseur sont quatre contrôles distincts.

| Ressource | Preuve disponible | Conclusion / action |
| --- | --- | --- |
| Oswald, quatre TTF | `assets/fonts/OFL-Oswald.txt` | Licence présente ; conserver texte/mentions, vérifier correspondance aux binaires et diffusion |
| `assets/composition/stade.mp4`, `stade-720.mp4`, `stade.jpg` | Origine non établie par les fichiers lus | M05 : source, licence et personnes/marques ; remplacer si preuve absente, même pendant pilote réel |
| `assets/images/icons/assist_boot.png` | Inconnue selon README légal | M05 : licence ou remplacement |
| `club_crest.webp`, `petit_filet_logo.webp`, deux `portrait_jersey_*.png` | Provenance non établie dans ce lot | Auteur/outil, source, droits commerciaux et marques tierces à consigner |
| `assets/audio/wrapped.mp3` | README déclare synthèse par `tool/generate_wrapped_music.py` | Déclaration de provenance utile, pas preuve automatique de propriété exclusive ; vérifier génération et absence d'éléments tiers |
| Dépendances Dart/Flutter et web | `pubspec.yaml`, lockfiles ; inventaire exhaustif non fait | M02/M07 : noms/versions exactes, licences transitives, notices distribuées et incompatibilités ; SDK/outils séparés du produit livré |
| Contributions et code IA | Historique commercial, origine dérivée déclarée | Chaîne des droits et conditions outils à établir ; originalité humaine et droits tiers à faire qualifier ; dépôt public ≠ domaine public |
| Nom Petit Filet et domaines | Nom décidé ; aucune recherche approfondie réalisée | Recherches INPI de similarités et autres droits, domaines ; aucun dépôt/achat sans accord [S9] |

Gabarit du registre privé : ressource/empreinte, auteur/source, date acquisition, version licence/preuve, droits de modification et diffusion commerciale, attribution, personnes/marques, validation, alternative. Aucun fichier de consentement nominatif dans GitHub.

## 6. Recette demandée et répartition

| Mission | Livrable demandé | Critère de réussite |
| --- | --- | --- |
| M01 | Données/champs et mécanismes pronostics/récompenses, publics concernés | Aucun champ libre, import ni historique oublié |
| M02/M05 | Notices et accords distincts, versions et nouvelle acceptation, parcours parental et retrait médias | Texte et comportement cohérents ; absence de cases trompeuses |
| M03 | Scénarios export/rectification/effacement/opposition/retrait ; sortie club | Exécuter avec données synthétiques autorisées ; tracer médias, historiques et isolation ; pas seulement bouton cliquable |
| M04 | Interclubs, permissions, exposition Git et incident | Résultats négatifs reproductibles, preuves assainies |
| M09 | DPA/prestataires/transferts, purge/cache/backups et restauration | Mesures effectives et délais ; aucun flux déduit de la seule région DB |
| M06 | Définition acheteur et unité équipe/club, gratuité, tarif, fiscalité/prospection | Offre sans contradiction et pas de contact sans ordre |
| M08 | Autorisations, représentant club, guides et refus/retrait | Pas de vrai onboarding avant GO et documents finalisés |
| M00 | Arbitrages et validation professionnelle | Fermeture des portes avec preuves, aucune fusion implicite |

**Exécuté dans ce lot :** lectures statiques des sources citées, inventaire des chemins assets et recherches officielles. **Non exécuté :** CI applicative, tests navigateur/mobile, requêtes SQL, audit Git historique, consentement réel, exercice de droits, audit fournisseur ou recherche de marque. Aucune certification ni conformité déployée annoncée.

## 7. Décisions et revue professionnelle

À présenter par M00 sans bloquer la préparation documentaire :
- Pilotes : A = deux mois gratuits pour une équipe adulte à 11 par club, troisième mois après accord (proposition M08) ; B = trois mois dès le départ (proposition M06) ; C = autre périmètre explicite. M00 doit fournir le détail du choix acquis, s'il existe ; ne pas interpréter un « 1A » isolé sans son questionnaire. Aucune année gratuite générale.
- Mineurs : A = pilote réservé aux majeurs (réduit le périmètre, décision requise) ; B = mineurs avec parcours parental/image validé ; C = comptes responsables légaux à spécifier. Ne pas présumer A décidé.
- Motif d'absence : A = supprimer/désactiver saisie libre et traiter copies (recommandé) ; B = maintien après analyse art. 6/9 ; C = reporter ce module après arbitrage produit. Aucun changement exécuté.

**Avocat/juriste RGPD et numérique :** rôles par finalité, données de santé, mineurs, image, clauses art. 28, classification des associations, DSA, accessibilité, responsabilité et jeux. **Expert-comptable :** structure, TVA, facturation et calendrier électronique. **Propriété intellectuelle :** droits code/IA, médias et recherche de marque. Ne commander aucune prestation sans prix et accord.

Prochaine action : M00/M06 valident l'offre équipe/club et les décisions ; M02/M03/M04/M09 apportent les preuves techniques ; M07 finalise ensuite les textes pour revue et consigne les validations. La seule existence de ce rapport ne lève aucun blocage.

## Sources officielles consultées le 15–16 novembre 2026

Réactualiser avant pilotes 2027 et contrats payants 2028. Les qualifications proposées ci-dessus sont des analyses de travail.

- **S1** [RGPD, texte UE](https://eur-lex.europa.eu/eli/reg/2016/679/oj?locale=fr) : notamment art. 5–9, 12–22, 28, 30, 32–37, 44+.
- **S2** [CNIL, santé des sportifs, 18/06/2024](https://www.cnil.fr/fr/sportifs-quels-cas-et-conditions-collecte-des-donnees-de-sante).
- **S3** [CNIL, sport amateur : questions-réponses](https://www.cnil.fr/fr/sport-amateur-hors-contrat/questions-reponses) ; [consentement](https://www.cnil.fr/fr/les-bases-legales/consentement) ; [mineurs de moins de 15 ans](https://www.cnil.fr/fr/recommandation-4-rechercher-le-consentement-dun-parent-pour-les-mineurs-de-moins-de-15-ans).
- **S4** [Service Public, droit à l'image](https://www.service-public.gouv.fr/particuliers/vosdroits/F32103) ; [image de l'enfant, vérifié le 27/04/2026](https://www.service-public.gouv.fr/particuliers/vosdroits/F38464).
- **S5** [Service Public, mentions site professionnel, vérifié le 13/10/2026](https://entreprendre.service-public.gouv.fr/vosdroits/F37351) : adapter à la forme réelle de l'éditeur.
- **S6** [Légifrance, L215-1](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000032226980/) et [L215-3](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000032226976) : reconduction et non-professionnels.
- **S7** [CNIL, prospection électronique, 10/06/2026](https://www.cnil.fr/fr/la-prospection-commerciale-par-courrier-electronique-sms-mms-et-automate-dappel).
- **S8** [CNIL, AIPD](https://www.cnil.fr/fr/RGPD-analyse-impact-protection-des-donnees-aipd) ; [guide DPO](https://www.cnil.fr/sites/default/files/atoms/files/guide_pratique_rgpd_-_delegues_a_la_protection_des_donnees.pdf).
- **S9** [INPI, étapes marque](https://www.inpi.fr/realiser-demarches/propriete-intellectuelle/etapes-cles-du-depot-de-marque) ; [logiciels](https://www.inpi.fr/realiser-demarches/propriete-intellectuelle/cas-particulier-logiciels).
- **S10** [DGCCRF, accessibilité, 13/11/2025](https://www.economie.gouv.fr/dgccrf/les-fiches-pratiques/professionnels-vos-produits-et-services-doivent-etre-conformes-la-directive-accessibilite).
- **S11** [Arcom, DSA, mise à jour du 06/02/2026](https://www.arcom.fr/espace-professionnel/reglement-sur-les-services-numeriques-ou-dsa-obligations-et-services-concernes).
- **S12** [ANJ, porteurs de projet et quatre critères](https://anj.fr/professionnels/porteur-de-projet).
