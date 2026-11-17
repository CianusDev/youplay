import 'package:flutter_test/flutter_test.dart';
import 'package:sika_app/ui/components/artwork_image.dart';

void main() {
  test('miniature YouTube 4:3 → haute définition 16:9, avec repli', () {
    const url = 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg?sqp=abc&rs=xyz';
    expect(artworkCandidates(url, large: true), [
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/hq720.jpg',
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      url,
    ]);
    expect(artworkCandidates(url, large: false), ['https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg', url]);
  });

  test('pochette carrée YouTube Music agrandie seulement en grand format', () {
    const url = 'https://lh3.googleusercontent.com/abc=w544-h544-l90-rj';
    expect(artworkCandidates(url, large: true), ['https://lh3.googleusercontent.com/abc=w1080-h1080-l90-rj', url]);
    expect(artworkCandidates(url, large: false), [url]);
  });

  test('autre URL inchangée', () {
    expect(artworkCandidates('https://example.com/a.png', large: true), ['https://example.com/a.png']);
  });
}
