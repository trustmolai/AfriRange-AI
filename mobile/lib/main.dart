import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:afrirange_ai/core/auth/models/auth_state.dart';
import 'package:afrirange_ai/core/auth/models/auth_event.dart';
import 'package:afrirange_ai/core/auth/auth_repository.dart';
import 'package:afrirange_ai/core/database/app_database.dart';
import 'package:afrirange_ai/features/auth/screens/login_screen.dart';
import 'package:afrirange_ai/features/auth/screens/register_screen.dart';
import 'package:afrirange_ai/features/home/home_dashboard_screen.dart';
import 'package:afrirange_ai/features/paddock_mapping/paddock_map_screen.dart';
import 'package:afrirange_ai/features/plant_id/plant_scanner_screen.dart';
import 'package:afrirange_ai/features/livestock/screens/stocking_dashboard_screen.dart';
import 'package:afrirange_ai/features/auth/screens/account_and_settings_screen.dart';
import 'package:afrirange_ai/core/network/connectivity_cubit.dart';
import 'package:afrirange_ai/shared/widgets/afri_offline_banner.dart';
import 'package:afrirange_ai/config/theme.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web database factory when running on web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await AppDatabase.instance.init();
  
  final authRepository = AuthRepository();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(repository: authRepository)..add(CheckAuthEvent()),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (context) => ConnectivityCubit(),
        ),
      ],
      child: const AfriRangeApp(),
    ),
  );
}

class AfriRangeApp extends StatelessWidget {
  const AfriRangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfriRange AI',
      debugShowCheckedModeBanner: false,
      theme: AfriTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticating || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const MainNavigationWrapper();
        }

        if (_showRegister) {
          return RegisterScreen(
            onNavigateToLogin: () => setState(() => _showRegister = false),
          );
        }

        return LoginScreen(
          onNavigateToRegister: () => setState(() => _showRegister = true),
          onNavigateToForgotPassword: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset instructions sent to your email.')),
            );
          },
        );
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboardScreen(),
    const PaddockMapScreen(),
    const PlantScannerScreen(),
    const StockingDashboardScreen(),
    const AccountAndSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, state) {
              if (state == ConnectivityState.offline) {
                return const AfriOfflineBanner();
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Paddocks',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak_outlined),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Plant AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Livestock',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}