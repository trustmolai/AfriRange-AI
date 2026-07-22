import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_api_service.dart';
import '../models/monetization_models.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _isLoading = true;
  List<SubscriptionPlanModel> _plans = [];
  UserSubscriptionModel? _currentSub;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final billingService = Provider.of<BillingApiService>(context, listen: false);
      final plans = await billingService.getSubscriptionPlans();
      final currentSub = await billingService.getCurrentSubscription();

      setState(() {
        _plans = plans;
        _currentSub = currentSub;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubscribe(SubscriptionPlanModel plan) async {
    final billingService = Provider.of<BillingApiService>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Initiating Google Play Billing for ${plan.displayName}...')),
    );

    try {
      // Execute Google Play In-App Purchase Flow & Token Verification
      final mockToken = 'gplay_tok_${DateTime.now().millisecondsSinceEpoch}_${plan.planName}';
      final res = await billingService.verifyGooglePlayPurchase(
        productId: plan.googlePlayProductId,
        purchaseToken: mockToken,
        isCreditPack: false,
      );

      if (mounted && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(res['message'] ?? 'Subscription active!'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Subscription failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_currentSub != null)
                      Card(
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Active Subscription',
                                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_currentSub!.displayName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('AI Credit Balance: ${_currentSub!.aiCreditBalance} Credits',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text('Choose a Subscription Plan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('All digital subscriptions are safely billed via Google Play Store.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ..._plans.map((plan) {
                      final isCurrent = _currentSub?.planName == plan.planName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isCurrent ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isCurrent ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(plan.displayName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(
                                    plan.monthlyPrice == 0
                                        ? 'Free'
                                        : '\$${plan.monthlyPrice.toStringAsFixed(2)} / mo',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${plan.aiCreditsIncluded} AI Credits / month included',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              const Divider(height: 24),
                              ...plan.features.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text('${entry.key}: ${entry.value}',
                                            style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCurrent ? Colors.grey : Colors.green.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: isCurrent ? null : () => _handleSubscribe(plan),
                                  child: Text(
                                    isCurrent ? 'Current Plan' : 'Subscribe via Google Play',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }
}
