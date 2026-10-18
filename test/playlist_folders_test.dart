import 'package:flutter_test/flutter_test.dart';
import 'package:sika_app/data/models.dart';
import 'package:sika_app/state/playlist_folders.dart';

void main() {
  test('nom de dossier : caractères interdits retirés, jamais vide ni caché', () {
    expect(PlaylistFolders.folderName('Rap FR / Drill'), 'Rap FR Drill');
    expect(PlaylistFolders.folderName('  Chill: soir?  '), 'Chill soir');
    expect(PlaylistFolders.folderName('.cachée'), 'cachée');
    expect(PlaylistFolders.folderName('***'), 'Playlist');
    expect(PlaylistFolders.displayPath('Ma playlist'), 'Music/YouPlay/Ma playlist');
  });

  test('nom de fichier lisible « Artiste - Titre.m4a »', () {
    const t = Track(id: 'yt_x', title: 'Θ. Macarena', artist: Artist(id: 'ytc_damso', name: 'Damso'), duration: Duration(seconds: 190));
    expect(PlaylistFolders.fileName(t), 'Damso - Θ. Macarena.m4a');
    const bad = Track(id: 'yt_y', title: 'A/B: "live"', artist: Artist(id: 'a', name: 'X'), duration: Duration.zero);
    expect(PlaylistFolders.fileName(bad), 'X - A B live.m4a');
  });
}
