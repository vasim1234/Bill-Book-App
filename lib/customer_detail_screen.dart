import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note / Wajah", border: OutlineInputBorder())),
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
                _loadTransactions(); 
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // VIP EDIT ENTRY POPUP (Aapke reference jaisa)
  // ==========================================
  void _editOrDeleteTransaction(Map<String, dynamic> transaction) {
    final amountController = TextEditingController(text: transaction['amount'].toString());
    final noteController = TextEditingController(text: transaction['note'] ?? '');
    String selectedType = transaction['type'];
    int transId = transaction['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Delete Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text("✏️ ", style: TextStyle(fontSize: 18)),
                        Text("Edit Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        // Delete Transaction from Database
                        await DatabaseHelper().deleteTransaction(transId);
                        Navigator.pop(context);
                        _loadTransactions();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted successfully!')));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Diya / Liye Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = "DIYA"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == "DIYA" ? Colors.red : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "DIYA (GAVE)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedType == "DIYA" ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = "LIYA"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == "LIYA" ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "LIYA (GOT)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedType == "LIYA" ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Field
                const Text("AMOUNT (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),

                // Note / Wajah Field
                const Text("NOTE / WAJAH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 25),

                // Cancel & Update Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (amountController.text.isNotEmpty) {
                            // Database update function call
                            await DatabaseHelper().updateTransaction({
                              'id': transId,
                              'customerId': widget.customerId,
                              'amount': double.parse(amountController.text),
                              'type': selectedType,
                              'note': noteController.text.isEmpty ? "Cash Transaction" : noteController.text,
                              'date': transaction['date'], // Date same rakhi hai
                            });
                            Navigator.pop(context);
                            _loadTransactions(); // Refresh list & balance
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry updated successfully!')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("UPDATE ENTRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendReminder() {
    if (_currentMobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number nahi hai!')));
      return;
    }
    String message = "Namaste $_currentName, aapka hisaab ₹${_balance.abs()} ${_balance > 0 ? 'lena' : 'dena'} baaki hai. Kripya jald payment karein. - My Dukan";
    String url = "https://wa.me/$_currentMobile?text=${Uri.encodeComponent(message)}";
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openStatementReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerStatementScreen(
          customerName: _currentName,
          customerMobile: _currentMobile,
          balance: _balance,
          transactions: _transactions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _balance > 0 ? Colors.red : (_balance < 0 ? Colors.green : Colors.grey);
    
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
          // --- VIP STYLISH BALANCE CARD ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _balance > 0 ? "AAPKO LENE HAIN" : (_balance < 0 ? "AAPKO DENE HAIN" : "HISAAB CLEAR"),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "₹ ${_balance.abs().toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),

          // --- REPORT & REMINDER BUTTONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openStatementReport,
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text("VIEW REPORT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendReminder,
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text("REMINDER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),

          // --- TRANSACTIONS LIST ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      
                      return InkWell(
                        onTap: () => _editOrDeleteTransaction(t),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['date'].toString().substring(0, 16), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(t['note'] ?? "Cash", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      isDiya ? "₹ ${t['amount']}" : "",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      !isDiya ? "₹ ${t['amount']}" : "",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
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

// ========================================================
// BANK STATEMENT PDF REPORT SCREEN
// ========================================================
class CustomerStatementScreen extends StatelessWidget {
  final String customerName;
  final String customerMobile;
  final double balance;
  final List<Map<String, dynamic>> transactions;

  const CustomerStatementScreen({
    super.key,
    required this.customerName,
    required this.customerMobile,
    required this.balance,
    required this.transactions,
  });

  Future<void> _generateAndSharePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("STATEMENT OF ACCOUNT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("My Dukan - Business Khata", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Customer Name: $customerName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text("Phone: $customerMobile", style: const TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Net Balance: ₹${balance.abs().toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: balance > 0 ? PdfColors.red : PdfColors.green)),
                    pw.SizedBox(height: 4),
                    pw.Text(balance > 0 ? "Aapko lene hain" : (balance < 0 ? "Aapko dene hain" : "Clear"), style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Date & Time', 'Note / Wajah', 'Diye (₹)', 'Liye (₹)'],
              data: transactions.map((t) {
                bool isDiya = t['type'] == 'DIYA';
                return [
                  t['date'].toString().substring(0, 16),
                  t['note'] ?? 'Cash',
                  isDiya ? "₹${t['amount']}" : "-",
                  !isDiya ? "₹${t['amount']}" : "-",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text("Generated via My Dukan App", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'statement_$customerName.pdf');
  }

  @byte
  @override
  Widget build(BuildContext context) {
    Color statusColor = balance > 0 ? Colors.red : (balance < 0 ? Colors.green : Colors.grey);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Statement"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _generateAndSharePdf(context),
            tooltip: "Share PDF Statement",
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text("STATEMENT OF ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text("My Dukan - Business Khata", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Customer Name:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text("Phone: $customerMobile", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Net Balance:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text("₹${balance.abs().toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  color: Colors.grey[200],
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text("DATE / NOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("DIYE (₹)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red))),
                      Expanded(flex: 2, child: Text("LIYE (₹)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                    ],
                  ),
                ),
                ...transactions.map((t) {
                  bool isDiya = t['type'] == 'DIYA';
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['note'] ?? "Cash", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(t['date'].toString().substring(0, 16), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            isDiya ? "₹${t['amount']}" : "-",
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            !isDiya ? "₹${t['amount']}" : "-",
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateAndSharePdf(context),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text("Share PDF Statement on WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
