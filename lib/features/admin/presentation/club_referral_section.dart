import 'package:petit_filet/core/config/app_config.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Parrainage, dans la carte Abonnement des réglages du club : comment ça
/// marche, le code du club à partager, et les clubs déjà parrainés.
class ClubReferralSection extends ConsumerWidget {
  const ClubReferralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referrals = ref.watch(clubReferralsProvider);
    return referrals.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) =>
          const Text('Impossible de charger le parrainage pour le moment.'),
      data: (value) => value == null || value.code.isEmpty
          ? const SizedBox.shrink()
          : _ReferralCard(referrals: value),
    );
  }
}

String referralShareText(String code) {
  final url =
      AppConfig.publicAppUrl.isEmpty ? '' : ' sur ${AppConfig.publicAppUrl}';
  return 'Ton club peut gérer ses matchs, présences et compositions avec '
      'Petit Filet. Crée ton club$url et saisis le code parrain $code.';
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referrals});

  final ClubReferrals referrals;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: referrals.code));
    messenger.showSnackBar(
      const SnackBar(content: Text('Code parrain copié.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = referrals.ratePercent;
    final cap = referrals.capPercent;
    final maxClubs = rate > 0 ? cap ~/ rate : 0;
    return Card(
      key: const Key('club-referral-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parrainage', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Fais découvrir Petit Filet à un autre club. Pour chaque club '
              'qui s’inscrit avec ton code et paie son abonnement, ton club '
              'gagne −$rate\u00A0% sur son prochain renouvellement, jusqu’à '
              '−$cap\u00A0%${cap >= 100 ? ' : $maxClubs clubs parrainés, et '
                  'l’année est offerte' : ''}. Le club parrainé a lui aussi '
              '−$rate\u00A0% sur sa première année.',
              key: const Key('club-referral-explanation'),
            ),
            const SizedBox(height: 12),
            Text('Ton code parrain', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    referrals.code,
                    key: const Key('club-referral-code'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('club-referral-copy'),
                  tooltip: 'Copier le code',
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  key: const Key('club-referral-share'),
                  tooltip: 'Partager le code',
                  onPressed: () =>
                      Share.share(referralShareText(referrals.code)),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            if (referrals.discountPercent > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Réduction acquise : −${referrals.discountPercent}\u00A0% sur le '
                'prochain renouvellement.',
                key: const Key('club-referral-discount'),
                style: theme.textTheme.titleSmall,
              ),
            ],
            if (referrals.referredBy != null) ...[
              const SizedBox(height: 8),
              Text(
                referrals.welcomePercent > 0
                    ? 'Ton club a été parrainé par ${referrals.referredBy} : '
                        '−${referrals.welcomePercent}\u00A0% sur ta première année.'
                    : 'Ton club a été parrainé par ${referrals.referredBy}.',
                key: const Key('club-referral-referred-by'),
              ),
            ],
            const SizedBox(height: 12),
            Text('Clubs parrainés', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            if (referrals.referrals.isEmpty)
              const Text(
                'Aucun pour l’instant.',
                key: Key('club-referral-empty'),
              )
            else
              for (final referral in referrals.referrals)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    referral.state == ClubReferralState.trial
                        ? Icons.hourglass_empty
                        : Icons.check_circle_outline,
                  ),
                  title: Text(referral.clubName),
                  subtitle: Text(_stateLabel(referral.state, rate)),
                ),
          ],
        ),
      ),
    );
  }
}

String _stateLabel(ClubReferralState state, int rate) => switch (state) {
      ClubReferralState.trial => 'En essai : compte dès son premier paiement',
      ClubReferralState.paid => 'Abonné : −$rate\u00A0% acquis',
      ClubReferralState.used => 'Abonné : réduction déjà utilisée',
    };
