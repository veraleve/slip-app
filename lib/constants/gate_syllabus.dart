class GateSyllabus {
  static const String gateCS = 'GATE CS';
  static const String gateDA = 'GATE DA';
  static const String gateEC = 'GATE EC';
  static const String gateEE = 'GATE EE';

  static const List<String> supportedExams = [
    gateCS,
    gateDA,
    gateEC,
    gateEE,
  ];

  // Normalize any incoming string (e.g. 'GATE CS 2027' -> 'GATE CS')
  static String normalizeExam(String? exam) {
    if (exam == null || exam.isEmpty) return gateCS;
    final clean = exam.replaceAll(RegExp(r'\s*\d{4}$'), '').trim();
    if (supportedExams.contains(clean)) return clean;
    return gateCS;
  }

  // ==========================================
  // GATE CS (Computer Science & IT)
  // ==========================================
  static const Map<String, List<String>> csSyllabus = {
    'Discrete Mathematics': [
      'Propositional & First Order Logic',
      'Sets, Relations & Functions',
      'Partial Orders & Lattices',
      'Monoids & Groups',
      'Graphs: Connectivity, Matching, Colouring',
      'Combinatorics: Counting & Recurrence Relations',
      'Generating Functions',
    ],
    'Linear Algebra': [
      'Matrices & Determinants',
      'System of Linear Equations',
      'Eigenvalues & Eigenvectors',
      'LU Decomposition',
    ],
    'Calculus': [
      'Limits, Continuity & Differentiability',
      'Maxima & Minima',
      'Mean Value Theorem',
      'Integration',
    ],
    'Probability and Statistics': [
      'Random Variables',
      'Uniform, Normal, Exponential Distributions',
      'Poisson & Binomial Distributions',
      'Mean, Median, Mode & Standard Deviation',
      'Conditional Probability & Bayes Theorem',
    ],
    'Digital Logic': [
      'Boolean Algebra & K-Maps',
      'Tabular Minimization Method',
      'Combinational Circuit Design (MUX, Decoders)',
      'Sequential Circuits & Flip-Flops',
      'Number Representation & Floating Point (IEEE 754)',
    ],
    'Computer Organization & Architecture': [
      'Instruction Set & Addressing Modes',
      'ALU Design',
      'Control Unit (Hardwired & Microprogrammed)',
      'Memory Hierarchy & Cache Mapping',
      'I/O Interface, Interrupts & DMA',
      'Instruction Pipelining & Pipeline Hazards',
    ],
    'Programming & Data Structures': [
      'Programming in C & Recursion',
      'Arrays, Stacks & Queues',
      'Linked Lists',
      'Trees, Binary Search Trees & Heaps',
      'Graphs',
    ],
    'Algorithms': [
      'Searching, Sorting & Hashing',
      'Asymptotic Time & Space Complexity',
      'Greedy Algorithms',
      'Dynamic Programming',
      'Divide-and-Conquer',
      'Graph Traversals, MST & Shortest Paths',
    ],
    'Theory of Computation': [
      'Regular Expressions & Finite Automata (DFA, NFA)',
      'Context-Free Grammars & PDA',
      'Regular & Context-Free Languages',
      'Pumping Lemma',
      'Turing Machines & Undecidability',
    ],
    'Compiler Design': [
      'Lexical Analysis & Parsing',
      'Syntax-Directed Translation (SDT)',
      'Runtime Environments',
      'Intermediate Code Generation',
      'Local Optimization & Data Flow Analyses',
    ],
    'Operating System': [
      'System Calls, Processes & Threads',
      'IPC & Synchronization (Semaphores)',
      'Deadlock Detection & Avoidance',
      'CPU and I/O Scheduling',
      'Memory Management & Virtual Memory (Paging, TLB)',
      'File Systems',
    ],
    'Databases': [
      'ER-Model & Relational Algebra',
      'SQL Queries & Tuple Calculus',
      'Integrity Constraints & Normal Forms (1NF-BCNF)',
      'File Organization & Indexing (B/B+ Trees)',
      'Transactions & Concurrency Control (2PL, ACID)',
    ],
    'Computer Networks': [
      'Principles of Layering & Switching',
      'Data Link Layer & MAC (Ethernet)',
      'Distance Vector & Link State Routing',
      'IPv4: Fragmentation, CIDR, NAT',
      'TCP: Flow & Congestion Control, Sockets',
      'Application Protocols: DNS & HTTP',
    ],
  };

  // ==========================================
  // GATE DA (Data Science & AI)
  // ==========================================
  static const Map<String, List<String>> daSyllabus = {
    'Probability and Statistics': [
      'Permutations & Combinations (Counting)',
      'Probability Axioms, Sample Space & Events',
      'Marginal, Conditional & Joint Probability',
      'Bayes Theorem & Total Probability',
      'Conditional Expectation & Variance',
      'Mean, Median, Mode, Correlation & Covariance',
      'Discrete Distributions (Bernoulli, Binomial, Uniform)',
      'Continuous Distributions (Exponential, Poisson, Normal, t, Chi-Sq)',
      'Cumulative Distribution Function (CDF)',
      'Central Limit Theorem',
      'Hypothesis Testing (z-test, t-test, chi-squared)',
      'Confidence Intervals',
    ],
    'Linear Algebra': [
      'Vector Space, Subspaces & Basis',
      'Linear Independence & Dependence',
      'Projection Matrix, Orthogonal & Idempotent Matrix',
      'Partition Matrix & Properties',
      'Quadratic Forms',
      'Systems of Linear Equations & Gaussian Elimination',
      'Eigenvalues & Eigenvectors',
      'Determinant, Rank & Nullity',
      'LU Decomposition',
      'Singular Value Decomposition (SVD)',
    ],
    'Calculus and Optimization': [
      'Functions of Single Variable',
      'Limits, Continuity & Differentiability',
      'Taylor Series',
      'Maxima and Minima',
      'Optimization Involving Single Variable',
    ],
    'Programming, Data Structures & Algorithms': [
      'Programming in Python',
      'Stacks, Queues, Linked Lists & Trees',
      'Hash Tables',
      'Linear Search & Binary Search',
      'Sorting (Selection, Bubble, Insertion, Mergesort, Quicksort)',
      'Graph Theory & Graph Traversals',
      'Shortest Path Algorithms',
    ],
    'Database Management and Warehousing': [
      'ER-Model & Relational Model',
      'Relational Algebra, Tuple Calculus & SQL',
      'Integrity Constraints & Normal Forms',
      'File Organization & Indexing',
      'Data Transformation (Normalization, Sampling)',
      'Data Warehouse Modeling & Multidimensional Schemas',
      'Concept Hierarchies & Measures',
    ],
    'Machine Learning': [
      'Simple & Multiple Linear Regression',
      'Ridge Regression & Regularization',
      'Logistic Regression',
      'K-Nearest Neighbour (KNN)',
      'Naive Bayes Classifier',
      'Linear Discriminant Analysis (LDA)',
      'Support Vector Machine (SVM)',
      'Decision Trees',
      'Bias-Variance Trade-off',
      'Cross-Validation (LOO, K-Fold)',
      'Multi-Layer Perceptron (MLP)',
      'Feed-Forward Neural Networks',
      'Clustering (K-Means, K-Medoids)',
      'Hierarchical Clustering',
      'Dimensionality Reduction: PCA',
    ],
    'Artificial Intelligence': [
      'Informed & Uninformed Search (BFS, DFS, A*)',
      'Adversarial Search (Minimax, Alpha-Beta)',
      'Propositional & Predicate Logic',
      'Reasoning Under Uncertainty: Conditional Independence',
      'Exact Inference via Variable Elimination',
      'Approximate Inference via Sampling',
    ],
  };

  // ==========================================
  // GATE EC (Electronics & Communication)
  // ==========================================
  static const Map<String, List<String>> ecSyllabus = {
    'Engineering Mathematics': [
      'Linear Algebra: Vector Space, Rank, Eigenvalues',
      'Calculus: Mean Value, Multiple Integrals, Taylor Series',
      'Differential Equations: Cauchy, Laplace, PDE',
      'Vector Analysis: Gradient, Divergence, Stokes Theorem',
      'Complex Analysis: Cauchy Integral, Residue Theorem',
      'Probability: Distributions, Correlation & Regression',
    ],
    'Networks, Signals and Systems': [
      'Node & Mesh Analysis, Thevenin, Norton',
      'Sinusoidal Steady State & Maximum Power Transfer',
      'RL, RC, RLC Transient Analysis & 2-Port Networks',
      'LTI Systems: Impulse Response, Convolution, Poles/Zeroes',
      'Continuous-Time Signals: Fourier Series & Transform',
      'Sampling Theorem & Reconstruction',
      'Discrete-Time Signals: DTFT, DFT, Z-Transform, FIR/IIR',
    ],
    'Electronic Devices': [
      'Energy Bands in Solids & Carrier Concentration',
      'Carrier Transport: Drift, Diffusion, Mobility',
      'P-N Junction & Zener Diode',
      'BJT, MOS Capacitor & MOSFET',
      'Scaling in MOSFETs',
      'LED, Photodiode & Solar Cell',
    ],
    'Analog Circuits': [
      'Diode Circuits: Clipping, Clamping & Rectifiers',
      'BJT and MOSFET Amplifiers & Biasing',
      'Small Signal Analysis & Frequency Response',
      'Current Mirrors & Differential Amplifiers',
      'Op-Amp Circuits, Summers, Integrators, Filters',
      'Schmitt Trigger, Oscillators & Miller Compensation',
    ],
    'Digital Circuits': [
      'Number Representations & Arithmetic Circuits',
      'Combinatorial Circuits & K-Map Minimization',
      'Sequential Circuits: Flip-Flops, Counters, FSM',
      'Propagation Delay, Setup & Hold Time',
      'Data Converters: ADCs and DACs',
      'Semiconductor Memories: ROM, SRAM, DRAM',
      'Computer Organization & Addressing Modes',
    ],
    'Control Systems': [
      'Feedback Principle & Transfer Functions',
      'Block Diagrams & Signal Flow Graphs',
      'Transient & Steady-State Analysis',
      'Routh-Hurwitz & Nyquist Stability Criteria',
      'Bode Plots & Root-Locus',
      'Compensators & PID Controllers',
      'State Variable Model & State Equations',
    ],
    'Communications': [
      'Random Processes, Autocorrelation & PSD',
      'Analog Communications: AM, FM & Superheterodyne',
      'Information Theory: Entropy & Channel Capacity',
      'Digital Communications: PCM, DPCM, ASK, PSK, QAM',
      'Matched Filter Receiver, SNR & BER',
      'Error Correction: Hamming Codes & CRC',
    ],
    'Electromagnetics': [
      'Maxwells Equations & Boundary Conditions',
      'Plane Waves: Reflection, Refraction, Skin Depth',
      'Transmission Lines: Characteristic Impedance & Smith Chart',
      'Waveguides & Optical Fibers',
      'Antennas: Dipole, Monopole & Arrays',
    ],
  };

  // ==========================================
  // GATE EE (Electrical Engineering)
  // ==========================================
  static const Map<String, List<String>> eeSyllabus = {
    'Engineering Mathematics': [
      'Linear Algebra: Matrix Algebra, Systems, Eigenvalues',
      'Calculus: Mean Value, Multiple Integrals, Vector Identities, Stokes',
      'Differential Equations: Cauchy-Euler, Higher Order, Separation',
      'Complex Variables: Cauchy Integral, Laurent, Residue Theorem',
      'Probability & Stats: Distributions, Poisson, Normal, Correlation',
    ],
    'Electric Circuits': [
      'Network Elements (R, L, C, M) & Sources',
      'KCL, KVL, Node and Mesh Analysis',
      'Network Theorems: Thevenin, Norton, Superposition, Max Power',
      'Transient Response of DC & AC Networks',
      'Sinusoidal Steady-State & Resonance',
      'Two-Port Networks & Star-Delta Transformation',
      'Three-Phase Balanced Circuits & Power Factor',
    ],
    'Electromagnetic Fields': [
      'Coulombs Law, Electric Field & Gauss Law',
      'Dielectric Medium & Capacitance',
      'Biot-Savart Law, Amperes Law & Magnetic Circuits',
      'Faradays Law, Lorentz Force & Reluctance',
      'Self and Mutual Inductance',
    ],
    'Signals and Systems': [
      'Continuous & Discrete Time Signals, Shifting & Scaling',
      'LTI & Causal Systems',
      'Fourier Series & Fourier Transform',
      'Sampling Theorem',
      'Laplace Transform & Z-Transform',
      'RMS & Average Value of Periodic Waveforms',
    ],
    'Electrical Machines': [
      'Single-Phase Transformer: Phasors, OC/SC Tests, Regulation',
      'Three-Phase Transformers & Vector Groups',
      'DC Machines: Characteristics, Motoring & Speed Control',
      'Three-Phase Induction Machines: Torque-Speed, Tests, Starting',
      'Single-Phase Induction Motors',
      'Synchronous Machines: Salient Pole, Regulation, Parallel Operation',
      'Losses & Efficiency Calculations',
    ],
    'Power Systems': [
      'Generation & AC/DC Transmission Lines',
      'Economic Load Dispatch & Losses',
      'Insulators & Distribution Systems',
      'Per-Unit Quantities & Bus Admittance Matrix',
      'Gauss-Seidel & Newton-Raphson Load Flow',
      'Symmetrical Components & Fault Analysis',
      'Protection: Over-Current, Differential, Distance & Breakers',
      'Power System Stability & Equal Area Criterion',
    ],
    'Control Systems': [
      'Mathematical Modelling, Feedback & Transfer Functions',
      'Block Diagrams & Signal Flow Graphs',
      'Transient & Steady-State Analysis',
      'Routh-Hurwitz & Nyquist Stability Criteria',
      'Bode Plots & Root Loci',
      'Compensators (Lag, Lead, Lead-Lag) & PID Controllers',
      'State Space Model & State Equations',
    ],
    'Electrical and Electronic Measurements': [
      'Bridges & Potentiometers',
      'Measurement of Voltage, Current, Power, Energy & Power Factor',
      'Instrument Transformers (CT & PT)',
      'Digital Voltmeters & Multi-meters',
      'Oscilloscopes & Error Analysis',
    ],
    'Analog and Digital Electronics': [
      'Diode Circuits: Clipping, Clamping & Rectifiers',
      'Amplifiers: Biasing & Frequency Response',
      'Op-Amps: Characteristics & Applications',
      'Active Filters: Sallen-Key & Butterworth',
      'Combinatorial & Sequential Logic Circuits',
      'Schmitt Triggers, Sample & Hold, ADCs & DACs',
    ],
    'Power Electronics': [
      'Thyristor, MOSFET & IGBT Characteristics',
      'DC to DC Converters: Buck, Boost, Buck-Boost',
      'Uncontrolled & Controlled Rectifiers (1-Phase & 3-Phase)',
      'Line Current Harmonics & Distortion Factor',
      'Voltage & Current Source Inverters, Sinusoidal PWM',
    ],
  };

  static List<String> getSubjectsForExam(String exam) {
    final normalized = normalizeExam(exam);
    switch (normalized) {
      case gateDA:
        return daSyllabus.keys.toList();
      case gateEC:
        return ecSyllabus.keys.toList();
      case gateEE:
        return eeSyllabus.keys.toList();
      case gateCS:
      default:
        return csSyllabus.keys.toList();
    }
  }

  static List<String> getSubtopics(String exam, String subject) {
    final normalized = normalizeExam(exam);
    switch (normalized) {
      case gateDA:
        return daSyllabus[subject] ?? [];
      case gateEC:
        return ecSyllabus[subject] ?? [];
      case gateEE:
        return eeSyllabus[subject] ?? [];
      case gateCS:
      default:
        return csSyllabus[subject] ?? [];
    }
  }
}
