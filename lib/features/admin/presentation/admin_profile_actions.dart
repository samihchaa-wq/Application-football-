part of 'admin_page.dart';

class _PendingProfileActions extends StatelessWidget {
  const _PendingProfileActions({
    required this.profile,
    required this.onValidate,
    required this.onReject,
  });

  final AdminProfileItem profile;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  String get _name {
    final full = profile.fullName.trim();
    return full.isEmpty ? profile.username : full;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le nom dans le libellé lu : avec plusieurs demandes, « Valider ce
        // compte » seul ne disait pas lequel.
        Semantics(
          label: 'Valider le compte de $_name',
          button: true,
          excludeSemantics: true,
          onTap: onValidate,
          child: FilledButton(
            onPressed: onValidate,
            child: const Text('Valider ce compte'),
          ),
        ),
        Semantics(
          label: 'Refuser et supprimer le compte de $_name',
          button: true,
          excludeSemantics: true,
          onTap: onReject,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: onReject,
            child: const Text('Refuser et supprimer'),
          ),
        ),
      ],
    );
  }
}
