import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alpina/screens/add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<dynamic> _allCustomers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _searchController.addListener(_filterCustomers);
  }

  Future<void> _fetchCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    // IMPORTANT: Replace with your live server URL
    const url = 'https://alpina.titaniahub.net/api/customers';

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
          _allCustomers = jsonDecode(response.body);
          _filteredCustomers = _allCustomers;
          _isLoading = false;
        });
      } else if (mounted) {
        _handleError('Failed to load customers');
      }
    } catch (e) {
      if (mounted) {
        _handleError('An error occurred: $e');
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((customer) {
        final name = customer['name'].toString().toLowerCase();
        final phone = customer['phone'].toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  void _handleError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchCustomers,
                    child: _filteredCustomers.isEmpty
                        ? const Center(child: Text('No customers found.'))
                        : ListView.builder(
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerDetailScreen(customer: customer),
                                      ),
                                    ).then((_) => _fetchCustomers());
                                  },
                                  leading: CircleAvatar(
                                    child: Text(customer['name'][0].toUpperCase()),
                                  ),
                                  title: Text(customer['name']),
                                  subtitle: Text(customer['phone']),
                                  trailing: Text(
                                    '৳ ${(customer['balance'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: (customer['balance'] as num) > 0 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          ).then((_) => _fetchCustomers());
        },
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
    );
  }
}



