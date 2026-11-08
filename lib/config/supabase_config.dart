/// Dados do projeto no Supabase.
/// Troque pelos valores do seu projeto em: Project Settings > API.
class SupabaseConfig {
  static const String url = 'https://cefzxbeyewupfxowchac.supabase.co';
  static const String publishableKey = '<SUA_KEY>';

  /// Bucket do Storage onde ficam as fotos (precisa ser público).
  static const String bucketFotos = 'petcare';

  static String get authUrl => '$url/auth/v1';
  static String get restUrl => '$url/rest/v1';
  static String get storageUrl => '$url/storage/v1';
}
