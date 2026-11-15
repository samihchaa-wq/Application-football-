import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:as_grinta/features/matches/presentation/widgets/kit_jersey.dart';
import 'package:flutter/material.dart';

/// Vignette d'un maillot proposé pour un match, avec sa coche quand il est
/// choisi. Partagée par le formulaire de création et celui de modification
/// d'un match.
/// Rangée des maillots proposés. Chaque vignette prend une part égale de la
/// largeur disponible, pour que les maillots restent sur une seule ligne quelle
/// que soit la taille de l'écran (plafonnés pour ne pas devenir énormes sur
/// tablette).
class JerseyOptionPicker extends StatelessWidget {
  const JerseyOptionPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final JerseyOption? selected;

  /// Reçoit le maillot choisi, ou `null` quand on retape sur celui déjà
  /// sélectionné. `null` désactive la sélection.
  final ValueChanged<JerseyOption?>? onChanged;

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ClubKits.revision,
      builder: (context, _, __) => _buildRow(),
    );
  }

  Widget _buildRow() {
    // Les maillots proposés par le club, plus celui déjà choisi pour ce match
    // s'il a été retiré depuis : il reste visible et désélectionnable.
    final options = [
      for (final option in JerseyOption.values)
        if (option.kit.enabled || option == selected) option,
    ];
    // Le nombre de maillots n'est plus plafonné : défilement horizontal
    // plutôt qu'une rangée qui devient illisible ou déborde.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: _spacing),
            SizedBox(
              width: 108,
              child: JerseyOptionTile(
                option: options[i],
                selected: selected == options[i],
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(
                          selected == options[i] ? null : options[i],
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class JerseyOptionTile extends StatelessWidget {
  const JerseyOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final JerseyOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 96 / 128,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 20,
              child: Center(
                child: SizedBox(
                  width: 88,
                  child: Stack(
                    children: [
                      // Le choix concerne la tenue du match : celle des
                      // joueurs. Le gardien porte sa déclinaison automatique.
                      KitJersey(kit: option.kit),
                      if (selected)
                        Positioned(
                          top: 35,
                          right: 22,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? accent : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
