# Hors lot — à traiter (Kyky)

- Légal : cohérence CGV (essai 30 j, 79 €, rappel J-10, suspension sans délai de grâce) vs base : OK. Reste à remplir par la propriétaire les passages `[ … ]` (nom, adresse, e-mail, téléphone, SIRET, médiateur) — gravité haute avant lancement. Validation avocat obligatoire.
- Cache identité club : si un club change de couleurs depuis un autre appareil, le 1er rendu garde l'ancienne copie jusqu'à la réponse serveur (~0,5 s), sans flash vers le défaut — gravité basse.
- Le wrapper d'identité redessine tout l'arbre (KeyedSubtree) à chaque changement de nom/logo/couleur : à terme remplacer par des écouteurs ciblés — fluidité, gravité moyenne.
- Migration Riverpod 2 → 3 non commencée (décidée) — gravité moyenne.
- Version ordinateur, écrans hebdo, compte gestionnaire, audit écran par écran (salle d'attente, pronos, live, effectif, badges, calendrier, réglages) : non audités cette nuit faute de serveur pour les voir tourner — à planifier.
- Edge Functions Stripe (checkout, webhook, remboursement) relues : signature vérifiée, montant figé côté base, idempotence — rien de bloquant vu. Non testé contre Stripe test (pas d'accès).
