# Mission 01 — Synthèse et index de l'audit d'AS Grinta

**État : audit documentaire approfondi, non validé par des essais utilisateur.**
**Mise à jour : 12 novembre 2026.** Travaux sur la [PR #25](https://github.com/samihchaa-wq/Application-football-/pull/25) ; suivi global par le fil 00 et [PR #29 — tableau CHANTIER](https://github.com/samihchaa-wq/Application-football-/pull/29).

## Livrables et source de vérité

- **Tableau complet de référence — 164 unités métiers** avec sous-fonctions, classification, présence code/serveur, changements, risques, priorités, limites : [AUDIT_FONCTIONNALITES_DETAILLE.md](AUDIT_FONCTIONNALITES_DETAILLE.md).
- **Audit des routes, interactions et paramètres — 41 entrées de navigation, 7 interrupteurs et 8 règles** : [AUDIT_ROUTES_ET_PARAMETRES.md](AUDIT_ROUTES_ET_PARAMETRES.md). Cette annexe précise les contrôles écran par écran à vérifier, sans prétendre que ces contrôles ont été exécutés.
- **Cahier des charges du fil 02 — 30 tâches**, scénarios et critères d'acceptation : [CAHIER_DES_CHARGES_FIL_02.md](CAHIER_DES_CHARGES_FIL_02.md).
- **Relais entre fils, décisions et état vérifié** : [HANDOFF.md](HANDOFF.md).
- **Registre de pilotage du fil 00** : [CHANTIER.md](CHANTIER.md) (sur branche PR #29 tant que celle-ci n'est pas fusionnée).
- **Détail des règles existantes** : [regles-metier.md](regles-metier.md) et [NOTIFICATIONS_V2.md](NOTIFICATIONS_V2.md).
- **Tests requis sans être exécutés par cet audit** : [COMMERCIAL_LAUNCH_CHECKLIST.md](COMMERCIAL_LAUNCH_CHECKLIST.md), [business-security-matrix.md](business-security-matrix.md).

**Les identifiants de référence sont A01 à Nxx du document détaillé.** Les tickets F2-00 à F2-29 du cahier des charges renvoient à ces identifiants. Pour éviter deux registres concurrents et des classifications contradictoires, ce fichier est désormais l'**index de lecture** et non un second tableau de 155 lignes.

## Principes validés par la demande

1. **Conserver autant que possible toutes les fonctionnalités, l'ergonomie et l'ADN d'AS Grinta.**
2. **Conserver mais modifier** les comportements inadaptés à plusieurs clubs ; **paramétrer par club** ce qui relève d'une préférence (effectif, maillots, règles et horaires) ; **activer/désactiver** les options sans effacer les données.
3. **Retirer les données d'AS Grinta original** (joueurs, comptes, scores, historiques, images et contenus propres à son équipe), jamais les fonctionnalités qui les affichaient. Les noms techniques internes conservés pour compatibilité ne constituent pas du branding visible.
4. **Ne pas copier les anciennes migrations ou données** vers la base multiclub ; conserver l'historique immuable et exiger une migration commerciale nouvelle si modification approuvée.
5. Distinguer **présent dans le code**, **déployé**, **test écrit**, **test exécuté** et **validé en conditions réelles**. Aucun écran ou scénario n'a été testé bout à bout par le fil 01.

## Classification consolidée — navigation par domaine

| Domaine | Politique de conservation | Écart prioritaire / décision | Risque et priorité |
|---|---|---|---|
| Comptes/inscription/rôles | Conserver et sécuriser, création par club | Homonymes d'identifiants, OAuth/email, rattachement | Accès et isolation — P0 |
| Identité du club | Paramétrer nom, couleurs, écusson | Identité commerciale finale et contrastes | Image et parcours — P1 |
| Règles club | Paramétrer ouverture, clôture, rappels, vote, correction | Quota par défaut et adresse du terrain non exposés dans le commercial | Règle imposée — P0 |
| Saisons/calendrier | Conserver matchs, adversaires, événements, .ics | Cycle juillet-juin, type « coupe » **non livré**, import historique | Planning incohérent — P1 |
| Disponibilités | Conserver et régler les horaires | Indisponibilités, promotions, réponses concurrentes | Convocations incorrectes — P0 |
| Attente/rotation | Conserver et adapter, trois modes envisagés | Contrat exact des modes et comptage +1 à finaliser | Équité sportive — P0 |
| Compositions/maillots | Conserver terrain et simulation, paramétrer | Maillots Blanc/Orange/Bleu codés en dur, formats autres que 11 | Adaptation du club — P0/P1 |
| Animation compo | Préserver présentation du stade | Clips transparents personnels non démontrés comme importables | Média/droits — P2 |
| Mode Live | Conserver, option activable | Pilote unique, gel, rapport, refus serveur quand désactivé | Intégrité — P0 |
| Résultat et vote | Conserver, options et délais réglables | Nom « Homme du match », anonymat, correction | Inclusion et fiabilité — P0 |
| Pronostics | Conserver, option activable et horaires réglables | Score et cotes sans historique ; pas de portefeuille ×2 | Classements — P1 |
| Stats/fiches | Conserver, option Stats activable | Archives, identities canoniques, coach/invités | Données fausses — P1 |
| Badges/bilan | Conserver, options activables, personnaliser visuels | Badges genrés, musique non incluse, droits média | Image et droits — P1 |
| Notifications/PWA | Conserver, préférences et coupe-circuit | Web push réel, secrets, mobile, déclenchement cron | Livraison absente — P0 |
| Admin/éditeur | Conserver consoles et abonnement | Configurer exploitation, RGPD, marque, facturation non branchée | Commercialisation — P0 |
| Multiclub/sécurité | Conserver les contrôles serveur et RLS | Test A/B réel, 157 fonctions privilégiées à auditer (non des failles prouvées) | Confidentialité — P0 |

## Constat technique en lecture seule (12/11/2026)

- Dépôt commercial : code Flutter, migrations, ressources et tests présents ; reprise du dépôt original sans écriture sur celui-ci.
- Supabase `jvxkhgdopslctpcjrhzw` : **19 migrations**, jusqu'à `20261112050000_blocage_serveur_mode_live` ; **8 Edge Functions ACTIVE**, **83 tables public/private avec RLS**, **aucun club/compte/match**, **3 buckets** dont `profile-photos` privé. Schéma `install_tmp` encore présent.
- Contrôles GitHub du commit initial de la PR #25 : Flutter CI et diagnostic runtime verts. Aucun test utilisateur bout à bout, sécurité A/B, push réel ni restauration réalisé dans cette mission.
- **La base active et le code n'établissent pas un produit commercialement prêt** : Auth/e-mails/secret push non testés, Stripe absent, tarifs et textes légaux provisoires, hébergement Pages non autorisé à rouvrir sans validation.
- Les alertes Supabase sur des fonctions privilégiées sont **à instruire** par le fil 04, pas une affirmation de vulnérabilités confirmées.
- Une migration de l'original du 12/11 ajoute le quota habituel et l'adresse domicile ; son portage multiclub est une tâche et **ne doit pas reprendre son SQL singleton tel quel**.

## Décisions réservées au propriétaire

**DEC-01** : une équipe par espace ou multiéquipe ; **DEC-02** : football à 11 ou formats 5/7/8 au lancement ; **DEC-03** : identifiants par club ou autre stratégie ; **DEC-04** : personnalisation couleurs/modèles/photos des maillots ; **DEC-05** : nom neutre du vote et des badges ; **DEC-06** : clips individuels au lancement ou plus tard ; **DEC-07** : prix, essai et paiements ; **DEC-08** : identité finale et licences des médias.

Ces décisions sont enregistrées dans le détail et transmises au fil 00. Aucune n'est imposée silencieusement par ce fil.

## Transmission opérationnelle

- **Fil 02** : implémenter, une tâche F2 à la fois et par PR distincte, seulement après identification des travaux parallèles.
- **Fil 03** : exécuter la matrice d'acceptation ; noter une preuve observable pour chaque parcours, frontière et état.
- **Fil 04** : auditer RLS/RPC/Storage, fonctions privilégiées, absence d'accès d'un club A aux ressources du club B.
- **Fils 05/07** : identité et droits visuels/sonores ; **06** : facturation ; **08** : pilotes ; **09** : exploitation.
- **Fil 00** : lire les PR et la présente documentation, trancher les conflits et vérifier gates de validation.

**Statut :** tableau de classification et cahier des charges rédigés ; **tests réels non effectués**, décisions ci-dessus ouvertes ; aucune migration, donnée, app originale ou production n'a été modifiée.
