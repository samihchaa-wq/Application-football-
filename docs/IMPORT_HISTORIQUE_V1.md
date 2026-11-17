# Import des matchs historiques — contrat Petit Filet v1

## Règles
- Une **équipe** importe un fichier `.json` généré à partir de ses propres données (SportEasy ou autre source). Petit Filet ne collecte pas les identifiants SportEasy, et n'en extrait aucune donnée directement.
- Accès réservé aux administrateurs, dans l'équipe courante. Prévisualisation et confirmation avant modification.
- Maximum **400 matchs** par document, jusqu’à aujourd’hui, y compris dans les saisons déjà suivies, en rejetant les conflits avec les matchs existants. Les doublons identiques sont ignorés ; les conflits de score sur une même date et contre le même adversaire bloquent le lot.
- Aucun champ inconnu ne doit recevoir une valeur imaginée. Les joueurs sans association explicite sont rapprochés uniquement par leur **nom complet exact et non ambigu**.
- Validation du document et du format côté application **et** serveur. La transaction côté serveur doit être atomique : erreur = aucun match du lot importé. Des contrôles de charge doivent être faits sur 350 matchs.
- Ne pas déposer sur GitHub d'exports réels contenant noms, photos ou informations personnelles. Les exports d'équipes doivent être réalisés conformément aux droits applicables.

## Contrat JSON

```json
{
  "format": "petit-filet-historique",
  "version": 1,
  "matches": [
    {
      "date": "2024-10-20",
      "opponent": "Exemple FC",
      "score_for": 3,
      "score_against": 1,
      "is_home": true,
      "match_type": "championnat",
      "time": "15:00",
      "address": "Stade municipal",
      "present": [{"name":"Alex Martin"},{"name":"Morgan Dupont"}],
      "scorers": [{"name":"Alex Martin","goals":2}],
      "motm": [{"name":"Morgan Dupont"}],
      "formation": "4-4-2",
      "starters": [{"name":"Alex Martin","position_code":"ATT","x_pct":50,"y_pct":20}],
      "bench": [{"name":"Morgan Dupont"}]
    }
  ]
}
```

`date`, `opponent`, `score_for` et `score_against` sont obligatoires. `is_home` et `match_type` sont facultatifs : les omettre si inconnus. Scores en nombres entiers 0–99. Date ISO AAAA-MM-JJ. `is_home` est relatif à l'équipe qui importe ; `match_type` vaut `championnat` ou `amical`. Les listes de joueurs, `time`, `address` et `formation` sont facultatives. Une présence ne doit être ajoutée que si elle est justifiée par la source. Les compositions ne doivent pas être reconstruites sans preuve. Les noms doivent rester constants d'un match à l'autre.

## Prompt à donner à l'IA du club

> Convertis les données de matchs historiques que je te fournis en un unique fichier JSON compatible avec Petit Filet.
>
> Mon équipe s'appelle : [NOM DE L'ÉQUIPE].
>
> Utilise exclusivement les informations présentes dans mes documents. **N'invente jamais** de match, de date, de score, de joueur, de buteur, d'homme du match, de domicile/extérieur ou de composition. Si un match n'a pas de date, d'adversaire ou de score fiable, exclus-le et indique-le séparément. Pour les autres données inconnues, omets simplement leurs propriétés.
>
> Le fichier de sortie doit être du JSON UTF-8 valide, sans commentaire ni balises Markdown, avec exactement un objet racine : `{"format":"petit-filet-historique","version":1,"matches":[...]}`.
>
> Pour chaque match, écris obligatoirement `date` au format AAAA-MM-JJ, `opponent` (adversaire seulement), `score_for` et `score_against` (nombres entiers du point de vue de mon équipe). Tu peux ajouter `is_home` (booléen) et `match_type` (seulement `"championnat"` ou `"amical"`) uniquement s'ils sont connus ; tu peux également ajouter `time` (`HH:MM`), `address`, `present` (tableau d'objets `{"name":"Prénom Nom"}`), `scorers` (`{"name":"Prénom Nom","goals":2}`), `motm` (`{"name":"Prénom Nom"}`), `formation`, `starters` et `bench`. Les compositions incluent uniquement les placements documentés ; chaque titulaire peut avoir `position_code`, `x_pct`, `y_pct` si connus.
>
> Si le lieu, l'heure, les listes de joueurs ou les buteurs sont inconnus, **omets les champs** concernés. Si le mode domicile/extérieur ou le type de match est inconnu, **omets ces champs**. Aucun champ optionnel inconnu ne doit être inventé. Uniformise uniquement les variantes évidentes d'un même nom, sans fusionner les homonymes.
>
> Regroupe les matchs en ordre chronologique, supprime uniquement les doublons strictement identiques, et signale séparément les dates, scores ou identités ambigus. N'insère aucune donnée personnelle non nécessaire (e-mail, téléphone, adresse personnelle, identifiant de compte, commentaire privé). Le résultat doit pouvoir être enregistré tel quel sous `historique_petit_filet.json`.

## Parcours QA minimum
- 350 matchs, import atomique, reconnection, doublons et conflit de score.
- Admin A équipe A, joueur A, admin B équipe B : aucune contamination interéquipes.
- Vérifier noms identiques, anciens joueurs, saison déjà suivie, dates invalides, score 99, liste énorme, fichier malformé.
- Vérifier calendrier, fiche archivée, statistiques, cotes, détails de match et aucun impact sur les pronostics des saisons suivies.
- Aucun import réel en production sans validation spécifique.

**Saisons déjà suivies (décision 3B) :** l'import doit accepter les anciens matchs datés avant aujourd'hui même si la saison existe déjà. Détecter les matchs déjà présents dans le calendrier moderne et l'archive du club avant insertion, et éviter tout double comptage statistique. Tant que les vues de statistiques toutes périodes et les tests de non-régression ne sont pas validés, ne pas fusionner/déployer.
