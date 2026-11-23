# Journal Kyky Fonctions

## 2026-11-23 (passage 15 h 40 UTC)

**Fait**
- Branche claude/kyky-fonctions créée depuis main (elle n'existait pas).
- Lecture du code, sans exécution : Flutter, Graphify et kyky.md absents. Installation de Graphify refusée par la session, non contournée.
- Test mot de passe « lettres accentuées » (message du Chef) : relu à la main, `ÉlèveDuFoot2026` passe la règle (a-z, A-Z, chiffre, 15 car.). Pas de lien avec la version de Flutter (règle simple). Non exécuté ici. Probablement déjà vert sur main : à confirmer par un vrai lancement.

**Décidé**
- Aucun correctif écrit : sans Flutter, impossible de reproduire ni de tester. Règle « cause avant correctif » tenue.

**Pistes (non vérifiées)**
- « Gestion sportive indisponible » : la page match affiche ce texte quand les réglages sont lus comme « coupés » et « connus ». Cela arrive si la lecture finale échoue (repli « indisponible », sourceAvailable=false) ou si la valeur de remplacement posée avant la connexion est servie. Fichiers : feature_flags_controller.dart (build, sportsManagementRoutingStateProvider), match_details_page.dart ligne ~135. Piste : traiter « source indisponible » comme « inconnu » (spinner + nouvel essai) et non comme « coupé ». À tester avec Flutter avant de coder.
- Déconnexion gestionnaire : toujours non reproduite. Réponses de la propriétaire aux questions Q2/Q6 (docs/KYKY_QUESTIONS.md) attendues.

**Reste à faire**
- Moi : dès que Flutter est dispo, écrire un test qui reproduit « indisponible » sur lien direct, puis corriger ; lot 3 (prochain match, convocations, disponibilités) ; lot 4 (propositions compte gestionnaire).
- Propriétaire : autoriser Flutter (storage.googleapis.com) et l'installation de Graphify, ou brancher l'environnement « Application-football » ; répondre à Q2 et Q6.

**Hors périmètre**
- Aucun relevé ce passage.

## 2026-11-23 (passage 16 h 45 UTC)

**Fait**
- Branche récupérée. Flutter toujours absent. Installation de Graphify refusée par la session (non contournée). Aucun test lançable.
- Q2 et Q6 (KYKY_QUESTIONS.md) : toujours sans réponse.

**Décidé**
- Aucun code écrit. Pas de correctif sans reproduction.

**Reste à faire**
- Moi : dès Flutter dispo, lot 2 (test « Gestion sportive indisponible » puis correctif), lot 3, lot 4.
- Propriétaire : autoriser Flutter + Graphify pour la session planifiée ; répondre à Q2/Q6.

**Hors périmètre**
- Rien.
