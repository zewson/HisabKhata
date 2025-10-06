import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summaryData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    const url = 'https://alpina.titaniahub.net/api/dashboard/summary';

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
          _summaryData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if(mounted) {
        // Handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) {
        // Handle error
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              '৳ ${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchSummary,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSummaryCard(
                  'Total Due Amount',
                  (_summaryData?['totalDue'] as num? ?? 0.0).toDouble(),
                  Colors.red.shade700,
                ),
                // You can add more summary cards here in the future
              ],
            ),
          );
  }
}
