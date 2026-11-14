/// Le mode appartient à l'objet photo : il voyage avec sa référence dans les
/// RPC, les caches et les URLs signées. Mode et image sont enregistrés ensemble,
/// sans état local ni modification des dossiers contrôlés par RLS.
enum PlayerPhotoMode {
  player('player', 'Type joueur'),
  other('other', 'Autre');

  const PlayerPhotoMode(this.storageTag, this.label);
  final String storageTag;
  final String label;
  String filename(int stamp, String extension) =>
      'avatar_${storageTag}_$stamp.$extension';
  static PlayerPhotoMode fromPhotoUrl(String? value) {
    final path = Uri.tryParse(value?.trim() ?? '')?.path ?? '';
    final filename = path.split('/').last;
    // Les portraits existants conservent leur rendu Type joueur.
    return RegExp(r'^avatar_other_[0-9]+\.(png|jpg|jpeg|webp)$')
            .hasMatch(filename)
        ? other
        : player;
  }
}
