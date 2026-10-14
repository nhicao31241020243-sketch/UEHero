import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/student_job.dart';
import 'package:uehero/services/job_repository.dart';
import 'package:uehero/services/points_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PointsManager.instance.resetForTesting();
    JobRepository.instance.resetForTesting();
  });

  test('saving, unsaving and saving again awards XP only once', () async {
    final repository = JobRepository.instance;

    expect(await repository.toggleSaved('ba-intern-nova'), isTrue);
    expect(repository.savedJobIds, contains('ba-intern-nova'));
    expect(await repository.toggleSaved('ba-intern-nova'), isFalse);
    expect(repository.savedJobIds, isNot(contains('ba-intern-nova')));
    expect(await repository.toggleSaved('ba-intern-nova'), isTrue);

    final rewards = PointsManager.instance.entries
        .where((entry) => entry.nguon == 'job_save')
        .toList();
    expect(rewards, hasLength(1));
    expect(rewards.single.luong, 3);
    expect(rewards.single.sourceRef, 'ba-intern-nova');
  });

  test('saved/applied lists use existing local job status storage', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'student_job_statuses',
      '{"ba-intern-nova":"saved","data-intern-lumen":"interview"}',
    );
    JobRepository.instance.resetForTesting();

    await JobRepository.instance.initialize();
    expect(JobRepository.instance.savedJobIds, {'ba-intern-nova'});
    expect(JobRepository.instance.appliedJobIds, {'data-intern-lumen'});

    await JobRepository.instance.setApplied('frontend-parttime-orbit');
    expect(JobRepository.instance.appliedJobIds, {
      'data-intern-lumen',
      'frontend-parttime-orbit',
    });
    expect(
      (await JobRepository.instance.statusFor('frontend-parttime-orbit')),
      JobApplicationStatus.applied,
    );
    expect(PointsManager.instance.entries, isEmpty);
  });
}
