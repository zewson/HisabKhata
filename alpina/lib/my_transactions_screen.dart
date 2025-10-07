import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTransactionsScreen extends StatefulWidget {
  const MyTransactionsScreen({super.key});

  @override
  State<MyTransactionsScreen> createState() => _MyTransactionsScreenState();
}

class _MyTransactionsScreenState extends State<MyTransactionsScreen> {
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyDetails();
  }

  Future<void> _fetchMyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('customerAuthToken');
    const url = 'hisabkhata.railway.internal/api/auth/customer/me';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _customerData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if(mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_customerData == null) {
      return const Scaffold(body: Center(child: Text('Could not load your data. Please try again.')));
    }

    final transactions = List.from(_customerData!['transactions'] ?? []).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('${_customerData!['name']}\'s Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Text('Your Current Balance:', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 5),
                      Text(
                        '৳ ${(_customerData!['balance'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: (_customerData!['balance'] as num) > 0 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('You have no transactions yet.'))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isDue = tx['type'] == 'due';
                        final formattedDate = DateFormat('dd MMM, yyyy - hh:mm a').format(DateTime.parse(tx['date']));
                        return Card(
                          color: isDue ? Colors.red.shade50 : Colors.green.shade50,
                          child: ListTile(
                            title: Text(isDue ? 'Purchase (Due)' : 'Payment'),
                            subtitle: Text(formattedDate),
                            trailing: Text(
                              '৳ ${tx['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDue ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
