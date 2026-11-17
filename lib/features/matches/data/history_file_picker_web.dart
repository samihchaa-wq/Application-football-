import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Le navigateur ouvre un sélecteur local ; aucun contenu n'est envoyé ici.
class HistorySelectedFile {
  const HistorySelectedFile(this.name, this.content);
  final String name;
  final String content;
}

Future<HistorySelectedFile?> pickHistoryJsonFile() {
  final completer = Completer<HistorySelectedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';

  void changed(web.Event event) {
    final file = input.files?.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    if (file.size > 3 * 1024 * 1024) {
      completer.completeError(
        const FormatException('Le document ne doit pas dépasser 3 Mo.'),
      );
      return;
    }
    file.text().toDart.then((text) {
      if (!completer.isCompleted) {
        completer.complete(HistorySelectedFile(file.name, text.toDart));
      }
    }).catchError((Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    });
  }

  void cancelled(web.Event event) {
    if (!completer.isCompleted) completer.complete(null);
  }

  input.addEventListener('change', changed.toJS);
  input.addEventListener('cancel', cancelled.toJS);
  input.click();
  return completer.future;
}
