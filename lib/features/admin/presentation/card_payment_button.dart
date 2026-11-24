import 'dart:async';

import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre la page de paiement sécurisée de Stripe. Remplaçable dans les tests.
typedef OpenPaymentPage = Future<bool> Function(Uri url);

Future<bool> _openInSamePage(Uri url) {
  // Sur le web, « _self » remplace la page : pas de fenêtre bloquée par
  // l'iPhone, et Stripe renvoie ensuite vers l'écran Abonnement.
  return kIsWeb
      ? launchUrl(url, webOnlyWindowName: '_self')
      : launchUrl(url, mode: LaunchMode.externalApplication);
}

final openPaymentPageProvider = Provider<OpenPaymentPage>(
  (ref) => _openInSamePage,
);

/// « Payer par carte », ou « Activer mon année offerte » quand le parrainage
/// couvre tout le montant ([amountDueCents] = 0).
class CardPaymentButton extends ConsumerStatefulWidget {
  const CardPaymentButton({super.key, this.amountDueCents});

  /// Montant à payer s'il est connu (sinon libellé sans montant).
  final int? amountDueCents;

  @override
  ConsumerState<CardPaymentButton> createState() => _CardPaymentButtonState();
}

class _CardPaymentButtonState extends ConsumerState<CardPaymentButton> {
  bool _busy = false;

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final url =
          await ref.read(clubSubscriptionRepositoryProvider).startCardPayment();
      final opened = await ref.read(openPaymentPageProvider)(url);
      if (!opened) _show('La page de paiement n’a pas pu s’ouvrir.');
    } catch (error) {
      _show(humanizeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimFreeYear() async {
    setState(() => _busy = true);
    try {
      await ref.read(clubSubscriptionRepositoryProvider).claimFreeYear();
      ref.invalidate(clubSubscriptionProvider);
      ref.invalidate(clubReferralsProvider);
      ref.invalidate(myClubAccessProvider);
      _show('Année offerte activée. Merci pour tes parrainages !');
    } catch (error) {
      _show(humanizeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.amountDueCents;
    if (amount == 0) {
      return FilledButton.icon(
        key: const Key('club-claim-free-year'),
        onPressed: _busy ? null : _claimFreeYear,
        icon: const Icon(Icons.card_giftcard_outlined),
        label: Text(_busy ? 'Activation…' : 'Activer mon année offerte'),
      );
    }
    return FilledButton.icon(
      key: const Key('club-pay-by-card'),
      onPressed: _busy ? null : () => unawaited(_pay()),
      icon: const Icon(Icons.credit_card_outlined),
      label: Text(
        _busy
            ? 'Ouverture du paiement…'
            : amount == null
                ? 'Payer par carte'
                : 'Payer ${formatEuros(amount)} par carte',
      ),
    );
  }
}
