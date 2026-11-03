import 'gate_syllabus.dart';

class AppConstants {
  static const String appName = 'SLIP';
  static const String appVersion = 'v1.0.0';
  static const String tagline = 'PEER MISTAKE INOCULATION NETWORK';

  // Supabase Configuration
  static const String supabaseUrl = 'https://grydnpgufybxvmovdumg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_VXnufLFzFqjaLkNP_u2lbg_kYr3oTfi';

  // Exams (All 4 GATE Branches)
  static const List<String> supportedExams = GateSyllabus.supportedExams;

  // Default Topics
  static List<String> get defaultTopics =>
      GateSyllabus.getSubjectsForExam(GateSyllabus.gateCS);
}
