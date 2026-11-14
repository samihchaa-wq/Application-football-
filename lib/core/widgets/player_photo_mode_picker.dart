import 'package:as_grinta/core/storage/player_photo_mode.dart';
import 'package:flutter/material.dart';

Future<PlayerPhotoMode?> choosePlayerPhotoMode(
  BuildContext context, {
  PlayerPhotoMode current = PlayerPhotoMode.player,
}) =>
    showDialog<PlayerPhotoMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Photo du joueur'),
        children: [
          for (final mode in PlayerPhotoMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, mode),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  mode == PlayerPhotoMode.player
                      ? Icons.checkroom_outlined
                      : Icons.image_outlined,
                ),
                title: Text(mode.label),
                subtitle: Text(
                  mode == PlayerPhotoMode.player
                      ? 'Photo à fond transparent. Le maillot s’adapte au match.'
                      : 'Photo libre. Couronne uniquement, sans maillot ajouté.',
                ),
                trailing: current == mode ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
