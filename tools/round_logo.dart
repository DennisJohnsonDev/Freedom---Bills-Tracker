// One-shot tool: masks the source app logo with an anti-aliased rounded-corner
// alpha so the rounded square is visible against any splash background.
//
// Run with:  dart run tools/round_logo.dart
//
// Output:    assets/logo/freedom_app_logo_rounded.png

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _input = 'assets/logo/freedom_app_logo_raw.png';
const _output = 'assets/logo/freedom_app_logo_rounded.png';

/// 22% radius — matches iOS app-icon squircle proportions and reads naturally
/// at every size.
const _radiusRatio = 0.22;

void main() {
  final file = File(_input);
  if (!file.existsSync()) {
    stderr.writeln('Missing $_input');
    exit(1);
  }

  final src = img.decodePng(file.readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode $_input');
    exit(1);
  }

  final w = src.width;
  final h = src.height;
  final r = w * _radiusRatio;

  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final a = _maskAlpha(x, y, w, h, r);
      if (a <= 0) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        final s = src.getPixel(x, y);
        out.setPixelRgba(
          x,
          y,
          s.r.toInt(),
          s.g.toInt(),
          s.b.toInt(),
          (a * 255).round(),
        );
      }
    }
  }

  File(_output).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('✓ Wrote $_output (${w}×$h, r=${r.toStringAsFixed(0)}px)');
}

/// Anti-aliased rounded-rect mask. Returns alpha in [0, 1].
double _maskAlpha(int x, int y, int w, int h, double r) {
  final inLeft = x < r;
  final inRight = x >= w - r;
  final inTop = y < r;
  final inBottom = y >= h - r;

  // Not in any corner zone → fully opaque interior.
  if (!((inLeft || inRight) && (inTop || inBottom))) return 1.0;

  final cx = inLeft ? r : (w - 1 - r);
  final cy = inTop ? r : (h - 1 - r);
  final dx = x - cx;
  final dy = y - cy;
  final dist = math.sqrt(dx * dx + dy * dy);

  if (dist <= r - 0.5) return 1.0;
  if (dist >= r + 0.5) return 0.0;
  return r + 0.5 - dist; // 1-pixel anti-aliased boundary
}
