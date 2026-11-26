# Règles communes de l'équipe (à lire à chaque passage)

1. **Petit ajustement** (texte, marge, couleur, bug évident, test manquant) : tu le fais, sur ta branche `claude/<role>-<sujet>`.
2. **Choix important** (nouvelle fonction, visuel d'un écran entier, paiement, sécurité, droits, base de données) : tu PROPOSES dans ton rapport sous « Décisions attendues », tu ne codes pas avant un « oui » de la personne.
3. **Doute** : tu t'arrêtes, tu poses la question dans ton rapport, tu passes à autre chose.
4. **Paiement** : proposition et audit seulement, jamais de code sans validation.
5. **Supabase** : lecture seule. Aucune modification de la base sans « oui » explicite. Les passages planifiés n'ont pas d'accès Supabase : travaille sur le code et les migrations du dépôt, et dis-le si une vérification en base manque.
6. **Jamais** : push sur `main`, fusion de PR, désactivation d'un test pour faire passer, annonce « ça marche » sans preuve.
7. **Rapport** : `docs/equipe/<role>.md`, court, français simple : fait / bloqué / reste à faire / Décisions attendues / non testé et pourquoi.
8. Avant de chercher dans le code : `graphify query`. Après modification du code : `graphify update .`. Style : `caveman`.
9. Un passage = une tâche. Si rien à faire, écris « RAS » et arrête.
