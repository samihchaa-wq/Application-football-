import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/auth/data/mfa_repository.dart';
import 'package:qr/qr.dart';
import 'package:url_launcher/url_launcher.dart';

/// Double authentification d'un administrateur : activer ou désactiver.
///
/// Proposée, pas obligatoire (audit du 26/11/2026, point 39). Une fois
/// activée, le code est demandé avant les actions sensibles sur les comptes.
class TwoFactorPage extends ConsumerStatefulWidget {
  const TwoFactorPage({super.key});

  @override
  ConsumerState<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends ConsumerState<TwoFactorPage> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _factorId;
  TotpEnrollmentStart? _pending;
  String? _error;
  String? _success;

  MfaRepository get _repository => ref.read(mfaRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final id = await _repository.verifiedTotpFactorId();
      if (!mounted) return;
      setState(() {
        _factorId = id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mfaErrorMessage(error);
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = mfaErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _run(() async {
        final pending = await _repository.startEnrollment();
        if (!mounted) return;
        _codeController.clear();
        setState(() => _pending = pending);
      });

  Future<void> _confirm() => _run(() async {
        final pending = _pending;
        if (pending == null) return;
        final code = _codeController.text.replaceAll(' ', '');
        if (!isValidTotpCode(code)) {
          throw StateError('Le code contient 6 chiffres.');
        }
        await _repository.confirmEnrollment(
          factorId: pending.factorId,
          code: code,
        );
        if (!mounted) return;
        setState(() {
          _pending = null;
          _factorId = pending.factorId;
          _success = 'Double authentification activée.';
        });
      });

  Future<void> _cancel() => _run(() async {
        final pending = _pending;
        if (pending != null) await _repository.removeFactor(pending.factorId);
        if (!mounted) return;
        setState(() => _pending = null);
      });

  Future<void> _disable() async {
    final factorId = _factorId;
    if (factorId == null) return;
    final code = await askTwoFactorCode(
      context,
      title: 'Désactiver la double authentification',
      message: 'Saisis un code de ton application pour confirmer.',
    );
    if (code == null || !mounted) return;
    await _run(() async {
      await _repository.verifyCode(code);
      await _repository.removeFactor(factorId);
      if (!mounted) return;
      setState(() {
        _factorId = null;
        _success = 'Double authentification désactivée.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = _pending;
    return Scaffold(
      appBar: PfAppBar(title: const Text('Double authentification')),
      body: _loading
          ? const Center(child: PfProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'En plus du mot de passe, un code à 6 chiffres '
                        'affiché par une application d’authentification '
                        '(Google Authenticator, Microsoft Authenticator, '
                        '1Password…) est demandé avant les actions sensibles '
                        'sur les comptes : lien de nouveau mot de passe, '
                        'suppression d’un compte.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (pending != null)
                        ..._enrollmentSteps(context, pending)
                      else if (_factorId != null) ...[
                        _StatusLine(
                          icon: Icons.verified_user_outlined,
                          text: 'Activée sur ce compte.',
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _busy ? null : _disable,
                          child: const Text('Désactiver'),
                        ),
                      ] else ...[
                        const _StatusLine(
                          icon: Icons.shield_outlined,
                          text: 'Pas encore activée.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _busy ? null : _start,
                          icon: const Icon(Icons.add_moderator_outlined),
                          label: const Text('Activer'),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      if (_success != null) ...[
                        const SizedBox(height: 12),
                        Text(_success!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _enrollmentSteps(
    BuildContext context,
    TotpEnrollmentStart pending,
  ) {
    final theme = Theme.of(context);
    return [
      Text(
        '1. Scanne ce QR code avec ton application d’authentification.',
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
      Center(child: TotpQrCode(data: pending.uri, size: 200)),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(pending.uri)),
            child: const Text('Ouvrir sur ce téléphone'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pending.secret));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clé copiée.')),
              );
            },
            child: const Text('Copier la clé'),
          ),
        ],
      ),
      SelectableText(
        pending.secret,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      Text(
        '2. Saisis le code à 6 chiffres affiché.',
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 7,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
        decoration: const InputDecoration(labelText: 'Code à 6 chiffres'),
        onSubmitted: (_) => _busy ? null : _confirm(),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _busy ? null : _confirm,
        child: const Text('Valider'),
      ),
      TextButton(
        onPressed: _busy ? null : _cancel,
        child: const Text('Annuler'),
      ),
    ];
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// QR code dessiné localement : la clé ne quitte jamais l'appareil.
class TotpQrCode extends StatelessWidget {
  const TotpQrCode({super.key, required this.data, this.size = 200});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
    return Semantics(
      label: 'QR code de la double authentification',
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: CustomPaint(
          size: Size.square(size),
          painter: _QrPainter(image),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final cell = size.width / count;
    final paint = Paint()..color = Colors.black;
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell + .5, cell + .5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}

/// Demande le code à 6 chiffres. Retourne null si la personne annule.
Future<String?> askTwoFactorCode(
  BuildContext context, {
  String title = 'Code de sécurité',
  String message =
      'Saisis le code à 6 chiffres de ton application d’authentification.',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TwoFactorCodeDialog(title: title, message: message),
  );
}

class _TwoFactorCodeDialog extends StatefulWidget {
  const _TwoFactorCodeDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_TwoFactorCodeDialog> createState() => _TwoFactorCodeDialogState();
}

class _TwoFactorCodeDialogState extends State<_TwoFactorCodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.replaceAll(' ', '');
    if (!isValidTotpCode(code)) {
      setState(() => _error = 'Le code contient 6 chiffres.');
      return;
    }
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 7,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            ],
            decoration: InputDecoration(
              labelText: 'Code à 6 chiffres',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}

/// Avant une action sensible d'admin : si la double authentification est
/// activée et que le code n'a pas encore été saisi dans cette session, le
/// demande. Retourne false si la personne annule ou si le code est refusé
/// (un message est alors affiché).
Future<bool> confirmTwoFactorForSensitiveAction(
  BuildContext context,
  WidgetRef ref,
) async {
  final MfaRepository repository;
  final bool needed;
  try {
    repository = ref.read(mfaRepositoryProvider);
    needed = repository.needsCodeForSensitiveAction();
  } catch (_) {
    // Sans session lisible, le serveur tranchera.
    return true;
  }
  if (!needed) return true;
  final code = await askTwoFactorCode(context);
  if (code == null) return false;
  try {
    await repository.verifyCode(code);
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mfaErrorMessage(error))),
      );
    }
    return false;
  }
}
