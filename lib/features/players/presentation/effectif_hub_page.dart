import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_secondary_tabs.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/players/presentation/club_roster_page.dart';
import 'package:petit_filet/features/players/presentation/players_registry_page.dart';

/// Un seul écran « Effectif ». Tout le monde voit l'annuaire du club ; un
/// administrateur a en plus la gestion des joueurs et des inscriptions, en
/// onglets au lieu de trois écrans séparés.
class EffectifHubPage extends ConsumerStatefulWidget {
  const EffectifHubPage({
    super.key,
    this.initialTab = 0,
    required this.registrationsBuilder,
  });

  final int initialTab;

  /// Onglet « Inscriptions » (chargé à la demande par le routeur).
  final WidgetBuilder registrationsBuilder;

  @override
  ConsumerState<EffectifHubPage> createState() => _EffectifHubPageState();
}

class _EffectifHubPageState extends ConsumerState<EffectifHubPage> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminViewProvider);
    if (!isAdmin) return const ClubRosterPage();
    final tab = _tab.clamp(0, 2);
    return Scaffold(
      appBar: PfAppBar(title: const Text('Effectif')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          PfSecondaryTabs<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Annuaire')),
              ButtonSegment(value: 1, label: Text('Joueurs')),
              ButtonSegment(value: 2, label: Text('Inscriptions')),
            ],
            selected: {tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          Expanded(
            child: switch (tab) {
              0 => const ClubRosterPage(embedded: true),
              1 => const PlayersRegistryPage(embedded: true),
              _ => widget.registrationsBuilder(context),
            },
          ),
        ],
      ),
    );
  }
}
