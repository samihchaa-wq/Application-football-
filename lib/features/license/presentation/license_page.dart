import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/billing/presentation/invoice_download.dart'
    show shareFile;
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/license/data/license_repository.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
// Chargé à la demande : la bibliothèque PDF reste hors du bundle principal.
import 'package:petit_filet/features/license/domain/license_pdf.dart'
    deferred as license_pdf;
import 'package:petit_filet/features/players/data/roster_repository.dart';

/// Espace « Licence » de l'admin : qui a payé sa licence, qui a payé l'autre
/// dépense demandée par le club, et l'attestation de licence en PDF.
class LicensePage extends ConsumerStatefulWidget {
  const LicensePage({super.key});

  @override
  ConsumerState<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends ConsumerState<LicensePage> {
  bool _onlyUnpaid = false;
  String _city = '';

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(PlayerLicense license, String seasonId) async {
    try {
      await ref.read(licenseRepositoryProvider).saveLicense(license);
      ref.invalidate(seasonLicensesProvider(seasonId));
    } catch (error) {
      _toast('Enregistrement impossible. ${humanizeError(error)}');
    }
  }

  Future<void> _editSettings(LicenseSettings current) async {
    final saved = await showDialog<LicenseSettings>(
      context: context,
      builder: (_) => _SettingsDialog(initial: current),
    );
    if (saved == null) return;
    try {
      await ref.read(licenseRepositoryProvider).saveSettings(saved);
      ref.invalidate(licenseSettingsProvider);
      _toast('Réglages enregistrés.');
    } catch (error) {
      _toast('Enregistrement impossible. ${humanizeError(error)}');
    }
  }

  Future<void> _attestation({
    required RosterPlayer player,
    required PlayerLicense license,
    required LicenseSettings settings,
    required String seasonId,
  }) async {
    final answer = await showDialog<({String city, String number})>(
      context: context,
      builder: (_) => _AttestationDialog(
        playerName: player.fullName,
        city: _city,
        number: license.licenseNumber,
      ),
    );
    if (answer == null) return;
    _city = answer.city;
    try {
      final repository = ref.read(licenseRepositoryProvider);
      final club = await ref.read(myClubProvider.future);
      final contact = await repository.clubContact();
      final seasonName = await repository.seasonName(seasonId);
      if (answer.number.trim() != license.licenseNumber.trim()) {
        await _save(
            license.copyWith(licenseNumber: answer.number.trim()), seasonId);
      }
      final data = LicenseAttestation(
        clubName: club.name,
        clubNumber: settings.clubNumber,
        clubAddress: contact.address,
        clubEmail: contact.email,
        presidentName: settings.presidentName,
        leagueName: settings.leagueName,
        playerName: player.fullName,
        licenseNumber: answer.number.trim(),
        seasonName: seasonName,
        amountCents: settings.licenseAmountCents,
        city: answer.city,
        date: DateTime.now(),
      );
      await license_pdf.loadLibrary();
      final bytes = await license_pdf.buildLicenseAttestationPdf(data);
      await shareFile(bytes, data.fileName, 'application/pdf');
    } catch (error) {
      _toast('Attestation impossible. ${humanizeError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(openSeasonIdProvider);
    return Scaffold(
      appBar: PfAppBar(title: const Text('Licence')),
      body: seasonAsync.when(
        loading: () => const Center(child: PfProgressIndicator()),
        error: (error, _) => _Message(
          'Impossible de charger la saison. ${humanizeError(error)}',
          onRetry: () => ref.invalidate(openSeasonIdProvider),
        ),
        data: (seasonId) => seasonId == null
            ? const _Message('Aucune saison ouverte.')
            : _body(seasonId),
      ),
    );
  }

  Widget _body(String seasonId) {
    final rosterAsync = ref.watch(rosterProvider(seasonId));
    final licensesAsync = ref.watch(seasonLicensesProvider(seasonId));
    final settingsAsync = ref.watch(licenseSettingsProvider);

    final error =
        rosterAsync.error ?? licensesAsync.error ?? settingsAsync.error;
    if (error != null) {
      return _Message(
        'Impossible de charger les licences. ${humanizeError(error)}',
        onRetry: () {
          ref.invalidate(rosterProvider(seasonId));
          ref.invalidate(seasonLicensesProvider(seasonId));
          ref.invalidate(licenseSettingsProvider);
        },
      );
    }
    final roster = rosterAsync.asData?.value;
    final licenses = licensesAsync.asData?.value;
    final settings = settingsAsync.asData?.value;
    if (roster == null || licenses == null || settings == null) {
      return const Center(child: PfProgressIndicator());
    }

    final players = roster.where((p) => p.isActive).toList()
      ..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    PlayerLicense of(RosterPlayer p) =>
        licenses[p.id] ?? PlayerLicense(seasonPlayerId: p.id);
    final licensePaid = players.where((p) => of(p).licensePaid).length;
    final otherPaid = players.where((p) => of(p).otherPaid).length;
    final shown = _onlyUnpaid
        ? players.where((p) => !of(p).licensePaid || !of(p).otherPaid).toList()
        : players;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rosterProvider(seasonId));
        ref.invalidate(seasonLicensesProvider(seasonId));
        ref.invalidate(licenseSettingsProvider);
        await ref.read(seasonLicensesProvider(seasonId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licences payées : $licensePaid / ${players.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${settings.otherTitle} payée : $otherPaid / ${players.length}',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editSettings(settings),
                        icon: const Icon(Icons.tune_outlined),
                        label: const Text('Réglages'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Impayés seulement'),
                        selected: _onlyUnpaid,
                        onSelected: (value) =>
                            setState(() => _onlyUnpaid = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  players.isEmpty
                      ? 'Aucun joueur dans l’effectif.'
                      : 'Tout le monde est à jour.',
                ),
              ),
            ),
          for (final player in shown)
            _PlayerLicenseCard(
              key: ValueKey(player.id),
              player: player,
              license: of(player),
              otherTitle: settings.otherTitle,
              onChanged: (next) => _save(next, seasonId),
              onAttestation: () => _attestation(
                player: player,
                license: of(player),
                settings: settings,
                seasonId: seasonId,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(text),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      );
}

class _PlayerLicenseCard extends StatelessWidget {
  const _PlayerLicenseCard({
    super.key,
    required this.player,
    required this.license,
    required this.otherTitle,
    required this.onChanged,
    required this.onAttestation,
  });

  final RosterPlayer player;
  final PlayerLicense license;
  final String otherTitle;
  final ValueChanged<PlayerLicense> onChanged;
  final VoidCallback onAttestation;

  @override
  Widget build(BuildContext context) {
    final number = license.licenseNumber.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            title: Text(
                player.fullName.isEmpty ? player.displayName : player.fullName),
            subtitle: Text(number.isEmpty
                ? 'N° de licence : à saisir'
                : 'N° de licence : $number'),
            trailing: IconButton(
              tooltip: 'Attestation de licence (PDF)',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: onAttestation,
            ),
          ),
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Licence payée'),
            value: license.licensePaid,
            onChanged: (value) =>
                onChanged(license.copyWith(licensePaid: value ?? false)),
          ),
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('$otherTitle payée'),
            value: license.otherPaid,
            onChanged: (value) =>
                onChanged(license.copyWith(otherPaid: value ?? false)),
          ),
        ],
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.initial});

  final LicenseSettings initial;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late final _clubNumber =
      TextEditingController(text: widget.initial.clubNumber);
  late final _president =
      TextEditingController(text: widget.initial.presidentName);
  late final _league = TextEditingController(text: widget.initial.leagueName);
  late final _amount = TextEditingController(
    text: formatLicenseAmount(widget.initial.licenseAmountCents),
  );
  late final _otherLabel =
      TextEditingController(text: widget.initial.otherLabel);
  late final _otherAmount = TextEditingController(
    text: formatLicenseAmount(widget.initial.otherAmountCents),
  );
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _clubNumber,
      _president,
      _league,
      _amount,
      _otherLabel,
      _otherAmount
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final amount = parseLicenseAmount(_amount.text);
    final other = parseLicenseAmount(_otherAmount.text);
    if (_amount.text.trim().isNotEmpty && amount == null ||
        _otherAmount.text.trim().isNotEmpty && other == null) {
      setState(() => _error = 'Montant invalide (exemple : 120 ou 12,50).');
      return;
    }
    final president = _president.text.trim();
    final league = _league.text.trim();
    final label = _otherLabel.text.trim();
    if ((president.isNotEmpty && president.length < 2) ||
        (league.isNotEmpty && league.length < 2) ||
        (label.isNotEmpty && label.length < 2)) {
      setState(
          () => _error = 'Les textes doivent faire au moins 2 caractères.');
      return;
    }
    Navigator.pop(
      context,
      LicenseSettings(
        clubNumber: _clubNumber.text,
        presidentName: president,
        leagueName: league,
        licenseAmountCents: amount,
        otherLabel: label,
        otherAmountCents: other,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label,
            {String? hint, TextInputType? type}) =>
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            controller: c,
            keyboardType: type,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );
    return AlertDialog(
      title: const Text('Réglages de la licence'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(_clubNumber, 'N° de club', hint: 'ex. 860395'),
            field(_president, 'Nom du président'),
            field(_league, 'Ligue', hint: 'ex. Ligue Occitanie de Football'),
            field(_amount, 'Montant de la licence (€)',
                hint: 'ex. 120', type: TextInputType.number),
            field(_otherLabel, 'Autre dépense demandée',
                hint: 'ex. Équipement'),
            field(_otherAmount, 'Montant de l’autre dépense (€)',
                type: TextInputType.number),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}

class _AttestationDialog extends StatefulWidget {
  const _AttestationDialog({
    required this.playerName,
    required this.city,
    required this.number,
  });

  final String playerName;
  final String city;
  final String number;

  @override
  State<_AttestationDialog> createState() => _AttestationDialogState();
}

class _AttestationDialogState extends State<_AttestationDialog> {
  late final _city = TextEditingController(text: widget.city);
  late final _number = TextEditingController(text: widget.number);

  @override
  void dispose() {
    _city.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Attestation de ${widget.playerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _number,
              decoration: const InputDecoration(labelText: 'N° de licence'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'Ville (pour « Toulouse le … »)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              (city: _city.text.trim(), number: _number.text.trim()),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Générer'),
          ),
        ],
      );
}
