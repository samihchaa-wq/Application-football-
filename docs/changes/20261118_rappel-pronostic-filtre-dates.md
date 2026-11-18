# Rappel de pronostic : un filtre de dates avant les calculs d'heure

## Problème

La tâche planifiée `prediction-j5-reminders` passe chaque minute, club par club.
Elle calculait l'heure du rappel (plusieurs lectures des réglages du club) pour
**tous** les matchs « à venir » de chaque club, c'est-à-dire tout le calendrier
de la saison, alors qu'un rappel ne peut partir que pour un match qui commence
dans les prochaines 24 heures.

Mesure du test de charge de la CI (200 clubs, 4 000 matchs, PR #194) : cette
seule tâche prend 6,5 s par passage sur 6,9 s pour toutes les tâches
planifiées. Sur la vraie base (2 clubs), elle représente aussi la plus grosse
part. À coût égal par club, c'est elle qui fixe le nombre de clubs que la
plate-forme peut porter avant que les passages se chevauchent (voir
`docs/ANALYSE_PETIT_FILET_20261118.md`, section 6).

## Changement

Migration `20261124000000_rappel_pronostic_filtre_dates.sql` : deux conditions
simples (`kickoff_at` entre hier et dans deux jours) placées **avant** les
calculs d'heure dans `public.push_prediction_j5_notifications()`. Le reste de la
fonction est repris à l'identique.

## Pourquoi le résultat ne change pas

- Le rappel ne part jamais après la fermeture des pronostics, qui ne tombe
  jamais après le coup d'envoi : il faut donc `kickoff_at > now()`.
- L'heure du rappel n'est jamais avant minuit (Paris) du jour du match : le
  coup d'envoi est donc à moins de 24 h de `now()` (25 h un jour de changement
  d'heure). La borne de deux jours laisse une marge.

Preuves :

- `supabase/tests/database/prediction_reminder_prefilter.test.sql` : sur une
  grille de coups d'envoi couvrant les deux changements d'heure de 2026,
  aucun match dont le rappel est dû n'est hors du filtre ;
- vérification hors ligne avec les définitions réelles des fonctions : 1 416
  cas dus avec les réglages par défaut, 41 376 cas sur 32 combinaisons
  extrêmes des réglages du club, **0 écarté à tort**.

## Mesure (test de charge de la CI, mêmes 200 clubs et 4 000 matchs)

| Tâche `prediction-j5-reminders`, un passage | Avant (PR #194) | Après (PR #197) |
|---|---|---|
| Durée | 6 500 ms | 436 ms |
| Part de toutes les tâches planifiées | 94 % | 71 % |
| Toutes les tâches, part d'un cœur par minute | 11,6 % | 1,1 % |

Le serveur de CI de cette seconde exécution était environ deux fois plus
rapide (lectures 1 224 par seconde contre 659, les autres tâches deux fois plus
courtes). En corrigeant de ce facteur, le gain réel de cette tâche est d'environ
**7 fois** (≈ 3 250 ms attendus sans correction sur cette machine) ; sans
correction, il est de 15 fois. Lectures, saisies de score et cloisonnement :
aucun échec, aucune fuite.

## Reste à faire

- Mesurer sur la vraie base après publication (durée de `prediction-j5-reminders`
  dans `cron.job_run_details`).
- La tâche reste la plus lourde (≈ 2 ms par club et par passage) ; les autres
  tâches pèsent chacune moins de 65 ms pour 200 clubs.
