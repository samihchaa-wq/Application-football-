import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/core/widgets/match_contribution_icons.dart';
import 'package:as_grinta/core/widgets/portrait_alignment_guide.dart';
import 'package:as_grinta/core/storage/avatar_image.dart';
import 'package:as_grinta/core/storage/avatar_image_codec.dart'
    deferred as avatar_codec;
import 'package:flutter/material.dart';

/// Ouvre l'éditeur utilisé pour les photos de profil : déplacement libre,
/// pinch-to-zoom / dézoom et export JPEG, ou PNG si la photo a des zones
/// transparentes.
///
/// Deux seuls patrons sont posés sur l'aperçu : le maillot du club et
/// l'emplacement de la couronne Homme du match, au-dessus de la tête.
/// Aucun d'eux n'est enregistré dans la photo exportée.
///
/// L'export est calculé directement depuis l'image source et la matrice de
/// transformation. On ne capture pas le widget à l'écran : cela évite les
/// échecs de RenderRepaintBoundary sur Flutter Web / iOS PWA et garantit un
/// rendu identique à l'aperçu.
Future<Uint8List?> cropProfilePhoto(
  BuildContext context,
  Uint8List bytes, {
  String title = 'Recadrer la photo',
  String instructions = 'Déplace et pince pour zoomer : place la tête '
      'sous la couronne et le cou dans le maillot.',
  String confirmLabel = 'Utiliser cette photo',
  Color previewColor = const Color(0xFF174936),
  Color previewBorderColor = const Color(0xFF6DAD8B),
  ClubKit? kit,
  bool isGoalkeeper = false,
}) {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PhotoCropDialog(
      bytes: bytes,
      title: title,
      instructions: instructions,
      confirmLabel: confirmLabel,
      previewColor: previewColor,
      previewBorderColor: previewBorderColor,
      kit: kit,
      isGoalkeeper: isGoalkeeper,
    ),
  );
}

class _PhotoCropDialog extends StatefulWidget {
  const _PhotoCropDialog({
    required this.bytes,
    required this.title,
    required this.instructions,
    required this.confirmLabel,
    required this.previewColor,
    required this.previewBorderColor,
    required this.kit,
    required this.isGoalkeeper,
  });

  final Uint8List bytes;
  final String title;
  final String instructions;
  final String confirmLabel;
  final Color previewColor;
  final Color previewBorderColor;
  final ClubKit? kit;
  final bool isGoalkeeper;

  @override
  State<_PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<_PhotoCropDialog> {
  static const double _cropSize = 300;

  /// Le rendu est calculé à la taille de stockage, pas à un multiple arbitraire
  /// de l'aperçu : c'est ce qui décide du poids réel de la photo à télécharger.
  static const double _exportScale = avatarStorageSide / _cropSize;

  final _transformationController = TransformationController();
  double _childWidth = _cropSize;
  double _childHeight = _cropSize;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final coverScale = math.max(
      _cropSize / image.width,
      _cropSize / image.height,
    );
    final childWidth = image.width * coverScale;
    final childHeight = image.height * coverScale;
    image.dispose();
    codec.dispose();
    if (!mounted) return;

    setState(() {
      _childWidth = childWidth;
      _childHeight = childHeight;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(
          -(childWidth - _cropSize) / 2,
          -(childHeight - _cropSize) / 2,
          0,
          1,
        );
      _ready = true;
    });
  }

  Future<Uint8List> _renderCrop() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(_exportScale, _exportScale);
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, _cropSize, _cropSize));
    // Pas de fond peint : une photo détourée garde sa transparence, comme une
    // zone laissée découverte par le cadrage (voir encodeAvatar).
    canvas.transform(_transformationController.value.storage);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, _childWidth, _childHeight),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    final picture = recorder.endRecording();
    const side = avatarStorageSide;
    final output = await picture.toImage(side, side);
    // dart:ui ne sait encoder que du PNG, sans perte : les avatars pesaient
    // 171 à 250 ko pièce, soit ~2,5 Mo pour une composition de onze joueurs.
    // On récupère donc les pixels bruts et on les encode en JPEG, sauf photo
    // transparente (voir encodeAvatar).
    final data = await output.toByteData(format: ui.ImageByteFormat.rawRgba);

    output.dispose();
    source.dispose();
    codec.dispose();

    if (data == null) {
      throw StateError('Impossible de générer la photo recadrée.');
    }

    // Encodeur chargé à la demande (voir avatar_image_codec.dart).
    await avatar_codec.loadLibrary();
    return avatar_codec.encodeAvatarFromRawRgba(data, side, side);
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final jpeg = await _renderCrop();
      if (!mounted) return;
      Navigator.pop(context, jpeg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de préparer cette image. Réessaie.'),
        ),
      );
    }
  }

  static const _background = Color(0xFF080F19);
  static const _outline = Color(0xFF3A4A5D);

  ClubKit get _previewKit => widget.kit ?? ClubKits.enabled.first;

  /// Une seule image source, déplacée sous les deux patrons non exportés.
  /// Le maillot conserve le cou visible, la couronne reste fixe au-dessus.
  Widget _photoFrame() {
    final photo = !_ready
        ? const ColoredBox(color: Color(0x1FFFFFFF))
        : InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(_cropSize * 4),
            minScale: 0.05,
            maxScale: 8,
            panEnabled: true,
            scaleEnabled: true,
            child: Image.memory(
              widget.bytes,
              width: _childWidth,
              height: _childHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const TransparentPhotoBackground(),
          KitPortrait(
            kit: _previewKit,
            isGoalkeeper: widget.isGoalkeeper,
            child: photo,
          ),
        ],
      ),
    );
  }

  /// Le badge Homme du match est DÉCALÉ au-dessus de la photo sur le
  /// terrain, et non dessiné dans son carré. Un espace hors export lui est
  /// réservé pour montrer son vrai encombrement sans rogner les pointes.
  ///
  /// En composition : photo en y=12, couronne en
  /// y=12 + PhotoCrown.topOffset(photoSize).
  /// Ici : photo en y=crownSpace, couronne en y=0. Le décalage relatif est
  /// strictement identique, y compris après FittedBox sur écran mobile.
  Widget _mainPreview() {
    final crownSpace = -PhotoCrown.topOffset(_cropSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: _cropSize / (_cropSize + crownSpace),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _cropSize,
              height: _cropSize + crownSpace,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: crownSpace,
                    left: 0,
                    right: 0,
                    height: _cropSize,
                    child: Container(
                      key: const ValueKey('portrait-crop-frame'),
                      // Border au premier plan, sans padding : la photo
                      // occupe vraiment 300 x 300 et garde les proportions
                      // exactes de l'avatar du terrain et de son export.
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _outline, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _photoFrame(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: PortraitAlignmentGuide(photoSize: _cropSize),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Déplace la photo ou pince pour zoomer. Maillot et couronne ne seront pas enregistrés.',
          style: TextStyle(color: Color(0xFFAAB7C7), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Fenêtre compacte, sans panneaux d'explications ni aperçu secondaire.
    final dialogWidth = math.min(screen.width - 32, 520.0);
    return Dialog(
      backgroundColor: _background,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _outline),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: math.min(screen.height - 32, dialogWidth * 1.36 + 210),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.checkroom_outlined,
                      size: 27, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title == 'Recadrer la photo'
                          ? 'Ajouter la photo du joueur'
                          : widget.title,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dialogWidth < 400 ? 18 : 23,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: _outline, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: _mainPreview(),
              ),
            ),
            const Divider(color: _outline, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: _outline)),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: !_ready || _busy ? null : _confirm,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(widget.confirmLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE3B45E),
                        foregroundColor: const Color(0xFF101723),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
