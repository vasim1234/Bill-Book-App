import 'package:flutter/material.dart';
import 'database_helper.dart';

class BillPreviewScreen extends StatefulWidget {
  final int billId;
  const BillPreviewScreen({super.key, required this.billId});

  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> {
  Map<String, dynamic>? _billData;
  List<Map<String, dynamic>> _billItems = [];
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Database se data fetch karo
    final bills = await DatabaseHelper().getAllBills();
    final bill = bills.firstWhere((element) => element['id'] == widget.billId);
    final items = await DatabaseHelper().getBillItems(widget.billId);
    final settings = await DatabaseHelper().getSettings();

    setState(() {
      _billData = bill;
      _billItems = items;
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_billData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String businessName = _settings?['businessName'] ?? "MY BUSINESS";
    String ownerName = _settings?['ownerName'] ?? "Owner";
    String mobile = _settings?['mobile'] ?? "";
    String address = _settings?['address'] ?? "";
    String upiId = _settings?['upiId'] ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Bill Preview"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- INVOICE DESIGN ---
            Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Business Name & Invoice No)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const Text("Premium Quality", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("INVOICE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("#INV-${_billData!['id']}", style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                    const Divider(thickness: 2, color: Colors.indigo),
                    const SizedBox(height: 10),

                    // Customer Details & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("BILL TO:", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Mo: ${_billData!['customerMobile']}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("DATE:", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(_billData!['date']),
                            Text("Status: ${_billData!['paymentStatus']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Table Header
                    Container(
                      color: Colors.indigo[50],
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text("PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Table Items
                    ..._billItems.map((item) {
                      double amount = item['price'] * item['quantity'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(item['itemName'])),
                            Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text("₹${item['price']}", textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }),

                    const Divider(),
                    
                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("GRAND TOTAL: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Footer (UPI & Thank You)
                    Center(
                      child: Column(
                        children: [
                          if (upiId.isNotEmpty)
                            Text("Scan to Pay: $upiId", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bluetooth Print feature coming next!'))); },
                icon: const Icon(Icons.print),
                label: const Text("Thermal Printer / Bluetooth Print"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF feature coming next!'))); },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Save PDF"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], foregroundColor: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp feature coming next!'))); },
                    icon: const Icon(Icons.message),
                    label: const Text("WhatsApp Bill"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () { Navigator.pop(context); },
                child: const Text("New Sale", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
