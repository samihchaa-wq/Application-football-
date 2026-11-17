# M05 — Confirmation d'inscription utilisable sur téléphone

Lot développé le 17/11/2026 sur main `0e5fa39`, suite au critère M05-02 du rapport `docs/missions/M05_UX.md` (PR #150).

Le dialogue conserve son identité visuelle Material/Petit Filet. Il devient défilant, propose une copie explicite de l'identifiant et annonce le succès ou le refus du presse-papiers. L'identifiant reste sélectionnable si le navigateur refuse la copie. Le texte dirige l'administrateur vers le chemin actuel : Paramètres → Effectif → Lien d'inscription. La confirmation utilise « équipe ». Le joueur en attente conserve son explication et ne reçoit pas d'instruction administrative.

Coordination M02 : branche fondée sur main après intégration du premier lot comptes/invitations. Seule la confirmation de succès est extraite ; aucun changement à la soumission, l'authentification, aux consentements ou à la base. M05-01 (guidage calendrier vide) reste à traiter séparément.

Recette ajoutée : copie de l'identifiant exact, refus du presse-papiers avec repli manuel, distinction joueur/admin et fermeture sur écran 320×568 avec texte 200 %. Le test existant d'inscription est adapté au titre « Équipe créée ».

Vérification locale : revue des chemins et git diff --check. SDK Flutter/Dart indisponible dans PATH : formatage, analyse, tests et build Web non exécutés localement, à vérifier dans Flutter CI avant toute intégration. Ces tests ajoutés ne sont pas présentés comme réussis. Aucun test sur vrai iPhone/Android ou lecteur d'écran réalisé. M03 : vérifier la CI du SHA exact et les scénarios ajoutés ; M08 : retester conservation de l'identifiant et découverte du lien sans aide sur téléphone. Pas de fusion, déploiement, donnée commerciale modifiée ni intervention sur AS Grinta original.
