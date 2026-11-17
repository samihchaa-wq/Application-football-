class HistorySelectedFile {
  const HistorySelectedFile(this.name, this.content);
  final String name;
  final String content;
}

Future<HistorySelectedFile?> pickHistoryJsonFile() async {
  throw UnsupportedError(
    'Pour importer un fichier, ouvre Petit Filet dans ton navigateur.',
  );
}
