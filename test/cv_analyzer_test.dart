import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/career_goal.dart';
import 'package:uehero/models/cv_check.dart';
import 'package:uehero/services/cv_analyzer.dart';

void main() {
  const analyzer = CvAnalyzer();

  test('matches career keywords without Vietnamese diacritics', () {
    final analysis = analyzer.analyze(
      text: '''
HOC VAN
Ky nang: SQL, Power BI, Excel, giao tiep va phan tich du lieu.
Kinh nghiem
Phan tich dashboard, tang 20% hieu qua.
Lien he: test@example.com
''',
      career: careerGoals.first,
    );

    expect(analysis.score, greaterThan(50));
    expect(analysis.matchedKeywords, contains('sql'));
    expect(
      analysis.issues.where(
        (issue) => issue.kind == CvIssueKind.missingSection,
      ),
      isEmpty,
    );
  });

  test(
    'compares job requirements and flags weak, vague, and long CV lines',
    () {
      final job = CvCheckJob(
        title: 'Data Analyst',
        company: 'Example',
        requirements: const ['SQL', 'Python'],
      );
      final longLine = 'Mô tả công việc '.padRight(140, 'x');
      final analysis = analyzer.analyze(
        text:
            '''
Mục tiêu nghề nghiệp: Mong muốn học hỏi.
Học vấn
Kinh nghiệm
Tham gia làm báo cáo bán hàng.
Kỹ năng
SQL
Liên hệ: test@example.com
$longLine
''',
        career: careerGoals[1],
        job: job,
      );

      expect(analysis.jobMatchCount, 1);
      expect(analysis.jobRequirementCount, 2);
      expect(
        analysis.issues.any(
          (issue) => issue.kind == CvIssueKind.weakActionVerb,
        ),
        isTrue,
      );
      expect(
        analysis.issues.any(
          (issue) => issue.kind == CvIssueKind.vagueObjective,
        ),
        isTrue,
      );
      expect(
        analysis.issues.any((issue) => issue.kind == CvIssueKind.longLine),
        isTrue,
      );
      expect(analysis.score, inInclusiveRange(0, 100));
    },
  );
}
