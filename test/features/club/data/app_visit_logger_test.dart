import 'package:petit_filet/features/club/data/app_visit_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one call per day, retried after a failure', () async {
    var now = DateTime(2026, 11, 18, 9);
    var calls = 0;
    var fail = true;
    final logger = AppVisitLogger(
      () async {
        calls++;
        if (fail) throw StateError('offline');
      },
      clock: () => now,
    );

    await logger.log();
    expect(calls, 1);
    fail = false;
    await logger.log();
    expect(calls, 2, reason: 'a failed visit is retried');
    await logger.log();
    now = DateTime(2026, 11, 18, 23, 59);
    await logger.log();
    expect(calls, 2, reason: 'same day: nothing more is sent');
    now = DateTime(2026, 11, 19, 0, 1);
    await logger.log();
    expect(calls, 3, reason: 'next day: one new visit');
  });
}
