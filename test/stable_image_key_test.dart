import 'package:flutter_test/flutter_test.dart';
import 'package:mpjnew/src/core/utils/app_image.dart';

void main() {
  test('signed URL untuk objek yang sama menghasilkan kunci yang sama', () {
    const a = 'https://storage.googleapis.com/b/foto/1.jpg'
        '?X-Goog-Algorithm=GOOG4&X-Goog-Date=20260922&X-Goog-Signature=aaa';
    const b = 'https://storage.googleapis.com/b/foto/1.jpg'
        '?X-Goog-Algorithm=GOOG4&X-Goog-Date=20260923&X-Goog-Signature=bbb';
    expect(stableImageKey(a), stableImageKey(b));
    expect(stableImageKey(a), 'https://storage.googleapis.com/b/foto/1.jpg');
  });

  test('parameter non-tanda-tangan dipertahankan → gambar beda tidak bentrok',
      () {
    const a = 'https://api.example.com/media?id=1&Expires=100&Signature=x';
    const b = 'https://api.example.com/media?id=2&Expires=100&Signature=x';
    expect(stableImageKey(a), isNot(stableImageKey(b)));
    expect(stableImageKey(a), 'https://api.example.com/media?id=1');
  });

  test('URL tanpa query tidak berubah', () {
    const u = 'https://cdn.example.com/a/b.png';
    expect(stableImageKey(u), u);
  });
}
