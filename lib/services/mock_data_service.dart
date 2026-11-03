import '../constants/gate_syllabus.dart';
import '../models/slip.dart';

class MockDataService {
  static List<Slip> getInitialSlips() {
    return [
      // --- GATE CS PEER DOUBTS ---
      Slip(
        id: 'slip-cs-d01',
        authorId: 'peer_vikram',
        authorUsername: 'vikram_cs',
        postType: PostType.doubt,
        title: 'Why is L1 cache virtually indexed & physically tagged (VIPT)?',
        topic: 'Computer Organization & Architecture',
        subtopic: 'Memory Hierarchy & Cache Mapping',
        examTag: GateSyllabus.gateCS,
        trapStatement:
            'I am confused between PIPT, VIPT, and VIVT. What happens if cache size > page size * associativity in VIPT? Does aliasing happen, and how does hardware resolve it?',
        fixStatement:
            'In VIPT, index bits come directly from the page offset (which is invariant under translation), allowing TLB translation and cache index lookup to happen simultaneously. If cache size <= page size * assoc, the index bits never overlap with the VPN, preventing aliasing entirely.',
        isResolved: true,
        audioDurationSeconds: 45,
        sameCount: 128,
        clearedCount: 42,
        keepCount: 65,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Slip(
        id: 'slip-cs-d02',
        authorId: 'peer_sneha',
        authorUsername: 'sneha_gate',
        postType: PostType.doubt,
        title: 'Can a system be in an unsafe state in Banker\'s Algorithm without deadlock?',
        topic: 'Operating System',
        subtopic: 'Deadlock Detection & Avoidance',
        examTag: GateSyllabus.gateCS,
        trapStatement:
            'If Banker\'s safety algorithm returns false, does it mean the system is currently deadlocked, or just that a deadlock could potentially occur depending on future requests?',
        fixStatement:
            'An UNSAFE state is strictly NOT a deadlock! It only means the OS cannot guarantee completion if every process simultaneously requests its maximum declared claims. Processes may terminate and release resources early without any deadlock.',
        isResolved: true,
        audioDurationSeconds: 30,
        sameCount: 94,
        clearedCount: 33,
        keepCount: 51,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Slip(
        id: 'slip-cs-d03',
        authorId: 'peer_ananya',
        authorUsername: 'ananya_gate',
        postType: PostType.doubt,
        title: 'Does every regular language have a unique minimal DFA up to isomorphism?',
        topic: 'Theory of Computation',
        subtopic: 'Regular Expressions & Finite Automata (DFA, NFA)',
        examTag: GateSyllabus.gateCS,
        trapStatement:
            'By Myhill-Nerode theorem, minimal DFA for a regular language is unique up to state renaming. But does this also apply if there are unreachable states, or must they be pruned first?',
        fixStatement:
            'Unreachable states must strictly be removed first. The Myhill-Nerode equivalence classes correspond 1-to-1 with states in the minimal reachable DFA. With unreachable states removed, the minimal DFA is uniquely canonical.',
        isResolved: false,
        audioDurationSeconds: 0,
        sameCount: 76,
        clearedCount: 15,
        keepCount: 40,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),

      // --- GATE CS MISTAKES / BLUNDERS ---
      Slip(
        id: 'slip-cs-01',
        authorId: 'peer_arya',
        authorUsername: 'arya',
        postType: PostType.mistake,
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
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      Slip(
        id: 'slip-cs-02',
        authorId: 'peer_rohit',
        authorUsername: 'rohit',
        postType: PostType.mistake,
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
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Slip(
        id: 'slip-cs-03',
        authorId: 'peer_kavya',
        authorUsername: 'kavya',
        postType: PostType.mistake,
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
        createdAt: DateTime.now().subtract(const Duration(hours: 16)),
      ),

      // --- GATE DA DOUBTS & MISTAKES ---
      Slip(
        id: 'slip-da-d01',
        authorId: 'peer_karthik',
        authorUsername: 'karthik_da',
        postType: PostType.doubt,
        title: 'Why does PCA maximize variance while simultaneously minimizing reconstruction error?',
        topic: 'Machine Learning',
        subtopic: 'Principal Component Analysis (PCA)',
        examTag: GateSyllabus.gateDA,
        trapStatement:
            'I understand the algebraic derivation maximizing w^T S w, but geometrically why does the direction of greatest variance mathematically equate to the minimum orthogonal squared projection distance?',
        fixStatement:
            'By the Pythagorean theorem: ||x||^2 = ||x_proj||^2 + ||x_recon_error||^2. Because the total data norm ||x||^2 is fixed, maximizing the projected variance ||x_proj||^2 strictly minimizes the orthogonal error ||x_recon_error||^2.',
        isResolved: true,
        audioDurationSeconds: 32,
        sameCount: 110,
        clearedCount: 39,
        keepCount: 67,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Slip(
        id: 'slip-da-01',
        authorId: 'peer_devansh',
        authorUsername: 'devansh',
        postType: PostType.mistake,
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
        authorId: 'peer_meera',
        authorUsername: 'meera',
        postType: PostType.mistake,
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

      // --- GATE EC ---
      Slip(
        id: 'slip-ec-d01',
        authorId: 'peer_shreya',
        authorUsername: 'shreya_ec',
        postType: PostType.doubt,
        title: 'Why does convolution in time domain equal multiplication in frequency domain for LTI systems?',
        topic: 'Networks, Signals and Systems',
        subtopic: 'LTI Systems: Impulse Response, Convolution, Poles/Zeroes',
        examTag: GateSyllabus.gateEC,
        trapStatement:
            'Is this property inherent to Fourier transform definition, or is it fundamentally because complex exponentials e^(st) are the eigenfunctions of continuous LTI systems?',
        fixStatement:
            'Fundamentally because complex exponentials e^(st) are eigenfunctions of LTI systems: T{e^(st)} = H(s) * e^(st). The Fourier transform decomposes any signal into these eigenfunctions, reducing convolution directly to scalar eigenvalue multiplication.',
        isResolved: true,
        audioDurationSeconds: 41,
        sameCount: 92,
        clearedCount: 31,
        keepCount: 54,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Slip(
        id: 'slip-ec-01',
        authorId: 'peer_tanvi',
        authorUsername: 'tanvi',
        postType: PostType.mistake,
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

      // --- GATE EE ---
      Slip(
        id: 'slip-ee-d01',
        authorId: 'peer_rahul',
        authorUsername: 'rahul_ee',
        postType: PostType.doubt,
        title: 'Why does armature reaction demagnetize in synchronous generator at lagging power factor?',
        topic: 'Electrical Machines',
        subtopic: 'Single-Phase Transformer: Phasors, OC/SC Tests, Regulation',
        examTag: GateSyllabus.gateEE,
        trapStatement:
            'At zero lagging power factor, is the armature flux directly opposing the main rotor field flux (direct axis demagnetizing)? How does this shift between generator and motor action?',
        fixStatement:
            'At lagging PF (inductive load), armature current lags induced EMF by 90°. Since EMF lags rotor flux by 90°, the armature current peaks when rotor poles have moved 180° out of phase, directly opposing the main field flux (pure demagnetization). In motors, the current direction is reversed, leading to magnetization.',
        isResolved: true,
        audioDurationSeconds: 38,
        sameCount: 83,
        clearedCount: 27,
        keepCount: 49,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Slip(
        id: 'slip-ee-01',
        authorId: 'peer_devansh',
        authorUsername: 'devansh',
        postType: PostType.mistake,
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
    ];
  }
}
