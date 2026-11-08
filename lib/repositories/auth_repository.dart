import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/usuario.dart';

/// Autenticação pelo Supabase Auth (REST).
class AuthRepository {
  Map<String, String> get _headers => {
        'apikey': SupabaseConfig.publishableKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<void> cadastrar({required String email, required String senha}) async {
    final response = await http.post(
      Uri.parse('${SupabaseConfig.authUrl}/signup'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': senha}),
    );

    if (response.statusCode != 200) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['msg'] ?? erro['error_description'] ?? 'Erro ao realizar o cadastro.');
    }
  }

  Future<Usuario> login({required String email, required String senha}) async {
    final response = await http.post(
      Uri.parse('${SupabaseConfig.authUrl}/token?grant_type=password'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': senha}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Usuario.fromAuthResponse(data);
    }
    throw Exception(data['error_description'] ?? data['msg'] ?? 'Falha ao realizar o login.');
  }

  /// O access token expira em 1 hora; o refresh token gera um novo.
  Future<Usuario> renovarToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('${SupabaseConfig.authUrl}/token?grant_type=refresh_token'),
      headers: _headers,
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Usuario.fromAuthResponse(data);
    }
    throw Exception(data['error_description'] ?? 'Sessão expirada. Faça login novamente.');
  }
}
