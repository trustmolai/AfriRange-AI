import 'user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticating extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
