# Hors lot — à traiter (Kyky)

- Légal : cohérence CGV (essai 30 j, 79 €, rappel J-10, suspension sans délai de grâce) vs base : OK. Reste à remplir par la propriétaire les passages `[ … ]` (nom, adresse, e-mail, téléphone, SIRET, médiateur) — gravité haute avant lancement. Validation avocat obligatoire.
- Cache identité club : si un club change de couleurs depuis un autre appareil, le 1er rendu garde l'ancienne copie jusqu'à la réponse serveur (~0,5 s), sans flash vers le défaut — gravité basse.
- Le wrapper d'identité redessine tout l'arbre (KeyedSubtree) à chaque changement de nom/logo/couleur : à terme remplacer par des écouteurs ciblés — fluidité, gravité moyenne.
- Migration Riverpod 2 → 3 non commencée (décidée) — gravité moyenne.
- Version ordinateur, écrans hebdo, compte gestionnaire, audit écran par écran (salle d'attente, pronos, live, effectif, badges, calendrier, réglages) : non audités cette nuit faute de serveur pour les voir tourner — à planifier.
- Edge Functions Stripe (checkout, webhook, remboursement) relues : signature vérifiée, montant figé côté base, idempotence — rien de bloquant vu. Non testé contre Stripe test (pas d'accès).
- Lien direct vers un match à venir (Supabase local, temps réel coupé) : « Gestion sportive indisponible » reste affiché. Cause partielle trouvée par traces : le contrôleur des réglages (feature_flags_controller.dart) est reconstruit 3 fois au démarrage ; la 1re valeur « indisponible » reste servie à la page alors que la 3e est « activée ». Se corrige en revenant au calendrier puis au match. Non corrigé (2 essais ratés). Gravité moyenne (notification ouverte à froid).
- Remboursement total d'un paiement : l'abonnement reste « actif » jusqu'à son échéance (apply_refund ne touche ni statut ni échéance). Décision métier à prendre (voir KYKY_QUESTIONS).
- Compte éditeur sans club (profil « en attente ») : /control mène à l'écran « Compte en attente de validation ». Normal mais déroutant ; compte éditeur = admin d'un club ?
- Composition passée (démo) : joueurs entassés au centre du terrain sur ordinateur (terrain étroit) — à revoir avec de vraies positions.
