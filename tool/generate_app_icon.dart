import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() async {
  const size = 1024;
  final bgTop = _hex('#0F172A');
  final bgMid = _hex('#1E293B');
  final brain = _hex('#FFFFFF');
  final brainFold = _hex('#CBD5E1');
  final nodeGlow = _hex('#818CF8');
  final nodeLine = _hex('#C7D2FE');
  final cx = size / 2;
  final cy = size / 2;

  final main = img.Image(width: size, height: size);
  final cornerRadius = 200.0;
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final tt = t * t;
    final r = lerp(bgTop[0], bgMid[0], tt).round();
    final g = lerp(bgTop[1], bgMid[1], tt).round();
    final b = lerp(bgTop[2], bgMid[2], tt).round();
    for (var x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (!_inRoundedCorner(dx, dy, cornerRadius)) continue;
      main.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > 360) continue;
      final glow = (1.0 - dist / 360) * 0.06;
      final p = main.getPixel(x, y);
      main.setPixelRgba(x, y,
        (p.r + 30 * glow).clamp(0, 255).round(),
        (p.g + 40 * glow).clamp(0, 255).round(),
        (p.b + 100 * glow).clamp(0, 255).round(), 255);
    }
  }

  final nodes = <(double, double)>[];
  for (var i = 0; i < 12; i++) {
    final angle = (i / 12) * 2 * math.pi;
    nodes.add((cx + math.cos(angle) * 230, cy + math.sin(angle) * 230));
  }
  final connections = [
    (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6),
    (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 0),
    (0, 6), (3, 9),
  ];
  for (final c in connections) {
    final a = nodes[c.$1];
    final b = nodes[c.$2];
    _drawLine(main, size, a.$1.round(), a.$2.round(), b.$1.round(), b.$2.round(), nodeLine, 3);
  }
  for (final n in nodes) {
    _drawCircle(main, size, n.$1.round(), n.$2.round(), 10, nodeGlow);
  }

  final brainW = 340.0;
  final brainH = 220.0;
  final brainY = cy + 20;
  _drawBrainLobe(main, size, cx - brainW / 2 - 10, brainY, brainW, brainH, brain, brainFold, false);
  _drawBrainLobe(main, size, cx + brainW / 2 + 10, brainY, brainW, brainH, brain, brainFold, true);
  _drawRoundRect(main, size, (cx - 25).round(), (brainY - 30).round(), 50, 110, 12, brainFold);

  final mainFile = File('assets/images/app_icon.png');
  await mainFile.writeAsBytes(img.encodePng(main));
  print('✅ Saved ${mainFile.path} (${mainFile.lengthSync()} bytes)');

  final adaptive = img.Image(width: size, height: size);
  _drawBrainLobe(adaptive, size, cx - brainW / 2 - 10, brainY, brainW, brainH, brain, brainFold, false);
  _drawBrainLobe(adaptive, size, cx + brainW / 2 + 10, brainY, brainW, brainH, brain, brainFold, true);
  _drawRoundRect(adaptive, size, (cx - 25).round(), (brainY - 30).round(), 50, 110, 12, brainFold);

  final adaptiveFile = File('assets/images/app_icon_adaptive.png');
  await adaptiveFile.writeAsBytes(img.encodePng(adaptive));
  print('✅ Saved ${adaptiveFile.path} (${adaptiveFile.lengthSync()} bytes)');
}

bool _inRoundedCorner(double dx, double dy, double r) {
  final ax = dx.abs();
  final ay = dy.abs();
  if (ax <= r && ay <= r) return true;
  if (ax > r && ay > r) {
    final cd = ax - r;
    final cd2 = ay - r;
    return cd * cd + cd2 * cd2 <= r * r;
  }
  return true;
}

List<int> _hex(String hex) {
  final h = hex.replaceFirst('#', '');
  return [
    int.parse(h.substring(0, 2), radix: 16),
    int.parse(h.substring(2, 4), radix: 16),
    int.parse(h.substring(4, 6), radix: 16),
  ];
}

int lerp(int a, int b, double t) => a + ((b - a) * t).round();

void _drawLine(img.Image image, int size, int x0, int y0, int x1, int y1,
    List<int> color, int thickness) {
  var dx = (x1 - x0).abs();
  var dy = (y1 - y0).abs();
  var sx = x0 < x1 ? 1 : -1;
  var sy = y0 < y1 ? 1 : -1;
  var err = dx - dy;
  while (true) {
    for (var tx = -thickness ~/ 2; tx <= thickness ~/ 2; tx++) {
      for (var ty = -thickness ~/ 2; ty <= thickness ~/ 2; ty++) {
        final px = x0 + tx;
        final py = y0 + ty;
        if (px >= 0 && px < size && py >= 0 && py < size) {
          image.setPixelRgba(px, py, color[0], color[1], color[2], 255);
        }
      }
    }
    if (x0 == x1 && y0 == y1) break;
    final e2 = 2 * err;
    if (e2 > -dy) { err -= dy; x0 += sx; }
    if (e2 < dx) { err += dx; y0 += sy; }
  }
}

void _drawCircle(img.Image image, int size, int cx, int cy, int r, List<int> color) {
  for (var y = -r; y <= r; y++) {
    for (var x = -r; x <= r; x++) {
      if (x * x + y * y <= r * r) {
        final px = cx + x;
        final py = cy + y;
        if (px >= 0 && px < size && py >= 0 && py < size) {
          image.setPixelRgba(px, py, color[0], color[1], color[2], 255);
        }
      }
    }
  }
}

void _drawRoundRect(img.Image image, int size, int x, int y, int w, int h, int r,
    List<int> color) {
  for (var iy = 0; iy < h; iy++) {
    for (var ix = 0; ix < w; ix++) {
      final px = x + ix;
      final py = y + iy;
      if (px < 0 || px >= size || py < 0 || py >= size) continue;
      bool inRect = true;
      if (ix < r && iy < r) {
        if ((ix - r) * (ix - r) + (iy - r) * (iy - r) > r * r) inRect = false;
      }
      if (ix >= w - r && iy < r) {
        if ((ix - (w - r)) * (ix - (w - r)) + (iy - r) * (iy - r) > r * r) inRect = false;
      }
      if (ix < r && iy >= h - r) {
        if ((ix - r) * (ix - r) + (iy - (h - r)) * (iy - (h - r)) > r * r) inRect = false;
      }
      if (ix >= w - r && iy >= h - r) {
        if ((ix - (w - r)) * (ix - (w - r)) + (iy - (h - r)) * (iy - (h - r)) > r * r) inRect = false;
      }
      if (!inRect) continue;
      image.setPixelRgba(px, py, color[0], color[1], color[2], 255);
    }
  }
}

void _drawBrainLobe(img.Image image, int size, double cx, double cy, double w,
    double h, List<int> brain, List<int> fold, bool mirror) {
  final r = h * 0.45;
  for (var y = cy.round() - (h ~/ 2); y <= cy.round() + (h ~/ 2); y++) {
    for (var x = cx.round() - (w ~/ 2); x <= cx.round() + (w ~/ 2); x++) {
      if (x < 0 || x >= size || y < 0 || y >= size) continue;
      final nx = (x - cx) / (w / 2);
      final ny = (y - cy) / (h / 2);
      final val = math.pow(nx.abs(), 2.5) + math.pow(ny.abs(), 2.5);
      if (val > 1.0) continue;
      image.setPixelRgba(x, y, brain[0], brain[1], brain[2], 255);
    }
  }

  final foldCount = 5;
  for (var f = 0; f < foldCount; f++) {
    final fProgress = f / (foldCount - 1);
    final startX = cx - w * 0.35 + w * 0.7 * fProgress;
    final endX = startX + w * 0.15;
    final amplitude = h * 0.18;
    for (var t = 0.0; t <= 1.0; t += 0.005) {
      final sx = startX + (endX - startX) * t;
      final wave = math.sin(t * math.pi * 2 * 3) * amplitude * (1 - fProgress * 0.5);
      final sy = cy - h * 0.25 + wave + fProgress * h * 0.5;
      _drawCircle(image, size, sx.round(), sy.round(), 3, fold);
    }
  }
}