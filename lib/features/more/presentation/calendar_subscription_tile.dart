import 'dart:async';

import 'package:petit_filet/core/config/app_config.dart';
import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Le jeton est créé ou réutilisé pour l'abonné authentifié. Le flux ICS
/// reste identique : déplacer l'accès ne change pas les abonnements existants.
/// Extrait dans un provider pour tester le parcours sans contacter Supabase.
final calendarSubscriptionLinkProvider = Provider<Future<Uri> Function()>(
  (ref) {
    return () async {
      final client = ref.read(supabaseClientProvider);
      final rawToken = await client.rpc(
        'get_or_create_calendar_subscription_token',
      );
      final token = rawToken?.toString().trim() ?? '';
      if (token.isEmpty) {
        throw StateError('Le lien d’abonnement n’a pas pu être créé.');
      }

      return Uri.parse(
        '${AppConfig.supabaseUrl}/functions/v1/calendar-feed',
      ).replace(queryParameters: {'token': token});
    };
  },
);

/// Entrée permanente de « Mon compte » pour les joueurs comme les admins.
class CalendarSubscriptionTile extends ConsumerStatefulWidget {
  const CalendarSubscriptionTile({super.key});

  @override
  ConsumerState<CalendarSubscriptionTile> createState() =>
      _CalendarSubscriptionTileState();
}

class _CalendarSubscriptionTileState
    extends ConsumerState<CalendarSubscriptionTile> {
  bool _subscribing = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey('calendar-subscription-settings'),
      leading: Icon(
        Icons.calendar_month_outlined,
        color: AppTheme.primaryBright,
      ),
      title: const Text('Synchroniser mon calendrier'),
      trailing: _subscribing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _subscribing ? null : _subscribeCurrentSeason,
    );
  }

  /// Copie le lien ; un presse-papiers refusé ne doit jamais empêcher la
  /// suite (ouverture de l'abonnement, message).
  Future<bool> _copyCalendarLink(Uri uri) async {
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lance [uri] tout de suite, sans rien attendre avant : appelé après un
  /// await, Safari sur iPhone ne voyait plus le geste de l'utilisateur et
  /// bloquait l'ouverture sans aucune erreur. Sur le web, [webWindowName]
  /// « _self » ouvre le lien dans la page en cours plutôt que dans une
  /// nouvelle fenêtre, que l'iPhone peut aussi bloquer en silence.
  void _launchNow(Uri uri, {String? webWindowName}) {
    final launch = kIsWeb
        ? launchUrl(uri, webOnlyWindowName: webWindowName)
        : launchUrl(uri, mode: LaunchMode.externalApplication);
    unawaited(launch.catchError((Object _) => false));
  }

  Uri _subscribePageUri(Uri httpsUri) {
    final base = AppConfig.publicAppUrl.endsWith('/')
        ? AppConfig.publicAppUrl
        : '${AppConfig.publicAppUrl}/';
    return Uri.parse(
      '${base}abonnement-calendrier.html'
      '#feed=${Uri.encodeComponent(httpsUri.toString())}',
    );
  }

  /// Message avec un bouton : depuis Flutter 3.38, un SnackBar doté d'une
  /// action reste affiché tant qu'on ne le ferme pas, et bloque les messages
  /// suivants. Il est donc rendu temporaire, avec une croix pour le fermer.
  void _showActionMessage(
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 8),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        persist: false,
        showCloseIcon: true,
        content: Text(message),
        action: SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }

  void _openSubscribePage(Uri httpsUri) =>
      _launchNow(_subscribePageUri(httpsUri), webWindowName: '_self');

  Future<void> _openAppleCalendar(Uri httpsUri) async {
    // Le lien webcal ouvre l'abonnement ; le https, collé dans Safari,
    // proposait « Ajouter tous les événements », une copie unique qui ne se
    // met jamais à jour.
    final webcalUri = httpsUri.replace(scheme: 'webcal');
    // Dans la page en cours seulement sur les appareils Apple, qui savent
    // ouvrir un webcal : ailleurs (Firefox sans agenda associé), l'app serait
    // remplacée par une page d'erreur.
    final applePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    _launchNow(webcalUri, webWindowName: applePlatform ? '_self' : null);
    // La copie sert de filet : l'abonnement s'ouvre de lui-même, et la page
    // d'abonnement propose le lien si besoin.
    await _copyCalendarLink(webcalUri);
    if (!mounted) return;
    // Les étapes détaillées sont sur la page d'abonnement : le message n'a
    // plus à les répéter (il tenait sur 4 lignes pendant 20 secondes).
    _showActionMessage(
      'Pas de « S’abonner » dans Calendrier ? Ouvre la page d’abonnement.',
      actionLabel: 'Ouvrir',
      onAction: () => _openSubscribePage(httpsUri),
      duration: const Duration(seconds: 20),
    );
  }

  Future<void> _useGoogleCalendar(Uri httpsUri) async {
    final copied = await _copyCalendarLink(httpsUri);
    if (!mounted) return;
    // Google Agenda ne permet pas l'abonnement dans son appli : la page
    // d'abonnement explique la marche à suivre sur calendar.google.com.
    _showActionMessage(
      copied
          ? 'Lien copié. Google Agenda s’ajoute depuis un navigateur.'
          : 'Copie impossible. Ouvre la page d’abonnement pour copier le lien.',
      actionLabel: 'Ouvrir',
      onAction: () => _openSubscribePage(httpsUri),
    );
  }

  Future<void> _useOutlookCalendar(Uri httpsUri) async {
    // Outlook s'ouvre depuis le bouton du message, par un nouvel appui :
    // ouvert avant la copie, l'onglet Outlook prenait la main et le
    // navigateur refusait la copie ; ouvert après, Safari pouvait le bloquer.
    final copied = await _copyCalendarLink(httpsUri);
    if (!mounted) return;
    if (copied) {
      _showActionMessage(
        'Lien copié. Dans Outlook : Ajouter un calendrier > S’abonner à partir du web.',
        actionLabel: 'Outlook',
        onAction: () => _launchNow(
          Uri.parse('https://outlook.live.com/calendar/0/view/month'),
        ),
        duration: const Duration(seconds: 20),
      );
      return;
    }
    _showActionMessage(
      'Copie impossible. Ouvre la page d’abonnement pour copier le lien.',
      actionLabel: 'Ouvrir',
      onAction: () => _openSubscribePage(httpsUri),
    );
  }

  Future<void> _showCalendarSubscriptionChoices(Uri httpsUri) async {
    await showModalBottomSheet<void>(
      context: context,
      // Au-dessus de la barre de navigation du bas, sinon elle masque la fin
      // de la liste.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        Future<void> choose(Future<void> Function() action) async {
          Navigator.of(sheetContext).pop();
          await action();
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'S’abonner au calendrier',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Apple Calendrier'),
                  subtitle: const Text('iPhone, iPad et Mac'),
                  trailing: const Icon(Icons.chevron_right_outlined),
                  onTap: () => choose(() => _openAppleCalendar(httpsUri)),
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Google Agenda'),
                  subtitle: const Text(
                    'Android : abonnement à faire sur Google Agenda en version web',
                  ),
                  trailing: const Icon(Icons.content_copy_outlined),
                  onTap: () => choose(() => _useGoogleCalendar(httpsUri)),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outlined),
                  title: const Text('Outlook'),
                  subtitle: const Text('Outlook.com ou Outlook sur le web'),
                  trailing: const Icon(Icons.chevron_right_outlined),
                  onTap: () => choose(() => _useOutlookCalendar(httpsUri)),
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Copier le lien du calendrier'),
                  subtitle: const Text(
                    'Pour toute autre application compatible ICS',
                  ),
                  trailing: const Icon(Icons.content_copy_outlined),
                  onTap: () => choose(() async {
                    final copied = await _copyCalendarLink(httpsUri);
                    if (!mounted) return;
                    if (copied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lien du calendrier copié.'),
                        ),
                      );
                      return;
                    }
                    _showActionMessage(
                      'Copie impossible sur cet appareil. La page d’abonnement affiche le lien.',
                      actionLabel: 'Ouvrir',
                      onAction: () => _openSubscribePage(httpsUri),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _subscribeCurrentSeason() async {
    // Bloquer les appuis répétés pendant la récupération du jeton, puis
    // masquer le chargement AVANT d'afficher les choix du calendrier.
    // Un indicateur animé derrière la fenêtre empêcherait les tests UI
    // de se stabiliser et n'aurait plus d'utilité.
    if (_subscribing) return;
    setState(() => _subscribing = true);
    Uri? httpsUri;
    try {
      httpsUri = await ref.read(calendarSubscriptionLinkProvider)();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(humanizeError(error))));
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }

    if (!mounted || httpsUri == null) return;
    await _showCalendarSubscriptionChoices(httpsUri);
  }
}
