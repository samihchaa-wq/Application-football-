# Chantier 161 — promotions et parrainage par équipe

Reprise du 16 novembre 2026. Références : #161, #159, plan #147.
Base lue : `main` `61e941b15bfd5df6c9e00281bb38bbf565d9b871`.

## Décisions du propriétaire à conserver

- Petit Filet gère exclusivement des équipes ; `clubs`/`club_id` restent des
  identifiants historiques, sans regroupement commercial.
- Référence : 100 €/équipe/an. La qualification HT/TTC reste à préciser avant vente.
- Promotion à usage unique au total : une année gratuite ou 50 % sur une période
  annuelle. Seul le gestionnaire peut émettre/désactiver ces codes.
- 5 points de réduction par nouvelle équipe filleule abonnée annuellement,
  plafond 50 % après dix équipes distinctes.
- Choix **2A** : bénéfice au prochain renouvellement annuel seulement.
- Choix **3A** : meilleure offre unique, aucun cumul promo + parrainage.
- Pas de débit automatique surprise après une année offerte.

## Développé dans ce lot

`supabase/functions/_shared/annual_offer.ts` est une politique de calcul serveur
pure, réutilisable dans le futur adaptateur de facturation. Aucun endpoint ne
l'appelle encore ; elle ne crée ni code réel, ni paiement, ni abonnement.

Le devis est en centimes EUR, prend le maximum des deux offres et fournit les
identifiants à consommer après validation. Les crédits sont affectés à une
échéance explicite ; aucun report ou renouvellement automatique de réduction.
Seuls les crédits validés, payés, non consommés, de cette équipe et de cette
échéance sont retenus. Un paiement gratuit, échoué, pending ou reversed ne compte
pas. Doublons, auto-parrainage et registre d'une autre équipe sont rejetés.
Une promotion présentée mais indisponible bloque le devis au lieu de produire
silencieusement une facture au tarif plein.

Choix technique de ce lot : à égalité de réduction, utiliser le parrainage et
préserver le coupon. Si la promotion gagne, le calcul ne consomme aucun crédit
de parrainage. Le sort des crédits non utilisés à cette échéance (expiration ou
exception de report), comme les crédits au-delà du plafond, reste à formaliser
dans les conditions avant activation ; le calcul ne les déplace jamais de lui-même.
Un identifiant de crédit n'est pas une preuve de paiement : la source doit être
le registre privé, vérifié par le futur adaptateur, jamais le corps de requête.

## Vérification exécutée

Commande : `node --test supabase/tests/edge/annual_offer.test.mjs`, Node 24.22.1.
**30 tests réussis, zéro échec**. Cas 0/1/2/9/10/11, matrice 0–100 pour les trois
offres, prochaine année, première souscription, gratuité, remboursements/statuts,
doublons, auto-parrainage, inéligibilité, montants invalides et absence de mutation.
Les données sont fictives. Workflow dédié sans secret et sans paiement ajouté.
Les tests n'exécutent pas un prestataire, une base, une RLS ou une interface.

## Suite indispensable pour rendre la fonctionnalité utilisable

1. **Registre privé SQL et RPC (M02/M04).** Promotions à empreinte de code,
   émission opérateur via `private.is_platform_operator()`, désactivation,
   audit privé, droits révoqués par défaut ; code de parrainage non énumérable
   par équipe. Une attribution unique par filleule, sans auto-parrainage.
   Préserver le code dans l'inscription avec validation d'e-mail (#160).
2. **Paiement et transaction (M02/M09).** Choisir/brancher le prestataire sans
   achat implicite. Vérifier signature, compte, devise, abonnement annuel et
   paiement réellement encaissé ; clés uniques événement/paiement/souscription.
   Ne jamais déduire le succès du retour navigateur. Réserver et consommer un
   coupon atomiquement ; deux transactions concurrentes ne réussissent pas.
   Pour une année gratuite : acceptation explicite et transaction atomique,
   sans simuler un encaissement ou valider un parrainage.
3. **Devis et échéances.** Charger les données serveur, recalculer à la
   confirmation, figer la version de politique, l'offre gagnante et le montant
   dans le registre. Éviter le double usage après retry. Sérialiser clôture de
   renouvellement et attribution de crédits pour définir le prochain disponible.
   Remboursement/contestation : reversed avant calcul ; après facture, correction
   explicite/avoir selon conditions, jamais réécriture silencieuse.
4. **Interface (M02/M05).** Écran gestionnaire #159 pour émettre, désactiver et
   suivre ; espace équipe pour saisir un code, voir devis, échéance, code de
   parrainage et compteurs agrégés sans identité des filleuls. Remplacer l'ancien
   écran par joueur seulement avec le contrat serveur par équipe correspondant.
5. **Recette intégrée (M03/M04).** Permissions joueur/admin/opérateur/anonyme,
   révocation, recherche de codes limitée, concurrence réelle, webhooks répétés,
   remboursement et deux équipes, E2E mobile puis revue M06/M07 des conditions.

## État et limites

**Développé et testé localement : calcul uniquement.** Pas encore utilisable
dans l'application ; registre, émission, consommation atomique, paiement et
interface restent à réaliser. CI distincte à vérifier sur le dernier SHA.
Pas de test Flutter, de test SQL ni de consultation de Supabase commercial
dans ce lot ; aucune conclusion sur l'état effectif de production.
Issue #161 à garder ouverte. Aucune fusion ni activation : les workflows de
main peuvent lancer une publication. AS Grinta original et Carte soirée intacts ;
aucune dépense, notification réelle ou écriture de production.
