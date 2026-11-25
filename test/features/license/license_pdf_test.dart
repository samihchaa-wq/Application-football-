import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
import 'package:petit_filet/features/license/domain/license_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('montants : lecture et affichage', () {
    expect(parseLicenseAmount('120'), 12000);
    expect(parseLicenseAmount('12,5 €'), 1250);
    expect(parseLicenseAmount(''), isNull);
    expect(parseLicenseAmount('abc'), isNull);
    expect(formatLicenseAmount(12000), '120 €');
    expect(formatLicenseAmount(1250), '12,50 €');
    expect(formatLicenseAmount(null), '');
  });

  test('date en toutes lettres', () {
    expect(formatLongFrenchDate(DateTime(2025, 11, 8)), '8 novembre 2025');
  });

  test('l’attestation est un PDF', () async {
    final data = LicenseAttestation(
      clubName: 'AS La Grinta',
      clubNumber: '860395',
      clubAddress: '82, rue de la fontaine des Cerdans, 31520 Ramonville',
      clubEmail: 'asso@example.org',
      presidentName: 'Samuel Granier',
      leagueName: 'Ligue Occitanie de Football',
      playerName: 'Samih Chaa',
      licenseNumber: '88213112',
      seasonName: '2025-26',
      amountCents: 12000,
      city: 'Toulouse',
      date: DateTime(2025, 11, 8),
    );
    final bytes = await buildLicenseAttestationPdf(data);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(data.fileName, 'attestation-licence-samih-chaa.pdf');
  });
}
