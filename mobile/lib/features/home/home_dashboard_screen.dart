import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/auth/models/auth_state.dart';
import '../grazing/screens/vegetation_dashboard_screen.dart';
import '../grazing/screens/recommendation_dashboard_screen.dart';
import '../grazing/screens/rotational_plans_screen.dart';
import '../climate_intelligence/screens/climate_dashboard_screen.dart';
import '../climate_intelligence/screens/drought_forecast_screen.dart';
import '../climate_intelligence/screens/alerts_screen.dart';
import '../monetization/screens/plans_screen.dart';
import '../monetization/screens/ai_credits_screen.dart';
import '../onboarding/screens/tool_onboarding_wizard.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _checkOnboardingAndLaunch(BuildContext context, String toolTitle, Widget targetScreen) {
    final authState = context.read<AuthBloc>().state;
    final bool hasCompletedOnboarding = authState is AuthAuthenticated
        ? authState.user.hasCompletedOnboarding
        : false;

    if (!hasCompletedOnboarding) {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (_) => ToolOnboardingWizard(
          targetToolTitle: toolTitle,
          onComplete: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
          },
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Farmer';
    String occupationBadge = '';
    String currencySymbol = '\$';

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      userName = user.firstName ?? (user.fullName != null && user.fullName!.isNotEmpty ? user.fullName!.split(' ').first : 'Farmer');
      if (user.occupation != null && user.occupation!.isNotEmpty) {
        occupationBadge = ' (${user.occupation![0].toUpperCase()}${user.occupation!.substring(1)})';
      }
      currencySymbol = user.currencySymbol;
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('AfriRange AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Alerts',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$userName$occupationBadge',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your rangeland, livestock, and satellite intelligence from here.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _QuickActionCard(
                  icon: Icons.satellite_alt,
                  title: 'Satellite\nVegetation',
                  subtitle: 'NDVI & biomass',
                  color: const Color(0xFF2E7D32),
                  onTap: () => _checkOnboardingAndLaunch(
                    context,
                    'Satellite Vegetation',
                    const VegetationDashboardScreen(),
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.psychology,
                  title: 'AI Grazing\nAdvisor',
                  subtitle: 'Get recommendations',
                  color: const Color(0xFF1565C0),
                  onTap: () => _checkOnboardingAndLaunch(
                    context,
                    'AI Grazing Advisor',
                    const RecommendationDashboardScreen(),
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.calendar_month,
                  title: 'Rotational\nPlans',
                  subtitle: 'Manage schedules',
                  color: const Color(0xFFEF6C00),
                  onTap: () => _checkOnboardingAndLaunch(
                    context,
                    'Rotational Plans',
                    const RotationalPlansScreen(),
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.cloud_outlined,
                  title: 'Climate\nIntelligence',
                  subtitle: 'Drought & weather',
                  color: const Color(0xFF6A1B9A),
                  onTap: () => _checkOnboardingAndLaunch(
                    context,
                    'Climate Intelligence',
                    const DroughtForecastScreen(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Rangeland Snapshot
            const Text(
              'Rangeland Snapshot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SnapshotRow(icon: Icons.grass, label: 'Average NDVI', value: '0.52', color: Colors.green),
                    const Divider(height: 24),
                    _SnapshotRow(icon: Icons.pets, label: 'Stocking Pressure', value: '58%', color: Colors.orange),
                    const Divider(height: 24),
                    _SnapshotRow(icon: Icons.water_drop, label: 'Drought Risk', value: 'Low', color: Colors.blue),
                    const Divider(height: 24),
                    _SnapshotRow(icon: Icons.eco, label: 'Veld Condition', value: 'Good', color: const Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subscription CTA
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: Color(0xFFF57C00)),
                title: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Unlock unlimited satellite scans & AI credits'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen()));
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SnapshotRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
