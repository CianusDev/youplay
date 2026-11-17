import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sika_app/data/library_backup.dart';

void main() {
  test('export puis parse restitue les clés de la bibliothèque, rien d\'autre', () async {
    SharedPreferences.setMockInitialValues({
      'sika.library.v1': '{"userName":"A"}',
      'youplay.locale': 'en',
      'youplay.update.skipped': 42, // propre à l'appareil : pas sauvegardé
    });
    final prefs = await SharedPreferences.getInstance();
    final data = LibraryBackup.parse(LibraryBackup.export(prefs))!;
    expect(data, {'sika.library.v1': '{"userName":"A"}', 'youplay.locale': 'en'});
  });

  test('parse refuse les fichiers qui ne sont pas des sauvegardes YouPlay', () {
    expect(LibraryBackup.parse(null), isNull);
    expect(LibraryBackup.parse('pas du json'), isNull);
    expect(LibraryBackup.parse('{"app":"Autre","format":1,"data":{}}'), isNull);
    expect(LibraryBackup.parse('{"app":"YouPlay","format":99,"data":{}}'), isNull);
    // Clé inconnue ignorée (un fichier ne peut pas écrire n'importe quel réglage).
    expect(LibraryBackup.parse('{"app":"YouPlay","format":1,"data":{"x":"y","youplay.locale":"fr"}}'), {'youplay.locale': 'fr'});
  });

  test('restore remplace tout et oublie les sons dont le fichier a disparu', () async {
    final dir = await Directory.systemTemp.createTemp('youplay-test');
    final kept = File('${dir.path}/a.m4a')..writeAsStringSync('x');
    SharedPreferences.setMockInitialValues({'youplay.locale': 'fr', 'youplay.lyrics.v1': '{}'});
    final prefs = await SharedPreferences.getInstance();
    final downloads = jsonEncode({
      'items': [
        {'status': 'done', 'path': kept.path},
        {'status': 'done', 'path': '${dir.path}/absent.m4a'},
        {'status': 'queued', 'path': null},
      ],
      'collections': [],
    });
    await LibraryBackup.restore(prefs, {'sika.downloads.v1': downloads});
    expect(prefs.getString('youplay.locale'), isNull); // absente de la sauvegarde → effacée
    expect(prefs.getString('youplay.lyrics.v1'), isNull);
    final items = (jsonDecode(prefs.getString('sika.downloads.v1')!) as Map)['items'] as List;
    expect(items.length, 2);
    expect(LibraryBackup.downloadedPaths(prefs), [kept.path]);

    // Déménagement : mêmes fichiers sur le même téléphone, rien n'est filtré.
    await LibraryBackup.restore(prefs, {'sika.downloads.v1': downloads}, checkFiles: false);
    expect(((jsonDecode(prefs.getString('sika.downloads.v1')!) as Map)['items'] as List).length, 3);
    await dir.delete(recursive: true);
  });
}
