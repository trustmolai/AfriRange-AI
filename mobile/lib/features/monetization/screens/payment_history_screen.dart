import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_api_service.dart';
import '../models/monetization_models.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<PaymentRecordModel> _payments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final billingService = Provider.of<BillingApiService>(context, listen: false);
      final history = await billingService.getPaymentHistory();

      setState(() {
        _payments = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment & Receipt History'),
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
                      ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? const Center(child: Text('No payment history recorded.'))
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final rec = _payments[index];
                          final isGPlay = rec.paymentProvider == 'google_play';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isGPlay ? Colors.blue.shade100 : Colors.teal.shade100,
                                child: Icon(
                                  isGPlay ? Icons.play_arrow : Icons.business,
                                  color: isGPlay ? Colors.blue.shade900 : Colors.teal.shade900,
                                ),
                              ),
                              title: Text(
                                isGPlay ? 'Google Play In-App Purchase' : 'External Enterprise Invoice',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ref: ${rec.transactionReference.substring(0, rec.transactionReference.length > 20 ? 20 : rec.transactionReference.length)}...'),
                                  Text(
                                    rec.createdAt.toIso8601String().substring(0, 10),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${rec.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: rec.status == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      rec.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: rec.status == 'completed' ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
