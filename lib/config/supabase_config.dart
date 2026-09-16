import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.get('SUPABASE_URL');
  static String get anonKey => dotenv.get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID');
}
