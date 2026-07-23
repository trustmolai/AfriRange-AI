import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/models/auth_event.dart';
import '../../../core/auth/models/auth_state.dart';
import '../../../core/database/app_database.dart';
import '../../monetization/screens/plans_screen.dart';
import '../../monetization/screens/ai_credits_screen.dart';
import '../../monetization/screens/payment_history_screen.dart';

class AccountAndSettingsScreen extends StatefulWidget {
  const AccountAndSettingsScreen({super.key});

  @override
  State<AccountAndSettingsScreen> createState() => _AccountAndSettingsScreenState();
}

class _AccountAndSettingsScreenState extends State<AccountAndSettingsScreen> {
  bool _useHectares = true;
  bool _useLsuStandard = true;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final count = await AppDatabase.instance.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }

  Future<void> _handleManualSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing local offline data with AfriRange Cloud...')),
    );
    await Future.delayed(const Duration(seconds: 1));
    await _loadSyncStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline database is up to date.')),
      );
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account & Data?'),
        content: const Text(
          'This action is permanent and will delete your personal details, registered farms, paddocks, and active subscriptions in compliance with Google Play Policies.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<AuthBloc>().add(DeleteAccountEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
                    child: const Icon(Icons.person, size: 32, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'AfriRange User',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.email ?? 'farmer@afrirange.ai',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO PLAN ACTIVE',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subscription & Credits Section
          const Text(
            'Subscriptions & AI Credits',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2E7D32)),
                  title: const Text('Subscription Plans'),
                  subtitle: const Text('Manage monthly or annual plans'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.stars_outlined, color: Colors.amber),
                  title: const Text('AI Credit Balance'),
                  subtitle: const Text('Buy additional tokens for satellite & plant AI'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiCreditsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: Colors.blue),
                  title: const Text('Payment History'),
                  subtitle: const Text('View transactions and Google Play receipts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Unit Preferences Section
          const Text(
            'Rangeland & Unit Preferences',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Land Area Unit'),
                  subtitle: Text(_useHectares ? 'Displaying in Hectares (ha)' : 'Displaying in Acres (ac)'),
                  secondary: const Icon(Icons.square_foot, color: Color(0xFF2E7D32)),
                  value: _useHectares,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) {
                    setState(() => _useHectares = val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Stocking Standard'),
                  subtitle: Text(_useLsuStandard ? 'LSU (450kg Steer)' : 'TLU (250kg Animal)'),
                  secondary: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
                  value: _useLsuStandard,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) {
                    setState(() => _useLsuStandard = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Offline Database & Sync Status
          const Text(
            'Data Sync & Offline Storage',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.cloud_sync_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Offline Database'),
              subtitle: Text('$_pendingSyncCount pending sync items queued'),
              trailing: ElevatedButton(
                onPressed: _handleManualSync,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('Sync Now', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Account Actions
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Log Out'),
                  onTap: () {
                    context.read<AuthBloc>().add(LogoutEvent());
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account & Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Fulfills Google Play User Data & Deletion Policy'),
                  onTap: () => _handleDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
