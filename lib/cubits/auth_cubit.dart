import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import '../services/sessao_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final SessaoService sessao;

  AuthCubit({required this.repository, required this.sessao}) : super(AuthInitial());

  /// Abre o app com a sessão salva, mesmo sem internet (offline-first).
  Future<void> verificarSessao() async {
    final usuario = await sessao.carregar();
    emit(usuario != null ? Authenticated(usuario) : Unauthenticated());
  }

  Future<void> realizarLogin(String email, String senha) async {
    if (email.trim().isEmpty || senha.trim().isEmpty) {
      emit(AuthError('Preencha todos os campos para realizar o login!'));
      return;
    }

    emit(AuthLoading());
    try {
      final usuario = await repository.login(email: email.trim(), senha: senha);
      await sessao.salvar(usuario);
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(_mensagem(e)));
    }
  }

  Future<void> realizarCadastro(String email, String senha) async {
    if (email.trim().isEmpty || senha.trim().isEmpty) {
      emit(AuthError('Preencha todos os campos para criar a conta!'));
      return;
    }
    if (senha.length < 6) {
      emit(AuthError('A senha deve ter pelo menos 6 caracteres.'));
      return;
    }

    emit(AuthLoading());
    try {
      await repository.cadastrar(email: email.trim(), senha: senha);
      final usuario = await repository.login(email: email.trim(), senha: senha);
      await sessao.salvar(usuario);
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(_mensagem(e)));
    }
  }

  Future<void> logout() async {
    await sessao.limpar();
    emit(Unauthenticated());
  }

  String _mensagem(Object erro) => erro.toString().replaceFirst('Exception: ', '');
}
