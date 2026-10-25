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

    String theme = _settings?['theme'] ?? "Modern Boxed";

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
            // Theme ke hisaab se bill design render karo
            if (theme == "Modern Boxed") _buildModernBoxed(),
            if (theme == "Classic Minimal") _buildClassicMinimal(),
            if (theme == "Dark Header") _buildDarkHeader(),

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

  // ==========================================
  // 1. MODERN BOXED THEME (Blue Header)
  // ==========================================
  Widget _buildModernBoxed() {
    String businessName = _settings?['businessName'] ?? "MY BUSINESS";
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Text("Wholesaler", style: TextStyle(fontSize: 10, color: Colors.grey)),
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
            _buildCustomerDetails(),
            const SizedBox(height: 20),
            _buildItemTable(),
            const Divider(),
            _buildGrandTotal(),
            const SizedBox(height: 20),
            _buildFooter(businessName),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. CLASSIC MINIMAL THEME
  // ==========================================
  Widget _buildClassicMinimal() {
    String businessName = _settings?['businessName'] ?? "MY BUSINESS";
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(businessName, style: const TextStyle(fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w300)),
            const Text("PREMIUM SHOWROOM", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildCustomerDetails(),
            const SizedBox(height: 20),
            _buildItemTable(),
            const SizedBox(height: 20),
            _buildGrandTotal(),
            const SizedBox(height: 20),
            const Divider(),
            _buildFooter(businessName),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. DARK HEADER THEME
  // ==========================================
  Widget _buildDarkHeader() {
    String businessName = _settings?['businessName'] ?? "MY BUSINESS";
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Dark Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("INVOICE", style: TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
          // Body
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerDetails(),
                const SizedBox(height: 20),
                _buildItemTable(),
                const Divider(),
                _buildGrandTotal(),
                const SizedBox(height: 20),
                _buildFooter(businessName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMMON WIDGETS
  // ==========================================
  Widget _buildCustomerDetails() {
    return Row(
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
    );
  }

  Widget _buildItemTable() {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
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
      ],
    );
  }

  Widget _buildGrandTotal() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("GRAND TOTAL: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo)),
        ],
      ),
    );
  }

  Widget _buildFooter(String businessName) {
    String upiId = _settings?['upiId'] ?? "";
    return Center(
      child: Column(
        children: [
          if (upiId.isNotEmpty)
            Text("Scan to Pay: $upiId", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
