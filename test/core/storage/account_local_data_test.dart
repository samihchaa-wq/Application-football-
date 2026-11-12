import 'package:as_grinta/core/storage/account_local_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('la déconnexion efface les copies locales du compte', () async {
    SharedPreferences.setMockInitialValues({
      'calendar_matches_v1_compte-a': '[{"id":"m1"}]',
      'calendar_history_all_v2': '[{"opponent_name":"Adversaire A"}]',
      'club_events_v1': '[]',
      'theme_mode': 'dark',
    });

    await AccountLocalData.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'theme_mode'});
  });
}
