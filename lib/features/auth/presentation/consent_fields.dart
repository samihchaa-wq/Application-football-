import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Déclaration d'âge et acceptation des CGU, obligatoires pour s'inscrire.
class ConsentFields extends StatelessWidget {
  const ConsentFields({
    super.key,
    required this.ageConfirmation,
    required this.acceptedTerms,
    required this.enabled,
    required this.onAgeChanged,
    required this.onTermsChanged,
  });

  final AgeConfirmation? ageConfirmation;
  final bool acceptedTerms;
  final bool enabled;
  final ValueChanged<AgeConfirmation?> onAgeChanged;
  final ValueChanged<bool> onTermsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<AgeConfirmation>(
          groupValue: ageConfirmation,
          onChanged: (value) {
            if (enabled) onAgeChanged(value);
          },
          child: const Column(
            children: [
              RadioListTile<AgeConfirmation>(
                key: Key('register-age-15-or-more'),
                contentPadding: EdgeInsets.zero,
                title: Text('J’ai 15 ans ou plus'),
                value: AgeConfirmation.fifteenOrMore,
              ),
              RadioListTile<AgeConfirmation>(
                key: Key('register-age-parental-consent'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'J’ai moins de 15 ans et un de mes parents est d’accord',
                ),
                value: AgeConfirmation.parentalConsent,
              ),
            ],
          ),
        ),
        CheckboxListTile(
          key: const Key('register-accept-terms'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: acceptedTerms,
          onChanged: enabled ? (value) => onTermsChanged(value ?? false) : null,
          title: const Text(
            'J’accepte les conditions d’utilisation et la politique de '
            'confidentialité',
          ),
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => context.push('/legal/cgu'),
              child: const Text('Lire les conditions'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/confidentialite'),
              child: const Text('Lire la politique de confidentialité'),
            ),
          ],
        ),
      ],
    );
  }
}
