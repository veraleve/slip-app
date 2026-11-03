import 'gate_syllabus.dart';

class AppConstants {
  static const String appName = 'SLIP';
  static const String appVersion = 'v0.1.8';
  static const String tagline = 'PEER MISTAKE INOCULATION NETWORK';

  // Supabase Configuration (Injected via --dart-define or GitHub Secrets)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://grydnpgufybxvmovdumg.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Exams (All 4 GATE Branches)
  static const List<String> supportedExams = GateSyllabus.supportedExams;

  // Default Topics
  static List<String> get defaultTopics =>
      GateSyllabus.getSubjectsForExam(GateSyllabus.gateCS);
}
