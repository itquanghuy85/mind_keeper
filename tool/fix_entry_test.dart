import 'dart:io';

void main() {
  final p =
      r'D:\JOB\mind_kepper\mind_keeper\test\features\navigation_entry_test.dart';
  final t = File(p).readAsStringSync();
  final eol = t.contains('\r\n') ? '\r\n' : '\n';
  final oldImp =
      "import 'package:mind_keeper/features/topics/topic_detail_screen.dart';";
  if (!t.contains(oldImp)) {
    print('FAIL: import anchor missing');
    exit(1);
  }
  var s = t.replaceFirst(
    oldImp,
    "import 'package:mind_keeper/features/profile/study_plan_screen.dart';$eol$oldImp",
  );
  final label = 'K\u{1EBF} ho\u{1EA1}ch h\u{1ECD}c';
  final title = 'Profile \u{2192} $label (StudyPlanScreen)';
  final comment =
      '      // Tile may be outside the viewport, scroll into view before tapping (GD20 entry point).';
  final newLines = [
    '      expect(find.byType(KnowledgeLibraryScreen), findsOneWidget);',
    '',
    '      await _dispose(tester, services);',
    '    });',
    '',
    "    testWidgets('$title', (",
    '      WidgetTester tester,',
    '    ) async {',
    '      final AppServices services = await _buildServices(tester);',
    '',
    '      await _pump(tester, _wrap(services, const ProfileScreen()));',
    '',
    "      final Finder entry = find.text('$label');",
    '      expect(entry, findsOneWidget);',
    '',
    comment,
    '      await tester.scrollUntilVisible(',
    '        entry.first,',
    '        240,',
    '        scrollable: find.byType(Scrollable).first,',
    '      );',
    '      await tester.pump(const Duration(milliseconds: 100));',
    '      await tester.tap(entry.first);',
    '      await _settleReal(tester);',
    '',
    '      expect(find.byType(StudyPlanScreen), findsOneWidget);',
    '',
    '      await _dispose(tester, services);',
    '    });',
    '  });',
    '}',
  ];
  final newTail = newLines.join(eol);
  final oldTail = [
    '      expect(find.byType(LearnedLibraryScreen), findsOneWidget);',
    '',
    '      await _dispose(tester, services);',
    '    });',
    '  });',
    '}',
  ].join(eol);
  if (!s.contains(oldTail)) {
    print('FAIL: tail anchor missing');
    exit(1);
  }
  s = s.replaceFirst(oldTail, newTail);
  File(p).writeAsStringSync(s, flush: true);
  print('PATCH_OK eol=$eol');
}
