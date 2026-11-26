# Décisions de la revue des agents (26/11/2026)

Passages planifiés : EN PAUSE pendant la revue.

## Testeur — validé
- Domaines : pronos, match en direct, liste d'attente, fin de saison, badges, notifications, simulation de compo, connexion/compte, matchs et compos, paiement/facturation (lecture seule), cas limites. Un domaine différent à chaque passage.
- Méthode : tests automatiques + navigateur simulé (version web).
- Données : vraie base Supabase, avec garde-fou. Risque connu : la connexion Supabase ne peut pas être limitée à la lecture, seule la règle écrite l'interdit. À vérifier : donner la connexion aux passages planifiés (non testé).
- Garde-fou : uniquement des requêtes de lecture (SELECT), jamais d'écriture, jamais de copie de données personnelles dans les rapports (chiffres et exemples anonymisés).
- Alerte : rapport + notification immédiate si grave = plantage/non-démarrage, fuite ou erreur de données/droits, paiement ou facture faux, fonction clé cassée.
- Fréquence : 3 passages par jour.

## Développeur — validé
- Fait seul : texte/orthographe/libellé, bug évident d'une seule fonction (avec test), test manquant, petit réglage visuel (marge, couleur).
- Livraison : branches et propositions de PR ; seul le chef les voit, les trie et les regroupe par thème (1 PR par thème). Le chef fixe la taille des changements par passage.
- Zones sensibles (paiement, droits d'accès/connexion, base de données/migrations) : le chef prépare et recommande, la personne qui pilote valide en dernier.
- Fusion dans la version principale : la personne qui pilote seule.

## Chef de projet — validé
- Tri des décisions : par urgence puis impact. Liste complète, mais ultra concise, en mots simples (une ligne par décision : quoi, pourquoi, sa recommandation).
- Conflit entre agents : il pose la question à la personne, avec les deux avis résumés et sa recommandation.
- Notifications : décision importante en attente, problème grave signalé par un agent, PR prête à fusionner, résumé quotidien même si RAS.

## Designer — validé
- Référence : l'appli actuelle (corriger les incohérences, pas de refonte).
- Priorités : cohérence couleurs/textes/boutons, adaptation aux tailles d'écran, états vides/erreurs/chargement, accessibilité.
- Preuve : captures avant/après (version web), jointes à la PR. Si impossible, dire que ce n'est pas vérifié visuellement.
- Fait seul : marges, couleurs, tailles, alignements, sans changer la structure d'un écran. Le reste = proposition.

## Sécurité — validé
- Périmètre : droits (qui voit/modifie quoi), secrets et clés dans le code, données personnelles, invitations et liens partagés.
- Base : lecture seule (SELECT) sur la vraie base. Même garde-fou et même risque que le testeur (écriture non bloquée techniquement). Jamais de données personnelles réelles dans les rapports.
- Alerte : rapport, notification si grave (fuite de données, droits trop larges, secret exposé).
- Fréquence : 1 passage par jour, un sujet par passage.
