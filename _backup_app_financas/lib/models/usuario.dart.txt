class Usuario {
  final String id;
  final String email;
  final String accessToken;

  Usuario({
    required this.id,
    required this.email,
    required this.accessToken
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Usuario(
      id: user['id'] as String, 
      email: user['email'] as String, 
      accessToken: json['access_token'] as String
    );
  }

}