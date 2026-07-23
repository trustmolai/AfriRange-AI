import 'user_model.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class CheckAuthEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  const RegisterEvent({required this.email, required this.password, required this.fullName});
}

class LogoutEvent extends AuthEvent {}

class DeleteAccountEvent extends AuthEvent {}

class LoginDemoEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final UserModel updatedUser;
  const UpdateProfileEvent(this.updatedUser);
}

