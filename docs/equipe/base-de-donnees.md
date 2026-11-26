# Base de données — rapport

## Passage du 26/11/2026 — table sans clé primaire

**Fait**
- Contrôle de performance Supabase (lecture seule) : aucune clé étrangère sans index, aucune règle d'accès lente signalée.
- Seul vrai signal : une table interne de mise de côté des incidents sans club n'a pas de clé primaire (identifiant unique de ligne). Vérifié : vide (0 ligne), 8 Ko, aucune fonction, vue, règle ni tâche planifiée ne s'en sert.
- Migration de suppression écrite, **non appliquée** : branche `claude/bdd-table-sans-cle`, PR #269. Elle s'arrête d'elle-même si la table n'est plus vide.

**Ce que ça change pour l'utilisateur** : rien de visible. Ménage, risque nul.

**Bloqué** : rien.

**Reste à faire (prochains passages)**
- 59 index jamais utilisés selon Supabase. Normal pour une base de 15 jours et peu de trafic ; beaucoup servent aux suppressions liées. À revoir dans quelques semaines, pas avant.
- Connexions du service de connexion (Auth) fixées à 10 au lieu d'un pourcentage : à changer seulement si on agrandit le serveur. Réglage du tableau de bord, pas une migration.

**Décisions attendues**
- Appliquer la PR #269 (suppression de la table vide) ? Recommandé : oui, sans urgence.

**Non testé et pourquoi**
- Tests de la base non lancés : pas de base locale dans cette session.
