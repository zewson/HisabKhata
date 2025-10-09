import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Map<String, dynamic> _currentCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
  }

  // Performs the API call, updates _currentCustomer on success and shows a snackbar.
  // Returns null on success, or a Map<String,String> of field-specific errors (use key '_general' for non-field error).
  Future<Map<String, String>?> _makeApiRequest(Future<http.Response> apiCall, String successMessage) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await apiCall;
      if (response.statusCode == 200 && mounted) {
        setState(() => _currentCustomer = jsonDecode(response.body));
        messenger.showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        return null;
      } else if (mounted) {
        // Try to parse structured errors from server
        Map<String, String> errors = {};
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            if (body['errors'] is Map) {
              (body['errors'] as Map).forEach((k, v) {
                if (v is List && v.isNotEmpty) {
                  errors[k.toString()] = v.first.toString();
                } else if (v != null) {
                  errors[k.toString()] = v.toString();
                }
              });
            }
            if (errors.isEmpty && body['message'] != null) {
              errors['_general'] = body['message'].toString();
            }
          }
        } catch (_) {
          // ignore parse errors
        }
        if (errors.isEmpty) errors['_general'] = 'Operation failed (${response.statusCode})';
        messenger.showSnackBar(
          SnackBar(content: Text(errors['_general'] ?? 'Operation failed'), backgroundColor: Colors.red),
        );
        return errors;
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
      return {'_general': 'An error occurred: $e'};
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return {'_general': 'Unknown error'};
  }

  // Returns null on success, or a map of field errors on failure.
  Future<Map<String, String>?> _addTransaction(double amount, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = 'https://hisabkhata-production.up.railway.app/api/customers/${_currentCustomer['_id']}/transactions';

    final apiCall = http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'x-auth-token': token ?? ''},
      body: jsonEncode({'amount': amount, 'type': type}),
    );

    return await _makeApiRequest(apiCall, 'Transaction added successfully');
  }

  // Returns null on success, or a map of field errors on failure.
  Future<Map<String, String>?> _editTransaction(String transactionId, double amount, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = 'https://hisabkhata-production.up.railway.app/api/customers/${_currentCustomer['_id']}/transactions/$transactionId';

    final apiCall = http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'x-auth-token': token ?? ''},
      body: jsonEncode({'amount': amount, 'type': type}),
    );

    return await _makeApiRequest(apiCall, 'Transaction updated successfully');
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = 'https://hisabkhata-production.up.railway.app/api/customers/${_currentCustomer['_id']}/transactions/$transactionId';

    final apiCall = http.delete(Uri.parse(url), headers: {'x-auth-token': token ?? ''});
    await _makeApiRequest(apiCall, 'Transaction deleted successfully');
  }

  void _showTransactionDialog({Map<String, dynamic>? transaction}) {
    final isEditing = transaction != null;
    final amountController = TextEditingController(text: isEditing ? transaction['amount'].toString() : '');
    String transactionType = isEditing ? transaction['type'] : 'due';

  final String? existingTransactionId = isEditing ? transaction['_id'] as String? : null;
    bool dialogSaving = false;
    Map<String, String>? dialogErrors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amount', errorText: dialogErrors == null ? null : dialogErrors!['amount']),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter an amount' : null,
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: transactionType,
                      items: const [
                        DropdownMenuItem(value: 'due', child: Text('Due')),
                        DropdownMenuItem(value: 'payment', child: Text('Payment')),
                      ],
                      onChanged: (value) => setState(() => transactionType = value ?? 'due'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
                if (dialogSaving) const Padding(
                  padding: EdgeInsets.only(top:12.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                if (dialogErrors != null && dialogErrors!['_general'] != null) Padding(
                  padding: const EdgeInsets.only(top:12.0),
                  child: Text(dialogErrors!['_general']!, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: dialogSaving ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: dialogSaving
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount != null && amount > 0) {
                          setState(() => dialogSaving = true);
                          final navigator = Navigator.of(ctx);
                          Map<String, String>? result;
                          if (isEditing && existingTransactionId != null) {
                            result = await _editTransaction(existingTransactionId, amount, transactionType);
                          } else {
                            result = await _addTransaction(amount, transactionType);
                          }
                          setState(() => dialogSaving = false);
                          if (result == null) {
                            navigator.pop();
                          } else {
                            setState(() => dialogErrors = result);
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(String transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(child: const Text('No'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteTransaction(transactionId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = List.from(_currentCustomer['transactions'] ?? []).reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(_currentCustomer['name'])),
      body: Stack(
        children: [
          Padding(
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
                          const Text('Current Balance:', style: TextStyle(fontSize: 20, color: Colors.black54)),
                          const SizedBox(height: 5),
                          Text(
                            '৳ ${(_currentCustomer['balance'] as num).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: (_currentCustomer['balance'] as num) > 0 ? Colors.red.shade700 : Colors.green.shade700,
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
                      ? const Center(child: Text('No transactions found.'))
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isDue = tx['type'] == 'due';
                            final formattedDate = DateFormat('dd MMM, yyyy - hh:mm a').format(DateTime.parse(tx['date']));

                            return Card(
                              child: ListTile(
                                leading: Icon(isDue ? Icons.arrow_upward : Icons.arrow_downward, color: isDue ? Colors.red : Colors.green),
                                title: Text(isDue ? 'Due' : 'Payment'),
                                subtitle: Text(formattedDate),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('৳ ${tx['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showTransactionDialog(transaction: tx);
                                        } else if (value == 'delete') {
                                          _showDeleteConfirmationDialog(tx['_id']);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color(0x80000000),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionDialog(),
        tooltip: 'New Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
