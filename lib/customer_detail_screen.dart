import 'package:flutter/material.dart';
import 'database_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerMobile;

  const CustomerDetailScreen({super.key, required this.customerId, required this.customerName, required this.customerMobile});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    final trans = await DatabaseHelper().getCustomerTransactions(widget.customerId);
    final bal = await DatabaseHelper().getCustomerBalance(widget.customerId);
    
    setState(() {
      _transactions = trans;
      _balance = bal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.customerMobile, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Balance Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.indigo[50],
            child: Column(
              children: [
                Text(
                  _balance > 0 ? "AAPKO LENE HAIN" : (_balance < 0 ? "AAPKO DENE HAIN" : "HISAAB CLEAR"),
                  style: TextStyle(fontWeight: FontWeight.bold, color: _balance > 0 ? Colors.red : Colors.green),
                ),
                Text(
                  "₹ ${_balance.abs().toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _balance > 0 ? Colors.red : Colors.green),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("Koi entry nahi hai."))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      bool isDiya = t['type'] == 'DIYA'; // Humne diya
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          title: Text(t['note'] ?? "Cash Transaction"),
                          subtitle: Text(t['date'].toString().substring(0, 16)),
                          trailing: Text(
                            "₹ ${t['amount']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18,
                              color: isDiya ? Colors.red : Colors.green
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
