import '../constants/gate_syllabus.dart';
import '../models/slip.dart';

class MockDataService {
  static List<Slip> getInitialSlips() {
    return [
      // --- GATE CS 2027 ---
      Slip(
        id: 'slip-cs-01',
        topic: 'Linear Algebra',
        subtopic: 'Eigenvalues & Eigenvectors',
        examTag: GateSyllabus.gateCS,
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
        id: 'slip-cs-02',
        topic: 'Computer Organization & Architecture',
        subtopic: 'Instruction Pipelining & Pipeline Hazards',
        examTag: GateSyllabus.gateCS,
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
        id: 'slip-cs-03',
        topic: 'Operating System',
        subtopic: 'Deadlock Detection & Avoidance',
        examTag: GateSyllabus.gateCS,
        trapStatement:
            'Conflating Deadlock Avoidance (Banker\'s Algorithm) with Starvation prevention.',
        fixStatement:
            'Banker\'s algorithm ensures the system stays in a SAFE state, preventing Deadlock. However, a thread requiring large resource sets can be postponed indefinitely, leading to STARVATION.',
        audioDurationSeconds: 0,
        sameCount: 63,
        clearedCount: 19,
        keepCount: 35,
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),

      // --- GATE DA 2027 ---
      Slip(
        id: 'slip-da-01',
        topic: 'Machine Learning',
        subtopic: 'Support Vector Machine (SVM)',
        examTag: GateSyllabus.gateDA,
        trapStatement:
            'Assuming a large regularization parameter C in soft-margin SVM results in a wider, smoother margin.',
        fixStatement:
            'Inverse behavior! The objective is min 1/2||w||^2 + C * sum(slack). A large C severely penalizes slack/violations, forcing a NARROW margin with high risk of overfitting. Small C yields a wider margin with more violations.',
        audioDurationSeconds: 35,
        sameCount: 96,
        clearedCount: 38,
        keepCount: 64,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Slip(
        id: 'slip-da-02',
        topic: 'Probability and Statistics',
        subtopic: 'Bayes Theorem & Total Probability',
        examTag: GateSyllabus.gateDA,
        trapStatement:
            'Forgetting that P(A | B) + P(A | B^c) does NOT equal 1.',
        fixStatement:
            'Probabilities conditioned on DIFFERENT events do not sum to 1. The valid partition is P(A | B) + P(A^c | B) = 1 (conditioning event B must be held constant).',
        audioDurationSeconds: 0,
        sameCount: 142,
        clearedCount: 52,
        keepCount: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 11)),
      ),
      Slip(
        id: 'slip-da-03',
        topic: 'Artificial Intelligence',
        subtopic: 'Informed & Uninformed Search (BFS, DFS, A*)',
        examTag: GateSyllabus.gateDA,
        trapStatement:
            'Assuming A* tree search with an admissible heuristic is guaranteed to be optimal on graphs without consistency.',
        fixStatement:
            'Admissibility (h(n) <= h*(n)) guarantees optimality for TREE search only. For GRAPH search (avoiding revisited states), the heuristic must also be CONSISTENT (monotonic: h(n) <= c(n,a,n\') + h(n\')).',
        audioDurationSeconds: 29,
        sameCount: 71,
        clearedCount: 24,
        keepCount: 43,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),

      // --- GATE EC 2027 ---
      Slip(
        id: 'slip-ec-01',
        topic: 'Analog Circuits',
        subtopic: 'Op-Amp Circuits, Summers, Integrators, Filters',
        examTag: GateSyllabus.gateEC,
        trapStatement:
            'Applying virtual ground (V+ = V-) blindly when the Op-Amp has positive feedback.',
        fixStatement:
            'Virtual short/ground condition V+ ≈ V- holds ONLY when the op-amp is operating in linear region with NEGATIVE feedback. In positive feedback (e.g. Schmitt Trigger), output saturates at ±Vsat and virtual ground is completely invalid.',
        audioDurationSeconds: 40,
        sameCount: 88,
        clearedCount: 31,
        keepCount: 57,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      Slip(
        id: 'slip-ec-02',
        topic: 'Networks, Signals and Systems',
        subtopic: 'LTI Systems: Impulse Response, Convolution, Poles/Zeroes',
        examTag: GateSyllabus.gateEC,
        trapStatement:
            'Conflating causality with BIBO stability in LTI systems.',
        fixStatement:
            'Causality means h(t) = 0 for t < 0 (ROC is to the right of rightmost pole). BIBO stability requires integral |h(t)| dt < ∞ (ROC includes imaginary axis jω). A causal system can be completely unstable if poles lie in the RHP.',
        audioDurationSeconds: 0,
        sameCount: 75,
        clearedCount: 22,
        keepCount: 48,
        createdAt: DateTime.now().subtract(const Duration(hours: 16)),
      ),

      // --- GATE EE 2027 ---
      Slip(
        id: 'slip-ee-01',
        topic: 'Electrical Machines',
        subtopic: 'Single-Phase Transformer: Phasors, OC/SC Tests, Regulation',
        examTag: GateSyllabus.gateEE,
        trapStatement:
            'Thinking Open Circuit test parameters represent series winding resistance and leakage reactance.',
        fixStatement:
            'OC test is conducted at rated voltage on LV side to find CORE LOSS and shunt branch parameters (Rc, Xm). Short Circuit (SC) test at rated current finds the series winding parameters (Req, Xeq).',
        audioDurationSeconds: 32,
        sameCount: 104,
        clearedCount: 45,
        keepCount: 68,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Slip(
        id: 'slip-ee-02',
        topic: 'Power Systems',
        subtopic: 'Power System Stability & Equal Area Criterion',
        examTag: GateSyllabus.gateEE,
        trapStatement:
            'Applying Equal Area Criterion assuming rotor angle δ returns to initial δ0 after fault clearance.',
        fixStatement:
            'After fault clearance at δc, the rotor swings up to maximum angle δmax where accelerating area A1 equals decelerating area A2. The post-fault operating angle settles at a NEW angle determined by the post-fault power-angle curve.',
        audioDurationSeconds: 0,
        sameCount: 67,
        clearedCount: 18,
        keepCount: 39,
        createdAt: DateTime.now().subtract(const Duration(hours: 19)),
      ),
    ];
  }
}
