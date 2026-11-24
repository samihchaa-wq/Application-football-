import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// « Finir la saison » refusé par le serveur : l'administrateur doit savoir
/// quoi faire, pas seulement que c'est impossible.
void main() {
  test('fenêtre de correction : dire d’attendre 24 h', () {
    const error = PostgrestException(
      message: 'Une saison ne peut pas être archivée pendant une fenêtre de '
          'correction de match.',
      code: '22023',
    );
    expect(
      humanizeError(error),
      'Un match validé il y a moins de 24 h peut encore être corrigé. '
      'Tu pourras finir la saison une fois ce délai passé.',
    );
  });

  test('matchs restants : dire de les valider ou les annuler', () {
    const error = PostgrestException(
      message:
          'Une saison avec des matchs non terminés ne peut pas être archivée.',
      code: '22023',
    );
    expect(humanizeError(error), contains('Valide-les ou annule-les'));
  });

  test('les autres messages de correction restent inchangés', () {
    const error = PostgrestException(
      message: 'La fenêtre de correction du match est fermée.',
      code: '22023',
    );
    expect(
      humanizeError(error),
      'La fenêtre de correction du match est fermée.',
    );
  });

  test('saison terminée qu’on tente de rouvrir : proposer un autre nom', () {
    const error = PostgrestException(
      message:
          'Une saison avec des données de compétition ne peut pas être rouverte.',
      code: '22023',
    );
    expect(humanizeError(error), contains('Choisis un autre nom'));
  });
}
