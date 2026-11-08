import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(Unauthenticated());

  Future<void> realizarLogin(String email, String senha) async {
    if (email.trim().isEmpty || senha.trim().isEmpty) {
      emit(AuthError("Preencha todos os campos para realizar o login!"));
      return;
    }

    emit(AuthLoading());

    try {
      final usuario = await repository.login(email: email, senha: senha);
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> realizarCadastro(String email, String senha) async {
    if (email.trim().isEmpty || senha.trim().isEmpty) {
      emit(AuthError("Preencha todos os campos para realizar o login!"));
      return;
    }

    emit(AuthLoading());

    try {
      await repository.cadastrar(email: email, senha: senha);
      final usuario = await repository.login(email: email, senha: senha);
      emit(Authenticated(usuario));
    } catch (e) {
      emit(AuthError(e.toString()));
    }

  }

  void logout() {
    emit(Unauthenticated());
  }

}