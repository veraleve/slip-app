import '../models/slip.dart';

class MockDataService {
  static List<Slip> getInitialSlips() {
    return [
      Slip(
        id: 'slip-01',
        topic: 'Linear Algebra',
        subtopic: 'Eigenvalues & Singularity',
        examTag: 'GATE CS',
        trapStatement:
            'Assuming det(A) = 0 implies all eigenvalues are zero, confusing singularity with nilpotency.',
        fixStatement:
            'det(A) = 0 guarantees ONLY that at least one eigenvalue λ = 0. All eigenvalues are zero if and only if A is nilpotent (A^k = 0).',
        audioDurationSeconds: 42,
        sameCount: 84,
        clearedCount: 29,
        keepCount: 47,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Slip(
        id: 'slip-02',
        topic: 'Computer Architecture',
        subtopic: 'Pipeline Data Hazards',
        examTag: 'GATE CS',
        trapStatement:
            'Assuming operand forwarding eliminates ALL stalls, specifically forgetting the Load-to-Use 1-cycle bubble.',
        fixStatement:
            'Forwarding cannot bypass time. When an instruction depends immediately on a LOAD result (MEM stage), the data is not available at the start of EX. A 1-cycle stall is strictly mandatory.',
        audioDurationSeconds: 38,
        sameCount: 112,
        clearedCount: 41,
        keepCount: 78,
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
      Slip(
        id: 'slip-03',
        topic: 'Operating Systems',
        subtopic: 'Deadlock Avoidance',
        examTag: 'GATE CS',
        trapStatement:
            'Conflating Deadlock Avoidance (Banker\'s Algorithm) with Starvation prevention.',
        fixStatement:
            'Banker\'s algorithm ensures the system stays in a SAFE state, preventing Deadlock. However, a thread requiring large resource sets can be postponed indefinitely, leading to STARVATION.',
        audioDurationSeconds: 27,
        sameCount: 63,
        clearedCount: 19,
        keepCount: 35,
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      Slip(
        id: 'slip-04',
        topic: 'Discrete Mathematics',
        subtopic: 'Equivalence Relations',
        examTag: 'GATE CS',
        trapStatement:
            'Claiming that if a relation is symmetric (aRb => bRa) and transitive (aRb & bRa => aRa), it MUST be reflexive.',
        fixStatement:
            'False! If an element x does not appear in any related pair at all (there is no y such that xRy), then xRx cannot be deduced. Reflexivity requires aRa for ALL elements in the domain.',
        audioDurationSeconds: 31,
        sameCount: 95,
        clearedCount: 33,
        keepCount: 52,
        createdAt: DateTime.now().subtract(const Duration(hours: 22)),
      ),
    ];
  }
}
