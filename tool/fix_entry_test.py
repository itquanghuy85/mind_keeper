import io
p = r'D:\JOB\mind_kepper\mind_keeper\test\features\navigation_entry_test.dart'
t = io.open(p, encoding='utf-8').read()
eol = '\r\n' if '\r\n' in t else '\n'
old_imp = "import 'package:mind_keeper/features/topics/topic_detail_screen.dart';"
assert old_imp in t, 'import anchor missing'
new_imp = "import 'package:mind_keeper/features/profile/study_plan_screen.dart';" + eol + old_imp
t = t.replace(old_imp, new_imp, 1)
label = 'K\u1ebf ho\u1ea1ch h\u1ecdc'
title = 'Profile \u2192 ' + label + ' (StudyPlanScreen)'
comment = '      // Tile n\u0103m ngo\u00e0i khung nh\u00ecn c\u1ee7a m\u00e0n h\u00ecnh test \u2014 cu\u1ed9n t\u1edbi tr\u01b0\u1edbc khi b\u1ea5m.'
new_block_lines = [
'      expect(find.byType(LearnedLibraryScreen), findsOneWidget);',
'',
'      await _dispose(tester, services);',
'    });',
'',
"    testWidgets('" + title + "', (",
'      WidgetTester tester,',
'    ) async {',
'      final AppServices services = await _buildServices(tester);',
'',
'      await _pump(tester, _wrap(services, const ProfileScreen()));',
'',
"      final Finder entry = find.text('" + label + "');",
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
]
new_tail = eol.join(new_block_lines)
old_tail = eol.join([
'      expect(find.byType(LearnedLibraryScreen), findsOneWidget);',
'',
'      await _dispose(tester, services);',
'    });',
'  });',
'}',
])
assert old_tail in t, 'tail anchor missing'
t = t.replace(old_tail, new_tail, 1)
io.open(p, 'w', encoding='utf-8', newline='').write(t)
print('PATCH_OK eol=' + repr(eol))
