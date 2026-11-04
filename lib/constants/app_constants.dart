import 'gate_syllabus.dart';

class AppConstants {
  static const String appName = 'SLIP';
  static const String appVersion = 'v0.1.20';
  static const String tagline = 'PEER MISTAKE INOCULATION NETWORK';

  static const String prodSupabaseUrl = 'https://grydnpgufybxvmovdumg.supabase.co';
  static const String prodSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyeWRucGd1ZnlieHZtb3ZkdW1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2NTkyMDMsImV4cCI6MjEwOTIzNTIwM30.OM2lsAooaLbkmG0GRAkgH2_s-yJKlgxniLCe_1g_OzQ';

  // Supabase Configuration (Injected via --dart-define or GitHub Secrets, with production fallback)
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static String get supabaseUrl =>
      (_envUrl.trim().isNotEmpty && _envUrl.trim() != '***')
          ? _envUrl.trim()
          : prodSupabaseUrl;

  static const String _envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get supabaseAnonKey {
    final key = _envKey.trim();
    if (key.isNotEmpty && key != '***' && !key.contains('1762230290')) {
      return key;
    }
    return prodSupabaseAnonKey;
  }

  // Exams (All 4 GATE Branches)
  static const List<String> supportedExams = GateSyllabus.supportedExams;

  // Default Topics
  static List<String> get defaultTopics =>
      GateSyllabus.getSubjectsForExam(GateSyllabus.gateCS);
}
