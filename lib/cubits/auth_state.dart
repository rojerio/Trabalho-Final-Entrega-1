import '../models/usuario.dart';

sealed class AuthState {}

/// Verificando se existe sessão salva no aparelho.
class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Usuario usuario;
  Authenticated(this.usuario);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String erro;
  AuthError(this.erro);
}
