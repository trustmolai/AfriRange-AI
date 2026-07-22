import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_repository.dart';
import 'models/auth_event.dart';
import 'models/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticating());
    try {
      final user = await repository.checkAuthStatus();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticating());
    try {
      final user = await repository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticating());
    try {
      final user = await repository.register(event.email, event.password, event.fullName);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticating());
    await repository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onDeleteAccount(DeleteAccountEvent event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticating());
    try {
      await repository.deleteAccount();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
