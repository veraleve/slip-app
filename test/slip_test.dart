import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slip/models/slip.dart';
import 'package:slip/models/task_item.dart';
import 'package:slip/providers/slip_provider.dart';
import 'package:slip/services/mock_data_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Slip Model Tests', () {
    test('Slip serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final slip = Slip(
        id: 'slip-test-1',
        topic: 'Linear Algebra',
        subtopic: 'Eigenvalues',
        trapStatement: 'det(A)=0 implies all eigenvalues are 0',
        fixStatement: 'det(A)=0 implies at least one eigenvalue is 0',
        audioDurationSeconds: 42,
        sameCount: 15,
        clearedCount: 5,
        keepCount: 8,
        createdAt: now,
      );

      final json = slip.toJson();
      final reconstructed = Slip.fromJson(json);

      expect(reconstructed.id, equals('slip-test-1'));
      expect(reconstructed.topic, equals('Linear Algebra'));
      expect(reconstructed.sameCount, equals(15));
      expect(reconstructed.trapStatement,
          contains('det(A)=0 implies all eigenvalues are 0'));
    });

    test('Slip supports Doubt postType with title and resolution flag', () {
      final now = DateTime.now();
      final doubt = Slip(
        id: 'slip-doubt-1',
        postType: PostType.doubt,
        title: 'Why is L1 cache VIPT?',
        topic: 'Computer Organization & Architecture',
        subtopic: 'Memory Hierarchy & Cache Mapping',
        trapStatement: 'Is aliasing prevented when cache size <= page size?',
        fixStatement: 'Yes, because index bits fit inside page offset.',
        isResolved: true,
        createdAt: now,
      );

      final json = doubt.toJson();
      final reconstructed = Slip.fromJson(json);

      expect(reconstructed.postType, equals(PostType.doubt));
      expect(reconstructed.title, equals('Why is L1 cache VIPT?'));
      expect(reconstructed.isResolved, isTrue);
    });

    test('Slip copyWith maintains immutability and updates flags', () {
      final slip = Slip(
        id: 'slip-test-2',
        topic: 'Operating Systems',
        trapStatement: 'Bankers prevents starvation',
        fixStatement: 'Bankers only prevents deadlock',
        createdAt: DateTime.now(),
      );

      final updated = slip.copyWith(
        hasSaidSame: true,
        sameCount: 1,
        isFixRevealed: true,
      );

      expect(slip.hasSaidSame, isFalse);
      expect(updated.hasSaidSame, isTrue);
      expect(updated.sameCount, equals(1));
      expect(updated.isFixRevealed, isTrue);
    });
  });

  group('TaskItem Model Tests', () {
    test('TaskItem supports isStarred and custom listName', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-01',
        title: 'Do probability homework',
        subject: 'Engineering Mathematics',
        topics: ['Probability & Statistics'],
        scheduledAt: now.add(const Duration(days: 1)),
        isStarred: true,
        listName: 'Homework',
        createdAt: now,
      );

      final json = task.toJson();
      final reconstructed = TaskItem.fromJson(json);

      expect(reconstructed.id, equals('task-01'));
      expect(reconstructed.isStarred, isTrue);
      expect(reconstructed.listName, equals('Homework'));
    });
  });

  group('MockDataService Tests', () {
    test('Initial slips contain high-yield GATE CS blunders', () {
      final initialSlips = MockDataService.getInitialSlips();
      expect(initialSlips.length, greaterThanOrEqualTo(4));

      final topics = initialSlips.map((s) => s.topic).toList();
      expect(topics, contains('Linear Algebra'));
      expect(topics.any((t) => t.contains('Operating System')), isTrue);
    });
  });

  group('SlipProvider Logic Tests', () {
    test('Provider initializes and allows interaction toggles', () async {
      final provider = SlipProvider();
      await provider.init();

      expect(provider.slips.isNotEmpty, isTrue);
      final firstId = provider.slips.first.id;
      final initialSame = provider.slips.first.sameCount;

      provider.toggleSame(firstId);
      final updatedSlip = provider.slips.firstWhere((s) => s.id == firstId);
      expect(updatedSlip.hasSaidSame, isTrue);
      expect(updatedSlip.sameCount, equals(initialSame + 1));

      provider.toggleFixRevealed(firstId);
      final fixRevealedSlip =
          provider.slips.firstWhere((s) => s.id == firstId);
      expect(fixRevealedSlip.isFixRevealed, isTrue);
    });

    test('Saved peer mistakes appear in getBlundersForTask traps', () async {
      final provider = SlipProvider();
      await provider.init();

      // Find or create a peer slip in Linear Algebra
      final peerSlip = provider.slips.firstWhere((s) => s.topic == 'Linear Algebra');
      await provider.toggleKeep(peerSlip.id);

      final task = TaskItem(
        id: 'task-test',
        title: 'Linear Algebra Test',
        subject: 'Linear Algebra',
        topics: ['All Topics'],
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      final traps = provider.getBlundersForTask(task);
      expect(traps.any((t) => t.id == peerSlip.id), isTrue);
    });
  });
}
