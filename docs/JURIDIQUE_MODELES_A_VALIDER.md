# Mission 07 — projets de textes juridiques à faire valider

**État au 12 novembre 2026 — BROUILLONS UNIQUEMENT.** Ces textes sont volontairement **non exploitables tels quels** : toutes les mentions `[À COMPLÉTER]` ou `[À VALIDER]` doivent être traitées ; la qualification juridique des clients et la répartition des rôles RGPD doivent être tranchées. Relecture **avocat/juriste** avant publication ; fiscalité et factures par **expert-comptable**. Source des risques : [audit mission 07](../JURIDIQUE_MISSION07.md).

Ne pas injecter directement ces brouillons dans `legal_documents.dart` sans validation, ni réécrire une version acceptée par les utilisateurs sans procédure de versionnage et information.

## Modèle A — mentions légales (trame)

> Éditeur : **[dénomination / nom entrepreneur individuel]**, forme juridique **[À COMPLÉTER]**, immatriculation **[SIREN/SIRET/RCS selon cas]**, siège / adresse **[À COMPLÉTER]**. TVA intracommunautaire **[si applicable]**. Directeur de publication **[À COMPLÉTER]**. Contact : **[email]**, **[téléphone selon obligation]**. Hébergeur du site : **[prestataire du service web commercial, coordonnées légales]**. Base, fichiers et authentification : **[prestataire/coordonnées]**. Pour un signalement de contenu : **[contact et procédure]**.

**Alerte :** GitHub Pages ne peut pas être repris comme hébergement autorisé du SaaS commercial sans résoudre la question des conditions d'utilisation.

## Modèle B — CGU des membres de club (trame)

1. **Objet et périmètre.** L'application est mise à disposition des membres par un club **[nom]**, abonné auprès de **[éditeur]**. Le service couvre planning, convocations, disponibilité, résultats et fonctionnalités optionnelles activées par le club.
2. **Compte et accès.** Un compte personnel est nécessaire ; le club décide des habilitations sportives et valide les membres. Comptes et identifiants non transférables. Accès limité au club autorisé.
3. **Contenus.** L'utilisateur reste responsable des contenus qu'il publie ; il respecte les droits d'autrui, notamment l'image des joueurs et les droits sur les médias. Les admins n'ajoutent pas de contenus dont ils ne peuvent justifier les droits.
4. **Photographies et données sensibles.** Les photographies sont facultatives. L'utilisateur est informé des destinataires/visibilités avant publication. L'application ne doit pas servir à stocker des informations médicales sans cadre valide et contrôles spécifiques.
5. **Mineurs.** Le traitement des données des mineurs, les autorisations parentales et l'exercice des droits suivent les règles applicables à chaque finalité ; règles d'inscription **[À VALIDER]**.
6. **Comportements interdits.** Usurpation, harcèlement, contenu illégal, atteinte aux droits d'autrui et accès aux données d'autres clubs.
7. **Disponibilité/maintenance.** Les interruptions sont possibles ; modalités de support **[À COMPLÉTER]**, sans exclure les garanties légalement applicables.
8. **Données personnelles.** Répartition des rôles et contacts dans la politique de confidentialité ; demandes de droits et signalements **[À COMPLÉTER]**.
9. **Évolution.** Notification préalable des modifications substantielles ; version des CGU, date d'entrée en vigueur et modalités d'acceptation applicables **[À COMPLÉTER]**.
10. **Droit applicable / différends.** **[À VALIDER par juriste selon qualité du client et du membre]**.

## Modèle C — CGV de l'abonnement club (trame)

- **Parties.** Éditeur **[identité juridique]**, client signataire **[club/association/personne physique]**, représenté par **[habilité à engager le club]**.
- **Offre.** Accès à la PWA et fonctionnalités **[annexe technique datée]**. Nombre de comptes/joueurs inclus et méthode de comptage **[à décider]**.
- **Essai gratuit.** Durée **[30 jours, à valider]** ; déclenchement, conditions d'arrêt et éventuelle absence de carte bancaire **[à confirmer]**.
- **Prix et taxes.** Montant **[à décider]** ; HT/TTC et régime TVA **[expert-comptable]** ; changement du nombre de joueurs et prorata **[à décider]**.
- **Paiement et facturation.** Facturation **[annuelle/mensuelle]**, moyens de paiement **[virement/prestataire]**, échéance, retard et justificatifs **[à valider]**.
- **Durée et renouvellement.** Début, terme, renouvellement explicite ou automatique **[à décider]**, information précontractuelle, règles de non-reconduction et résiliation **[à valider en fonction de la clientèle]**.
- **Service, incidents, support.** Conditions de disponibilité raisonnables et exclusions circonscrites ; maintenance et contact **[à compléter]**.
- **Obligations réciproques.** Club responsable des habilitations et informations sportives ; éditeur des engagements de sécurité et de maintenance assumés.
- **RGPD.** DPA annexé lorsque l'éditeur est sous-traitant du club ; répartition des finalités dans l'information RGPD.
- **Fin de contrat.** Période d'export, restitution et suppression **[durée et format à convenir]**, sauvegardes et délais propres documentés.
- **Responsabilité.** Plafond, exclusions et assurances **[à faire relire]**, sans neutraliser obligations impératives ni faute lourde/dol.
- **Réclamations et litiges.** Contacts, médiation et rétractation **[selon qualification consommateur/professionnel et régime applicable]**.

**Ne pas utiliser unilatéralement une CGV « B2B » :** une association ne reçoit pas automatiquement la même qualification qu'une société ; le cocontractant et la finalité de l'achat doivent être précisés par le fil 06 et le juriste.

## Modèle D — contrat de sous-traitance RGPD (DPA, cadre art. 28)

**Annexe descriptive à renseigner par chaque club :**

- Responsable de traitement : **[club et coordonnées]**, pour les finalités sportives effectivement décidées par lui **[à confirmer]** ; sous-traitant : **[éditeur et coordonnées]**.
- Objet : hébergement et opérations techniques du service ; durée : **[contrat + restitution/suppression]**.
- Données : identité, compte, photo facultative, rôle, présence/indisponibilité, statistiques, contenus, notifications, logs **[inventaire exhaustif]**.
- Personnes concernées : membres, staff, éventuels invités et mineurs **[si admis]**.
- Finalités et instructions documentées : **[création/gestion du compte, organisation du club, sécurité, notifications, conservation]**.
- Personnes autorisées : engagement de confidentialité ; habilitations et formation appropriées.
- Sécurité : isolation logique par club, authentification, restrictions RLS, contrôle des accès, journalisation proportionnée, sauvegardes et tests ; **[annexe sécurité approuvée]**.
- Assistance aux demandes de droits : canal **[contact]**, délais opérationnels **[à fixer]**, procédure d'escalade au responsable.
- Violation : le sous-traitant alerte le responsable **sans délai injustifié**, informations disponibles et mesures de confinement ; les obligations de notification à la CNIL sont réparties selon rôle RGPD.
- Sous-traitants ultérieurs : liste **[Supabase / hébergeur web / e-mail / paiement selon traitement]**, mécanisme d'autorisation, information des changements et droit d'objection.
- Transferts : pays, garanties de transfert, clauses pertinentes et vérification d'accès hors EEE **[à documenter]**.
- Audits : informations pour démontrer la conformité, modalités proportionnées de contrôle et de remédiation.
- Fin de mission : restitution/suppression selon instruction, avec exceptions légales et sauvegardes **[à préciser]**.

**Important :** reprendre les clauses types de la Commission européenne (ou un DPA correctement individualisé) après qualification des rôles. L'éditeur peut être **responsable autonome** pour certaines finalités (par exemple ses propres factures) : ne pas étendre artificiellement ce DPA à ces traitements.

## Modèle E — politique de confidentialité (plan d'information, à individualiser)

### Tableau à remplir avant mise en ligne

| Finalité | Responsable juridique | Données | Base légale | Destinataires | Durée / critères |
|---|---|---|---|---|---|
| Compte et authentification | [à qualifier] | Identité, e-mail/identifiant, rôle | [à qualifier] | Supabase, accès autorisés | [à définir] |
| Organisation sportive | [club ou autre rôle : à qualifier] | Présences, résultats, statistiques | [à qualifier] | Membres selon visibilité | [à définir] |
| Photo de joueur | [à qualifier] | Image, légende | [à qualifier + droit à l'image] | [membres/public selon usage] | [à définir] |
| Motif d'absence libre | [à qualifier] | Peut révéler la santé | [condition art. 9 en plus de base art. 6, ou supprimer] | [restriction] | [strict minimum] |
| Notifications | [à qualifier] | Abonnement push, historique | [à qualifier] | Prestataires techniques | 90 jours documentés pour historique ; confirmer |
| Maintenance et sécurité | [éditeur à qualifier] | Logs/IP/événements | [intérêt légitime ou autre] | Hébergeurs/support | [à définir] |
| Abonnement/factures | [éditeur] | Données du client payeur | [contrat/obligation légale selon finalité] | Comptable/paiement | [durées fiscales légales] |

Compléter obligatoirement : coordonnées et contacts des responsables, catégories, droits (accès, rectification, opposition, effacement, portabilité **si applicable**, limitation), réclamation CNIL, transferts hors EEE, modalités d'exercice, conservation, rôle des mineurs et exceptions. **Ne pas exiger l'acceptation de cette politique comme si elle constituait à elle seule une base de consentement RGPD.**

## Modèle F — autorisation distincte de droit à l'image

> Je soussigné(e) **[nom de la personne photographiée]** / **[parent ou titulaire de l'autorité parentale, qualité et preuve selon situation]** autorise **[nom du club et/ou éditeur]** à utiliser les photos/vidéos **[description]** dans **[supports précisément désignés : PWA privée des membres, cartes joueurs, présentation d'effectif, site public, réseaux sociaux, etc.]**, à des fins **[description précise]**, pour la durée **[à fixer]** et le territoire **[à fixer]**, sans autre utilisation ni cession à des tiers sauf **[cas définis]**. Les modalités de retrait et les conséquences sur des publications déjà réalisées sont indiquées **[contact]**. Date, lieu, signature et cases de choix par usage.

**ATTENTION :** document séparé des CGU et du consentement aux traitements de données ; le club doit démontrer les droits sur l'image **et** une base RGPD appropriée. Pour les mineurs, faire vérifier la validité des signatures et les règles propres à l'âge / à l'autorité parentale.

## Modèle G — procédure d'incident et droits des personnes

1. Réception via **[adresse de support dédiée]** ; enregistrer demande/incident sans publier de données sur GitHub.
2. Vérifier identité de la personne et rôle du club, en limitant les pièces demandées.
3. Pour une **demande RGPD** : router au responsable pertinent, enregistrer la date et répondre dans le délai légal (en principe 1 mois, prolongation possible selon le RGPD) ; contrôler les lignes historiques, images et copies.
4. Pour une **violation** : documenter même si non notifiable, isoler et évaluer catégories de personnes/données et niveau de risque.
5. Si notification CNIL requise : le responsable doit notifier au plus tôt et si possible sous **72 h** après connaissance ; si risque élevé, information aux personnes selon règles. Le sous-traitant informe son responsable de traitement sans délai injustifié.
6. Consigner décision, preuves, actions correctives, clôture et responsable ; éviter toute publication de secrets/noms de joueurs dans PR.

## Checklist juridique avant **première vente**

- [ ] Statut/identité légale du vendeur et informations fiscales validées par expert-comptable.
- [ ] Modèle de clients et catégorie juridique clarifiés (associations, particuliers, professionnels).
- [ ] Prix, essai, périmètre, factures et éventuelle reconduction décidés ; CGV validées.
- [ ] Mentions légales complètes ; hébergeur PWA autorisé pour SaaS commercial.
- [ ] Rôles RGPD par finalité, base légale, information et DPA signés si nécessaires.
- [ ] Prestataires, régions, transferts et sous-traitants ultérieurs documentés.
- [ ] Historiques Git et secrets traités, avec analyse de notification si exposition confirmée.
- [ ] Deux clubs fictifs A/B prouvés étanches ; incidents et demandes de droits testés.
- [ ] Mineurs : modalités d'inscription/autorisation et information compréhensible validées.
- [ ] Images / audio / polices / badges / code et dépendances : registre de droits établi.
- [ ] Durées réelles de conservation, purge/archives et fin de contrat exercées et documentées.
- [ ] Nom retenu après recherche d'antériorités ; éventuel dépôt **seulement sur décision**.
- [ ] Tests PWA, sécurité, restaurations et paiement/factures réels achevés.
- [ ] Relecture avocat/juriste et expert-comptable sur les points concernés.
- [ ] Autorisation explicite du propriétaire et validation fil 00.

## Références principales

- [CNIL — qualification des rôles](https://www.cnil.fr/fr/rgpd-comment-bien-identifier-son-role)
- [CNIL — clauses contractuelles types art. 28](https://cnil.fr/fr/clauses-contractuelles-types-entre-responsable-de-traitement-et-sous-traitant)
- [CNIL — données de santé](https://www.cnil.fr/fr/quest-ce-ce-quune-donnee-de-sante)
- [CNIL — mineurs et consentement](https://www.cnil.fr/fr/les-bases-legales/consentement)
- [CNIL — notifier une violation](https://www.cnil.fr/fr/services-en-ligne/notifier-une-violation-de-donnees-personnelles)
- [Service Public — mentions site et CGV](https://entreprendre.service-public.gouv.fr/vosdroits/F37351)
- [Service Public — factures](https://entreprendre.service-public.gouv.fr/vosdroits/F23208)

**Validation requise :** avocat/juriste spécialisé numérique et RGPD ; expert-comptable pour fiscalité/facturation. **Aucun document ci-dessus n'est publié dans l'application.**
