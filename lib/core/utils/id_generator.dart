import 'dart:math';

final Random _random = Random();

String newId([String prefix = '']) {
  final int ms = DateTime.now().toUtc().millisecondsSinceEpoch;
  final String rand = (_random.nextInt(0xFFFFFF).toRadixString(16)).padLeft(6, '0');
  return '${prefix.isEmpty ? '' : prefix}_$ms$rand';
}
