import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../repositories/auth_repository.dart';

/// Guarda a sessão do usuário no aparelho para o app abrir mesmo offline.
class SessaoService {
  static const String _chave = 'petcare_sessao';

  final AuthRepository authRepository;
  Usuario? usuario;

  SessaoService(this.authRepository);

  bool get logado => usuario != null;

  Future<Usuario?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return null;
    try {
      usuario = Usuario.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      usuario = null;
    }
    return usuario;
  }

  Future<void> salvar(Usuario novoUsuario) async {
    usuario = novoUsuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(novoUsuario.toJson()));
  }

  Future<void> renovarToken() async {
    final atual = usuario;
    if (atual == null) throw Exception('Nenhum usuário logado.');
    final renovado = await authRepository.renovarToken(atual.refreshToken);
    await salvar(renovado);
  }

  Future<void> limpar() async {
    usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
