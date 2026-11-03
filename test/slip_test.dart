import 'package:flutter_test/flutter_test.dart';
import 'package:slip/models/slip.dart';
import 'package:slip/providers/slip_provider.dart';
import 'package:slip/services/mock_data_service.dart';

void main() {
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

  group('MockDataService Tests', () {
    test('Initial slips contain high-yield GATE CS blunders', () {
      final initialSlips = MockDataService.getInitialSlips();
      expect(initialSlips.length, greaterThanOrEqualTo(4));

      final topics = initialSlips.map((s) => s.topic).toList();
      expect(topics, contains('Linear Algebra'));
      expect(topics, contains('Operating Systems'));
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
  });
}
