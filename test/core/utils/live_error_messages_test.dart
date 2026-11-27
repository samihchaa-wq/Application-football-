import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Messages du Live levés en anglais par le serveur : jamais de nom de club
/// figé (« AS Grinta ») ni de message générique quand on sait quoi dire.
void main() {
  String humanize(String message, [String code = '22023']) =>
      humanizeError(PostgrestException(message: message, code: code));

  test('buteur sur un but adverse : sans nom de club', () {
    final text = humanize('Only an AS Grinta goal can have a scorer');
    expect(text, 'Seul un but de ton équipe peut avoir un buteur.');
    expect(text, isNot(contains('Grinta')));
  });

  test('trop de buteurs : sans nom de club', () {
    final text = humanize('Attributed goals exceed the AS Grinta score');
    expect(text, contains('ton équipe'));
    expect(text, isNot(contains('Grinta')));
  });

  test('action supprimée entre-temps', () {
    expect(
      humanize('Event not found', 'P0002'),
      'Cette action du match a déjà été supprimée.',
    );
  });

  test('coup d’envoi manquant', () {
    expect(humanize('Match kickoff is required'), contains('coup d’envoi'));
  });

  test('Live pas encore ouvert : message serveur gardé tel quel', () {
    expect(
      humanize('Le Live n’est pas encore ouvert.'),
      'Le Live n’est pas encore ouvert.',
    );
  });
}
