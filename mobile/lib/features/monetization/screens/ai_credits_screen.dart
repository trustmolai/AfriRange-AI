import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_api_service.dart';
import '../models/monetization_models.dart';

class AiCreditsScreen extends StatefulWidget {
  const AiCreditsScreen({Key? key}) : super(key: key);

  @override
  State<AiCreditsScreen> createState() => _AiCreditsScreenState();
}

class _AiCreditsScreenState extends State<AiCreditsScreen> {
  bool _isLoading = true;
  int _creditBalance = 0;
  List<AiCreditTransactionModel> _history = [];
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
      final balance = await billingService.getCreditBalance();
      final history = await billingService.getCreditHistory();

      setState(() {
        _creditBalance = balance;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _buyCreditPack(int count, double price) async {
    final billingService = Provider.of<BillingApiService>(context, listen: false);

    try {
      final mockToken = 'gplay_pack_${DateTime.now().millisecondsSinceEpoch}';
      final productId = count == 100 ? 'afrirange_pack_100' : 'afrirange_pack_50';

      final res = await billingService.verifyGooglePlayPurchase(
        productId: productId,
        purchaseToken: mockToken,
        isCreditPack: true,
      );

      if (mounted && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(res['message'] ?? 'Credits added successfully!'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to purchase credits: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Credit Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance Card
                  Card(
                    elevation: 3,
                    color: Colors.green.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.bolt, color: Colors.amber, size: 40),
                          const SizedBox(height: 8),
                          const Text('Current AI Credit Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$_creditBalance',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Credits are deducted only after successful AI analysis requests.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Top-Up Credit Packs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Billed securely via Google Play in-app purchase',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPackCard(
                          count: 50,
                          price: 4.99,
                          onTap: () => _buyCreditPack(50, 4.99),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPackCard(
                          count: 100,
                          price: 9.99,
                          isBestValue: true,
                          onTap: () => _buyCreditPack(100, 9.99),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Usage & Top-Up History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No credit transaction history yet.')),
                    )
                  else
                    ..._history.map((tx) {
                      final isAddition = tx.creditsAdded > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAddition ? Colors.green.shade100 : Colors.orange.shade100,
                            child: Icon(
                              isAddition ? Icons.add : Icons.remove,
                              color: isAddition ? Colors.green : Colors.orange.shade800,
                            ),
                          ),
                          title: Text(tx.description ?? tx.transactionType,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                              tx.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' '),
                              style: const TextStyle(fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isAddition ? '+${tx.creditsAdded}' : '-${tx.creditsUsed}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isAddition ? Colors.green : Colors.red,
                                ),
                              ),
                              Text('Bal: ${tx.balanceAfter}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildPackCard({
    required int count,
    required double price,
    bool isBestValue = false,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBestValue ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('BEST VALUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            const SizedBox(height: 8),
            Text('$count Credits', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('\$$price', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
