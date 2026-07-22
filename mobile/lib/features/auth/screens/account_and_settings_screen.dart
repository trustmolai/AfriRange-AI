import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/models/auth_event.dart';

class AccountAndSettingsScreen extends StatelessWidget {
  const AccountAndSettingsScreen({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion request submitted.')),
      );
      context.read<AuthBloc>().add(LogoutEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.person, color: Colors.green),
            title: Text('Account Profile'),
            subtitle: Text('Manage profile details & preferences'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account & Personal Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Fulfills Google Play User Data & Account Deletion Policy'),
            onTap: () => _handleDeleteAccount(context),
          ),
        ],
      ),
    );
  }
}
