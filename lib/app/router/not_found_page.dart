import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_empty_state.dart';

/// Page affichée pour une adresse que l'appli ne connaît pas.
///
/// Avant, l'écran ne montrait guère qu'un bouton : la personne ne savait pas
/// si l'appli avait planté ou si le lien était mauvais. Le titre dans la
/// barre du haut le dit tout de suite, et le message rappelle l'adresse.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.location});

  /// Adresse demandée, montrée telle quelle pour qu'on reconnaisse le lien.
  final String? location;

  @override
  Widget build(BuildContext context) {
    final address = location?.trim() ?? '';
    return Scaffold(
      appBar: PfAppBar(title: const Text('Page introuvable')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: PfEmptyState(
              key: const Key('not-found-page'),
              icon: Icons.explore_off_outlined,
              title: 'Page introuvable',
              message: address.isEmpty
                  ? 'Cette adresse n’existe pas ou n’est plus disponible.'
                  : 'L’adresse « $address » n’existe pas ou n’est plus '
                      'disponible.',
              action: FilledButton(
                onPressed: () => context.go('/matches'),
                child: const Text('Retour au calendrier'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
