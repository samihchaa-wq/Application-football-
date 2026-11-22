# Kyky : à traiter (hors lot)

Une ligne par point : quoi, où, gravité. Le propriétaire choisit l'ordre.

- Légal : Stripe est cité dans la politique de confidentialité mais absent de la liste des sous-traitants de l'accord sur les données (`lib/features/legal/domain/legal_documents.dart`, section « Sous-traitants »). Gravité moyenne. Modifier un texte légal peut imposer une nouvelle acceptation par les utilisateurs : décision du propriétaire, puis avocat.
- Légal : les CGV disent « sans remboursement de la période en cours » mais l'appli permet à l'éditeur de rembourser (double paiement, erreur). Prévoir une phrase sur ces cas. Gravité faible.
- Bug déconnexion gestionnaire : correctifs déjà fusionnés (Poste de contrôle + profil au retour), tests verts. Pas encore essayé sur vrai téléphone ni ordinateur. Gravité haute tant que non confirmé.
- Outils : ni Supabase CLI ni Deno sur cette machine, donc pas de test des règles d'accès (RLS) ni des fonctions Stripe en local. Gravité moyenne.
