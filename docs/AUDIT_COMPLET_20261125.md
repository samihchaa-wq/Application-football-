# Audit complet — 25/11/2026

## Phase 0 — État des lieux (fait)

| Contrôle | Résultat |
|---|---|
| Analyse statique (`flutter analyze`) | 0 problème |
| Tests | 1556 réussis, 0 échec |
| Couverture des tests | 64,2 % des lignes (21 956 / 34 195) |
| Build web release | OK, 51 Mo au total (script principal 4,9 Mo, moteur de rendu 37 Mo) |
| Graphe de code | mis à jour |
| Dépendances | 62 paquets ont une version plus récente, bloquées par les contraintes (voir plan de mise à jour existant) |

À noter :
- Des traces d'erreur s'affichent pendant les tests, mais tous passent :
  bruit ou erreurs attendues, à vérifier en phase 8.
- Un avertissement de build sur la police d'icônes iPhone (CupertinoIcons) :
  mineur, à vérifier en phase 6.
- Stripe : d'après `docs/HANDOFF.md`, aucun paiement ni événement Stripe n'a
  jamais été reçu en production, et les fonctions Stripe n'ont jamais été
  exécutées en test. À confirmer en lecture seule en phase 2.

Non testé : vrai téléphone, vrais paiements.
