import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Reminder ke liye
import 'database_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerMobile;

  const CustomerDetailScreen({
    super.key, 
    required this.customerId, 
    required this.customerName, 
    required this.customerMobile
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0.0;
  late String _currentName;
  late String _currentMobile;

  @override
  void initState() {
    super.initState();
    _currentName = widget.customerName;
    _currentMobile = widget.customerMobile;
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

  // Name/Number Edit karne ka popup
  void _editCustomer() {
    final nameController = TextEditingController(text: _currentName);
    final mobileController = TextEditingController(text: _currentMobile);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper().updateCustomer(widget.customerId, nameController.text, mobileController.text);
                setState(() {
                  _currentName = nameController.text;
                  _currentMobile = mobileController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // Paisa Add karne ka popup (Diye / Liye)
  void _addTransaction(String type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == "DIYA" ? "Aapne Diye ₹" : "Aapne Liye ₹"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note (Optional)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: type == "DIYA" ? Colors.red : Colors.green),
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                await DatabaseHelper().insertTransaction({
                  'customerId': widget.customerId,
                  'amount': double.parse(amountController.text),
                  'type': type,
                  'note': noteController.text.isEmpty ? "Cash Transaction" : noteController.text,
                  'date': DateTime.now().toString(),
                });
                Navigator.pop(context);
                _loadTransactions(); // Refresh list
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // WhatsApp Reminder bhejna
  void _sendReminder() {
    if (_currentMobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number nahi hai!')));
      return;
    }
    String message = "Namaste $_currentName, aapka hisaab ₹${_balance.abs()} ${_balance > 0 ? 'lena' : 'dena'} baaki hai. Kripya jald payment karein. - My Dukan";
    String url = "https://wa.me/${_currentMobile}?text=${Uri.encodeComponent(message)}";
    
    // In-app browser / whatsapp kholne ke liye
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.white24, child: Text(_currentName[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_currentMobile, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            // Edit Button
            TextButton.icon(
              onPressed: _editCustomer,
              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
              label: const Text("Edit", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.white24),
            )
          ],
        ),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Balance Header
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  color: Colors.indigo[50],
  child: Column(
    children: [
      // Agar balance > 0 (Lena hai) toh RED, warna GREEN
      Text(
        _balance > 0 
            ? "AAPKO LENE HAIN" 
            : (_balance < 0 ? "AAPKO DENE HAIN" : "HISAAB CLEAR"),
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: _balance > 0 ? Colors.red : (_balance < 0 ? Colors.green : Colors.grey)
        ),
      ),
      Text(
        "₹ ${_balance.abs().toStringAsFixed(2)}",
        style: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: _balance > 0 ? Colors.red : (_balance < 0 ? Colors.green : Colors.grey)
        ),
      ),
    ],
  ),
),

          // --- REPORT & REMINDER BUTTONS ---
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Report ka logic (abhi ke liye popup)
                    showDialog(context: context, builder: (c) => AlertDialog(
                      title: const Text("Report"),
                      content: Text("Total Transactions: ${_transactions.length}\nCurrent Balance: ₹${_balance.abs()}"),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
                    ));
                  },
                  icon: const Icon(Icons.description),
                  label: const Text("REPORT"),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              Expanded(
                child: TextButton.icon(
                  onPressed: _sendReminder,
                  icon: const Icon(Icons.message, color: Colors.green),
                  label: const Text("REMINDER", style: TextStyle(color: Colors.green)),
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // --- TRANSACTIONS LIST (Table format) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("ENTRIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("AAPNE DIYE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))),
                Expanded(flex: 1, child: Text("AAPNE LIYE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
              ],
            ),
          ),
          
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("Koi entry nahi hai."))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      bool isDiya = t['type'] == 'DIYA'; 
                      
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Entry Date & Note
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t['date'].toString().substring(0, 16), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(t['note'] ?? "Cash", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                // Amount Diya (Red)
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    isDiya ? "₹ ${t['amount']}" : "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                  ),
                                ),
                                // Amount Liya (Green)
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    !isDiya ? "₹ ${t['amount']}" : "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      
      // --- NEEYCHE WALE BADE BUTTONS ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addTransaction("DIYA"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("AAPNE DIYE ₹", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addTransaction("LIYA"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("AAPNE LIYE ₹", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
