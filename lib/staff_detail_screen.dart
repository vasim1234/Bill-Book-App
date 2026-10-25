import 'package:flutter/material.dart';
import 'database_helper.dart';

class StaffDetailScreen extends StatefulWidget {
  final Map<String, dynamic> staff;
  const StaffDetailScreen({super.key, required this.staff});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _attendance = [];
  
  double _totalPaid = 0.0;
  double _totalEarned = 0.0;
  int _presentDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // 1. Payments nikaalo
    final payments = await DatabaseHelper().getStaffPayments(widget.staff['id']);
    double totalPaid = 0;
    for (var p in payments) {
      totalPaid += (p['amount'] as num).toDouble();
    }

    // 2. Attendance (Haazri) nikaalo
    // Filhal hum saari attendance nikaal rahe hain, aage filter laga sakte hain
    final attendance = await DatabaseHelper().getTodayAttendance(""); 
    // NOTE: getTodayAttendance mein date filter hai, isliye better hai direct query karein
    // Par abhi ke liye hum database_helper se direct nikal lete hain

    final summary = await DatabaseHelper().getStaffAttendanceSummary(widget.staff['id']);

    setState(() {
      _payments = payments;
      _totalPaid = totalPaid;
      _totalEarned = summary['totalEarned'];
      _presentDays = summary['presentDays'];
      // _attendance = attendance; // Agar aage history chahiye toh use karenge
    });
  }

  void _payStaff() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pagar / Advance Dein"),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900]),
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                await DatabaseHelper().insertStaffPayment({
                  'staffId': widget.staff['id'],
                  'amount': double.parse(amountController.text),
                  'note': noteController.text.isEmpty ? "Pagar / Advance Diya" : noteController.text,
                  'date': DateTime.now().toString().substring(0, 10),
                });
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text("DEIN", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteStaff() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Staff?"),
        content: Text("Kya aap ${widget.staff['name']} ko delete karna chahte hain?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper().deleteStaff(widget.staff['id']);
              Navigator.pop(context); // Dialog band
              Navigator.pop(context); // Detail screen band karke list par wapas
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double dailyWage = (widget.staff['dailyWage'] as num).toDouble();
    double balance = _totalEarned - _totalPaid;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.staff['name'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("MO: ${widget.staff['mobile']} • ROZ: ₹$dailyWage", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pagar Bani (Kamai)
                _buildSummaryCol(
                  "PAGAR BANI", 
                  "₹${_totalEarned.toStringAsFixed(0)}", 
                  Colors.black
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                
                // Paise Diye
                _buildSummaryCol(
                  "PAISE DIYE", 
                  "₹${_totalPaid.toStringAsFixed(0)}", 
                  Colors.green
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                
                // Status (Baki ya Clear)
                _buildSummaryCol(
                  "STATUS", 
                  balance > 0 
                      ? "Baki: ₹${balance.toStringAsFixed(0)}" 
                      : (balance < 0 ? "Advance" : "Clear"), 
                  balance > 0 ? Colors.red : Colors.blue
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Advance / Pagar Dein Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ADVANCE / PAGAR DEIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _payStaff,
                        icon: const Icon(Icons.add),
                        label: const Text("PAY NOW"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[50], foregroundColor: Colors.indigo),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // Payment History
          Expanded(
            child: _payments.isEmpty
                ? const Center(child: Text("Koi hisaab nahi mila."))
                : ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.money, color: Colors.white)),
                        title: Text(p['note'].toString().isEmpty ? "Pagar Diya" : p['note']),
                        subtitle: Text(p['date']),
                        trailing: Text("- ₹${p['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                      );
                    },
                  ),
          ),

          // Bottom Buttons (PDF, WhatsApp, Delete)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF feature coming soon!'))); },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("PDF SAVE"),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp feature coming soon!'))); },
                        icon: const Icon(Icons.message),
                        label: const Text("WHATSAPP"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _deleteStaff,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("IS STAFF KO DELETE KAREIN", style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
