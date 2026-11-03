import 'gate_syllabus.dart';

class AppConstants {
  static const String appName = 'SLIP';
  static const String appVersion = 'v0.1.10';
  static const String tagline = 'PEER MISTAKE INOCULATION NETWORK';

  // Supabase Configuration (Injected via --dart-define or GitHub Secrets, with production fallback)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://grydnpgufybxvmovdumg.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyeWRucGd1ZnlieHZtb3ZkdW1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2NTkyMDMsImV4cCI6MjEwOTIzNTIwM30.OM2lsAooaLbkmG0GRAkgH2_s-yJKlgxniLCe_1g_OzQ',
  );

  // Exams (All 4 GATE Branches)
  static const List<String> supportedExams = GateSyllabus.supportedExams;

  // Default Topics
  static List<String> get defaultTopics =>
      GateSyllabus.getSubjectsForExam(GateSyllabus.gateCS);
}
