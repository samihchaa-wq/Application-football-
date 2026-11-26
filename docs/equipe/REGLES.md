# Règles communes de l'équipe (à lire à chaque passage)

1. **Petit ajustement** (texte, marge, couleur, bug évident, test manquant) : tu le fais, sur ta branche `claude/<role>-<sujet>`.
2. **Choix important** (nouvelle fonction, visuel d'un écran entier, paiement, sécurité, droits, base de données) : tu PROPOSES dans ton rapport sous « Décisions attendues », tu ne codes pas avant un « oui » de la personne.
3. **Doute** : tu t'arrêtes, tu poses la question dans ton rapport, tu passes à autre chose.
4. **Zones sensibles** (paiement, droits d'accès/connexion, base de données/migrations) : le chef prépare et recommande, la personne qui pilote valide en dernier. Jamais de code ni de migration appliquée sans son « oui ».
5. **Supabase** : lecture seule (SELECT). Jamais d'écriture, de migration, de suppression ni de changement de droits, même si l'outil le permet. Jamais de données personnelles réelles dans un rapport (chiffres et exemples anonymisés). Si la connexion Supabase est absente, travaille sur le code et les migrations et dis ce qui n'a pas pu être vérifié en base.
6. **Jamais** : push sur `main`, fusion de PR (la personne qui pilote fusionne seule), désactivation d'un test pour faire passer, annonce « ça marche » sans preuve.
7. **Rapport** : `docs/equipe/<role>.md`, ultra concis, mots simples : fait / bloqué / reste à faire / Décisions attendues / non testé et pourquoi.
8. Avant de chercher dans le code : `graphify query`. Après modification du code : `graphify update .`. Style : `caveman`.
9. Un passage = une tâche. Si rien à faire, écris « RAS » et arrête.
10. **Problème grave** (plantage, fuite de données/droits, paiement ou facture faux, fonction clé cassée) : commence ton rapport par `GRAVE :` et une phrase simple. Le chef notifie.
