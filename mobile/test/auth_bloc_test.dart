import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:afrirange_ai/core/auth/auth_repository.dart';
import 'package:afrirange_ai/core/auth/models/auth_event.dart';
import 'package:afrirange_ai/core/auth/models/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AuthRepository repository;
  late AuthBloc authBloc;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    repository = AuthRepository();
    authBloc = AuthBloc(repository: repository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Unit Tests', () {
    test('Initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('LoginDemoEvent emits AuthAuthenticating then AuthAuthenticated', () async {
      final expectedStates = [
        isA<AuthAuthenticating>(),
        isA<AuthAuthenticated>(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(LoginDemoEvent());
    });

    test('LogoutEvent clears session and emits AuthUnauthenticated', () async {
      final expectedStates = [
        isA<AuthAuthenticating>(),
        isA<AuthUnauthenticated>(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(LogoutEvent());
    });
  });
}
