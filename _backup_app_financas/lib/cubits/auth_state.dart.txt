import '../models/usuario.dart';

abstract class AuthState {}

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