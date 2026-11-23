# Journal Kyky Paiement et légal

Branche : `claude/kyky-paiement`. Rappel : seul un avocat peut valider les
textes légaux. Rien n'est appliqué à Supabase / Stripe (lecture seule).

## 23/11/2026 — Lot 1 : remboursement total = suspension immédiate

**Fait (écrit, non testé, non déployé)**
- Constat : `private.apply_refund` n'émettait qu'un avoir ; le club restait
  actif jusqu'à l'échéance. Code, tests et CGV ne disaient pas la même chose.
- Migration `20261204010000_remboursement_total_suspend_le_club.sql` (NON
  appliquée) : remboursement total du DERNIER paiement → club suspendu,
  abonnement `canceled`, échéance = maintenant. Partiel ou ancien paiement :
  rien ne change. Suspension « manuelle » (`auto_suspended_at` vide) : jamais
  purgée, pas rouverte seule par un nouveau paiement (l'éditeur rouvre via
  « Autoriser l'accès »).
- Test pgTAP `supabase/tests/database/remboursement_total_suspension.test.sql`.
- CGV art. 5 : paragraphe ajouté. `clubContractVersion` passée à
  `2026-11-23` (Dart + `register-account/consent.ts` + `claim-club/consent.ts`).
  À déployer ENSEMBLE (appli + 2 fonctions), sinon la création de club échoue.

**Non vérifié** : pas de Deno, Flutter ni base locale dans cette session. Ni
tests Deno, ni tests Flutter, ni pgTAP lancés. Les insertions du test
(paiement sans facture) peuvent demander un ajustement à la 1re exécution CI.

**Reste à faire (moi)** : lancer les tests en CI ; écran Gestionnaire :
afficher « club suspendu » après un remboursement total (le champ
`club_suspended` est renvoyé, non lu) ; texte du bouton « Rembourser » à
prévenir de la suspension.
**Reste à faire (propriétaire)** : valider la règle « suspension manuelle »
(un club qui repaie ne rouvre pas seul) ; confirmer que « dernier paiement »
est la bonne règle.

## 23/11/2026 (soir) — Lot 2 : relecture du parcours et tests Deno

**Fait / vérifié**
- Tests Deno lancés pour de vrai (Deno installé dans la session) :
  `stripe-checkout` 6, `stripe-refund` 7, `stripe-webhook` 13,
  `register-account` 18 : tous passent (type-check coupé, `--no-check`).
- Relu et cohérent code ↔ CGV : essai 30 jours sans carte (défaut base),
  rappel 10 jours avant l'échéance, suspension SANS délai de grâce (migration
  du 18/11 : 0 jour), facture acquittée après paiement, mention TVA 293 B
  identique sur facture et CGV, conservation des données 3 ans identique
  CGV ↔ suppression automatique, remboursement total = suspension immédiate.
- Aucune incohérence nouvelle trouvée.

**Non vérifié** : `account-email` (test des rappels) non lancé : `jsr.io`
inaccessible depuis la session, sa dépendance ne se télécharge pas. Aucun test
Flutter ni pgTAP (ni Flutter ni base locale ici). `claim-club` n'a pas de test.
Rien lu en vrai dans Stripe ni Supabase.

**Reste à faire (moi)** : lancer pgTAP + Flutter en CI ; écran Gestionnaire
« club suspendu » après remboursement total.
**Reste à faire (propriétaire)** : mêmes points que le lot 1 ; prix à décider ;
passages `[ … ]` à remplir. Seul un avocat peut valider les CGV.

## 24/11/2026 — Lot 3 : texte du bouton « Rembourser »

**Fait (écrit, non compilé, non testé, non déployé)** : la boîte « Rembourser »
disait « l'accès du club n'est pas modifié » : faux depuis la règle du 23/11.
Texte corrigé : remboursement total du dernier paiement = club suspendu tout
de suite ; partiel = accès inchangé. Aucun test Flutter ne cite ce texte.

**Non vérifié** : Flutter absent de la session (ni analyse, ni test). Charte
et courrier interne toujours illisibles (Projects : 404). graphify absent.

**Reste à faire (moi)** : pgTAP + Flutter en CI ; message « club suspendu »
après remboursement (le serveur renvoie `club_suspended`, l'appli ne le lit pas) ;
relecture bout en bout impayé → suspension.
**Reste à faire (propriétaire)** : inchangé (prix, passages `[ … ]`, avocat).

## Lieux à changer selon le prix (NON décidé, rien tranché)

Aujourd'hui : 79 € par club et par an, TVA non applicable (art. 293 B).
- Montant 79 € : `legal_documents.dart` (CGV art. 3), migration
  `20261124010000_forfait_annuel_club.sql` (défaut 7900), valeurs par défaut
  7900 dans `lib/features/platform/` (billing_panel, cash, settings_section),
  test e-mail `account-email/subscription_reminder_test.ts`.
- 100 € : mêmes endroits, valeur 10000.
- « Par équipe » (au lieu de par club) : changement de fond. Il faut compter
  les équipes d'un club dans la base, calculer le montant côté serveur
  (`admin_prepare_card_payment`), adapter facture, Stripe Checkout, CGV art. 3,
  parrainage. Pas de simple changement de chiffre.
- HT / TTC : si TVA applicable → `invoiceVatMention` (`invoice_pdf.dart`),
  `_vatMention` (CGV, mentions légales), réglages de facture en base,
  ligne TVA sur facture et avoir, Stripe Checkout, e-mails de rappel.
  Franchise de TVA : le seuil de chiffre d'affaires est à vérifier par un
  comptable.

## Passages `[ … ]` à remplir par le propriétaire

Dans `lib/features/legal/domain/legal_documents.dart` (lignes 48-57) :
nom et prénom de l'éditeur (2 fois), adresse postale, e-mail de contact,
téléphone, numéro SIREN. Le médiateur : décision du 19/11 = pas d'adhésion
(risque accepté, voir `docs/legal/README.md`). À remplir aussi en base :
réglages de facture (nom, adresse, SIRET, e-mail) — non vérifiés (lecture
de la base de production non faite dans ce lot).

## Hors périmètre / points ouverts

- `.claude/agents/kyky.md` absent de main : méthode appliquée de mémoire. Moyenne.
- Projet « Petit filet » illisible (outil Projects : 404) : charte et courrier
  interne non lus ; messages/paiement.md et skills/paiement.md non écrits. Moyenne.
- graphify absent (pas de `graphify-out/`, pas de programme) : noté.
- Parcours complet essai → carte → facture → impayé : relu en partie seulement
  (remboursement et CGV). Reste à relire de bout en bout. Non fait.
