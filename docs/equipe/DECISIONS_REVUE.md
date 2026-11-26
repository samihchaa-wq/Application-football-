# Décisions de la revue des agents (26/11/2026)

Passages planifiés : EN PAUSE pendant la revue.

## Testeur — validé
- Domaines : pronos, match en direct, liste d'attente, fin de saison, badges, notifications, simulation de compo, connexion/compte, matchs et compos, paiement/facturation (lecture seule), cas limites. Un domaine différent à chaque passage.
- Méthode : tests automatiques + navigateur simulé (version web).
- Données : vraie base Supabase, avec garde-fou. Risque connu : la connexion Supabase ne peut pas être limitée à la lecture, seule la règle écrite l'interdit. À vérifier : donner la connexion aux passages planifiés (non testé).
- Garde-fou : uniquement des requêtes de lecture (SELECT), jamais d'écriture, jamais de copie de données personnelles dans les rapports (chiffres et exemples anonymisés).
- Alerte : rapport + notification immédiate si grave = plantage/non-démarrage, fuite ou erreur de données/droits, paiement ou facture faux, fonction clé cassée.
- Fréquence : 3 passages par jour.
