class Usuario {
  final String id;
  final String email;
  final String accessToken;
  final String refreshToken;

  Usuario({
    required this.id,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Resposta do endpoint /auth/v1/token do Supabase.
  factory Usuario.fromAuthResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Usuario(
      id: user['id'] as String,
      email: user['email'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  /// Formato salvo no aparelho (shared_preferences).
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        email: json['email'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
