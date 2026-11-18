import 'package:flutter_test/flutter_test.dart';
import 'package:sika_app/data/youtube_source.dart';

void main() {
  test('youtubePlaylistUrl reconnaît les liens de playlist YouTube', () {
    const id = 'PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG';
    const canonical = 'https://www.youtube.com/playlist?list=$id';
    for (final link in [
      'https://www.youtube.com/playlist?list=$id',
      'https://youtube.com/playlist?list=$id&si=abc',
      'https://m.youtube.com/playlist?list=$id',
      'https://music.youtube.com/playlist?list=$id',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=$id&index=2',
      'https://youtu.be/dQw4w9WgXcQ?list=$id',
      '  https://www.youtube.com/playlist?list=$id  ',
      'Écoute ça : https://youtube.com/playlist?list=$id&si=xyz via YouTube',
    ]) {
      expect(youtubePlaylistUrl(link), canonical, reason: link);
    }
  });

  test('youtubePlaylistUrl refuse le reste', () {
    for (final text in [
      '',
      'pas un lien',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://example.com/playlist?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG',
      'https://evil-youtube.com/playlist?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG',
      'https://www.youtube.com/playlist?list=<script>',
    ]) {
      expect(youtubePlaylistUrl(text), isNull, reason: text);
    }
  });
}
