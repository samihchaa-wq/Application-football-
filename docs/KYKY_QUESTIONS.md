# Questions pour la propriétaire (Kyky, nuit du 22/11/2026)

## Q1. Direction visuelle de la refonte
- Contexte : 3 maquettes (téléphone + ordinateur) dans `docs/maquettes/`. Aucun texte, module ni ordre ne change, seulement l'esthétique.
- A : « Nuit » — sombre, rouge, titres condensés (proche de l'actuel, plus net).
- B : « Pelouse » — clair crème, vert profond, titres à empattement (très différent, chaleureux).
- C : « Ardoise » — sombre bleuté, bleu + vert, coins arrondis, ombres douces (moderne).
- Reco : A si tu veux garder l'identité rouge/anthracite ; B si tu veux vraiment casser l'effet « vibe codée ». Rien appliqué en masse en attendant.

## Q2. Bug de déconnexion du gestionnaire : symptôme précis
- Contexte : non reproduit (pas de serveur local). Durcissement fait sur le renouvellement de session de la Console. Cause réelle non prouvée.
- Besoin : sur quel appareil/navigateur, après combien de temps d'absence, quel écran voit-il après la déconnexion, par quel chemin il se connecte (lien /control ?).
- Options : A) tu me donnes ces infos ; B) essai sur ton téléphone avec la version corrigée ; C) je construis un faux serveur de test (lot à part).
- Reco : B puis A si ça persiste.

## Q3. Preuve visuelle du correctif « flash au lancement »
- Contexte : test automatique OK, mais pas de capture du rendu réel (pas de serveur Supabase local ni de compte).
- Options : A) tu testes sur ton téléphone (2e ouverture après connexion) ; B) faux serveur de test (lot à part).
- Reco : A.

## Q4. Textes légaux : infos à remplir par toi
- Voir `docs/KYKY_A_TRAITER.md` (section légal). Je n'invente rien : identité éditeur, SIRET, adresse, e-mail, médiateur.
- Rappel : seul un avocat peut valider ces textes.

## Q5. Remboursement total : que devient l'abonnement ?
- Constat (serveur local) : après un remboursement total, le club reste « actif » jusqu'à l'échéance ; seule une note de crédit est émise.
- Options : A) rien (l'éditeur suspend à la main si besoin) ; B) remboursement total = suspension auto du club ; C) échéance ramenée à la date du remboursement.
- Reco : A tant qu'il y a peu de clubs ; B si tu offres un droit de rétractation.

## Q6. Déconnexion du gestionnaire : toujours non reproduite
- Testé sur serveur local (web, jeton expiré toutes les 15 s, nouvel onglet, lien /control) : session conservée.
- Seul cas de « déconnexion » reproduit : compte éditeur sans club, profil « en attente » → écran « Compte en attente ». Est-ce ton cas (compte éditeur = admin d'un club ou compte seul) ?
- Besoin : téléphone ou ordinateur, navigateur ou appli installée, durée d'absence.
