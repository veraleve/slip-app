class AppConstants {
  static const String appName = 'SLIP';
  static const String appVersion = 'v1.0.0';
  static const String tagline = 'PEER MISTAKE INOCULATION NETWORK';

  // Supabase Configuration
  static const String supabaseUrl = 'https://grydnpgufybxvmovdumg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_VXnufLFzFqjaLkNP_u2lbg_kYr3oTfi';

  // Exams
  static const List<String> supportedExams = [
    'GATE CS 2027',
    'GATE DA 2027',
    'GATE ECE 2027',
    'GATE EE 2027',
  ];

  // Topics for GATE CS
  static const List<String> gateTopics = [
    'Linear Algebra',
    'Calculus & Probability',
    'Discrete Mathematics',
    'Data Structures & Algorithms',
    'Theory of Computation',
    'Compiler Design',
    'Operating Systems',
    'Database Management Systems',
    'Computer Networks',
    'Computer Organization & Architecture',
  ];
}
