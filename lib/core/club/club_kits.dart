import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum KitPattern {
  plain('Uni'),
  stripes('Rayures verticales'),
  hoops('Bandes horizontales'),
  sash('Bande diagonale');

  const KitPattern(this.label);
  final String label;

  static KitPattern fromJson(Object? value) => values.firstWhere(
        (pattern) => pattern.name == value,
        orElse: () => plain,
      );
}

/// Un maillot du club : son nom, ses deux couleurs et s'il est proposé.
@immutable
class ClubKit {
  const ClubKit({
    required this.slot,
    required this.label,
    required this.body,
    required this.trim,
    this.goalkeeperBody = const Color(0xFF168A52),
    this.goalkeeperTrim = const Color(0xFFFFFFFF),
    this.pattern = KitPattern.plain,
    this.goalkeeperPattern = KitPattern.plain,
    this.dressPlayers = false,
    this.archived = false,
    required this.enabled,
  });

  /// Emplacement technique (jamais affiché) : relie le maillot aux matchs déjà
  /// enregistrés et aux photos de maillot des joueurs.
  final JerseyOption slot;
  final String label;

  /// Couleur du corps du maillot.
  final Color body;

  /// Couleur des manches et du col.
  final Color trim;

  /// Couleurs du gardien distinctes de celles des joueurs de champ.
  final Color goalkeeperBody;
  final Color goalkeeperTrim;
  final KitPattern pattern;
  final KitPattern goalkeeperPattern;

  /// Option du club, conservée dans la tenue figée du match. Les anciennes
  /// photos restent intactes ; le maillot est composé uniquement à l'écran.
  final bool dressPlayers;
  /// Une tenue supprimée reste en base pour les anciens matchs.
  final bool archived;
  final bool enabled;

  ClubKit copyWith({
    String? label,
    Color? body,
    Color? trim,
    Color? goalkeeperBody,
    Color? goalkeeperTrim,
    KitPattern? pattern,
    KitPattern? goalkeeperPattern,
    bool? dressPlayers,
    bool? archived,
    bool? enabled,
  }) =>
      ClubKit(
        slot: slot,
        label: label ?? this.label,
        body: body ?? this.body,
        trim: trim ?? this.trim,
        goalkeeperBody: goalkeeperBody ?? this.goalkeeperBody,
        goalkeeperTrim: goalkeeperTrim ?? this.goalkeeperTrim,
        pattern: pattern ?? this.pattern,
        goalkeeperPattern: goalkeeperPattern ?? this.goalkeeperPattern,
        dressPlayers: dressPlayers ?? this.dressPlayers,
        archived: archived ?? this.archived,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object> toJson() => {
        'slot': slot.id,
        'label': label.trim(),
        'body': colorToHex(body),
        'trim': colorToHex(trim),
        'goalkeeper_body': colorToHex(goalkeeperBody),
        'goalkeeper_trim': colorToHex(goalkeeperTrim),
        'pattern': pattern.name,
        'goalkeeper_pattern': goalkeeperPattern.name,
        'dress_players': dressPlayers,
        'archived': archived,
        'enabled': enabled,
      };

  @override
  bool operator ==(Object other) =>
      other is ClubKit &&
      other.slot == slot &&
      other.label == label &&
      other.body == body &&
      other.trim == trim &&
      other.goalkeeperBody == goalkeeperBody &&
      other.goalkeeperTrim == goalkeeperTrim &&
      other.pattern == pattern &&
      other.goalkeeperPattern == goalkeeperPattern &&
      other.dressPlayers == dressPlayers &&
      other.archived == archived &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(
        slot,
        label,
        body,
        trim,
        goalkeeperBody,
        goalkeeperTrim,
        pattern,
        goalkeeperPattern,
        dressPlayers,
        archived,
        enabled,
      );
}

/// « Color(0xFFAA0000) » → « #AA0000 ».
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Les tenues configurables du club du compte connecté.
///
/// Tenus ici, comme le nom du club ([ClubIdentity]), parce qu'ils s'affichent
/// dans plusieurs écrans (formulaire de match, fiche du match, compositions
/// « entre nous »). Tant que le club n'a rien réglé, des maillots par défaut
/// sont tirés de ses couleurs.
abstract final class ClubKits {
  static const int maxLabelLength = 20;

  static Color defaultGoalkeeperBodyFor(JerseyOption slot) => switch (slot) {
        JerseyOption.france => const Color(0xFF168A52),
        JerseyOption.orange => const Color(0xFFF5A300),
        JerseyOption.blue => const Color(0xFF1F6FEB),
        _ => const Color(0xFF168A52),
      };

  static Color defaultGoalkeeperTrimFor(JerseyOption slot) =>
      const Color(0xFFFFFFFF);

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static List<ClubKit>? _saved;
  static Color? _clubPrimary;
  static Color? _clubSecondary;

  /// Change à chaque mise à jour des maillots.
  static ValueListenable<int> get revision => _revision;

  /// Un nouveau club ne commence qu'avec un maillot Domicile.
  static List<ClubKit> defaultsFor({Color? primary, Color? secondary}) =>
      [_legacyDefaults(primary: primary, secondary: secondary).first];

  /// Conserver les trois identifiants d'origine pour lire les anciens matchs.
  /// Les tenues absentes ne sont PAS proposées aux nouveaux matchs.
  static List<ClubKit> _legacyDefaults({Color? primary, Color? secondary}) {
    final main = primary ?? AppTheme.defaultPrimary;
    final second = secondary ?? const Color(0xFFFFFFFF);
    return [
      ClubKit(
        slot: JerseyOption.france,
        label: 'Domicile',
        body: main,
        trim: second,
        enabled: true,
      ),
      ClubKit(
        slot: JerseyOption.orange,
        label: 'Extérieur',
        body: const Color(0xFFFFFFFF),
        trim: main,
        goalkeeperBody: defaultGoalkeeperBodyFor(JerseyOption.orange),
        enabled: false,
      ),
      ClubKit(
        slot: JerseyOption.blue,
        label: 'Troisième',
        body: const Color(0xFF1B1F2A),
        trim: second,
        goalkeeperBody: defaultGoalkeeperBodyFor(JerseyOption.blue),
        enabled: false,
      ),
    ];
  }

  static List<ClubKit> get all =>
      _saved ?? defaultsFor(primary: _clubPrimary, secondary: _clubSecondary);

  /// Vrai quand le club n'a encore rien réglé.
  static bool get usesDefaults => _saved == null;

  /// Les maillots actifs proposés aux matchs ordinaires.
  static List<ClubKit> get enabled => [
        for (final kit in all)
          if (kit.enabled && !kit.archived) kit,
      ];

  /// Entre-nous nécessite deux tenues différentes. Si le club n'en possède
  /// qu'une, offrir une tenue de contraste historique sans l'ajouter à ses
  /// réglages : aucune nouvelle entrée n'est créée à son insu.
  static List<ClubKit> get forInternalMatch {
    final list = enabled;
    if (list.length >= 2) return list;
    if (list.isEmpty) return defaultsFor();
    final contrasting = _legacyDefaults(
      primary: _clubPrimary,
      secondary: _clubSecondary,
    ).firstWhere((kit) => kit.slot != list.first.slot);
    return [...list, contrasting.copyWith(enabled: true)];
  }

  /// Une référence de match ancienne ou archivée reste résoluble.
  static ClubKit of(JerseyOption slot) {
    for (final kit in all) {
      if (kit.slot == slot) return kit;
    }
    for (final kit in _legacyDefaults(
      primary: _clubPrimary,
      secondary: _clubSecondary,
    )) {
      if (kit.slot == slot) return kit.copyWith(enabled: false);
    }
    return ClubKit(
      slot: slot,
      label: 'Maillot archivé',
      body: const Color(0xFF1B1F2A),
      trim: const Color(0xFFFFFFFF),
      enabled: false,
      archived: true,
    );
  }

  /// Retient les couleurs du club, qui servent aux maillots par défaut.
  static void setClubColors({Color? primary, Color? secondary}) {
    if (primary == _clubPrimary && secondary == _clubSecondary) return;
    _clubPrimary = primary;
    _clubSecondary = secondary;
    if (_saved == null) _revision.value += 1;
  }

  /// Applique les maillots lus en base (`clubs.kits`). Une valeur absente ou
  /// illisible ramène aux maillots par défaut.
  static void setFromJson(Object? json) {
    final next = parse(json);
    if (listEquals(next, _saved)) return;
    _saved = next;
    _revision.value += 1;
  }

  static void reset() {
    _saved = null;
    _clubPrimary = null;
    _clubSecondary = null;
    _revision.value += 1;
  }

  /// Lit de 1 à N tenues, y compris les historiques archivées.
  /// Une valeur malformée ne doit jamais contaminer un autre club.
  static List<ClubKit>? parse(Object? json) {
    if (json is! List || json.isEmpty) return null;
    final result = <ClubKit>[];
    final seen = <String>{};
    var activeCount = 0;
    for (final item in json) {
      if (item is! Map) return null;
      final slot = JerseyOption.fromId(item['slot']?.toString());
      if (slot == null || !seen.add(slot.id)) return null;
      final body = AppTheme.parseHex(item['body']?.toString());
      final trim = AppTheme.parseHex(item['trim']?.toString());
      final goalkeeperBody = item.containsKey('goalkeeper_body')
          ? AppTheme.parseHex(item['goalkeeper_body']?.toString())
          : defaultGoalkeeperBodyFor(slot);
      final goalkeeperTrim = item.containsKey('goalkeeper_trim')
          ? AppTheme.parseHex(item['goalkeeper_trim']?.toString())
          : defaultGoalkeeperTrimFor(slot);
      final label = item['label']?.toString().trim() ?? '';
      if (body == null ||
          trim == null ||
          goalkeeperBody == null ||
          goalkeeperTrim == null ||
          label.isEmpty ||
          label.length > maxLabelLength ||
          (item.containsKey('enabled') && item['enabled'] is! bool) ||
          (item.containsKey('archived') && item['archived'] is! bool)) {
        return null;
      }
      final archived = item['archived'] == true;
      final enabled = item['enabled'] != false && !archived;
      if (enabled) activeCount += 1;
      result.add(ClubKit(
        slot: slot,
        label: label,
        body: body,
        trim: trim,
        goalkeeperBody: goalkeeperBody,
        goalkeeperTrim: goalkeeperTrim,
        pattern: KitPattern.fromJson(item['pattern']),
        goalkeeperPattern: KitPattern.fromJson(item['goalkeeper_pattern']),
        dressPlayers: item['dress_players'] == true,
        archived: archived,
        enabled: enabled,
      ));
    }
    if (activeCount == 0) return null;
    // Garder l'ordre historique pour les clubs qui avaient trois emplacements.
    final legacy = [
      JerseyOption.france,
      JerseyOption.orange,
      JerseyOption.blue,
    ];
    if (result.every((kit) => legacy.contains(kit.slot))) {
      result.sort((a, b) =>
          legacy.indexOf(a.slot).compareTo(legacy.indexOf(b.slot)));
    }
    return result;
  }
}
