import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/data/job_demo_data.dart';
import 'package:uehero/widgets/match_bar.dart';

void main() {
  final byId = {for (final job in jobDemoData) job.id: job};
  final vietnameseMarks = RegExp(
    r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
    caseSensitive: false,
  );

  test('seed jobs keep original English company and job names', () {
    const expected = {
      'ba-intern-nova': ('Business Analyst Intern', 'Nova Analytics'),
      'data-intern-lumen': ('Data Analyst Intern', 'Lumen Digital'),
      'frontend-parttime-orbit': ('Frontend Developer', 'Orbit Studio'),
    };
    expected.forEach((id, names) {
      expect(byId[id]?.title, names.$1);
      expect(byId[id]?.company, names.$2);
    });
  });

  test('company and job titles are never translated into Vietnamese', () {
    for (final job in jobDemoData) {
      expect(job.company, isNot(contains(vietnameseMarks)), reason: job.id);
      expect(job.title, isNot(contains(vietnameseMarks)), reason: job.id);
    }
  });

  test('skill and tool names stay as written', () {
    final skills = byId['ba-intern-nova']!.requiredSkills.map((s) => s.label);
    expect(skills, containsAll(['SQL', 'Excel', 'Power BI']));
  });

  testWidgets('energy bar shows label and percent without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 280, child: JobMatchEnergyBar(percent: 67)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Độ khớp'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
