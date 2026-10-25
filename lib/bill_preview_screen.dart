import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR ke liye
import 'package:url_launcher/url_launcher.dart'; // WhatsApp ke liye
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

  // WhatsApp par bill bhejne ka function
  void _sendWhatsAppBill() async {
    String mobile = _billData!['customerMobile'] ?? "";
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer ka mobile number nahi hai!')));
      return;
    }

    // Number format theek karo (91 add karo agar nahi hai)
    if (!mobile.startsWith('91')) mobile = '91$mobile';

    String businessName = _settings?['businessName'] ?? "My Dukan";
    String total = _billData!['totalAmount'].toString();
    String date = _billData!['date'];

    // WhatsApp message text
    String text = "Namaste ${_billData!['customerName']},\n\n"
        "Aapka bill details:\n"
        "Business: $businessName\n"
        "Date: $date\n"
        "Total Amount: ₹$total\n\n"
        "Thank you for shopping with us!";

    String url = "https://wa.me/$mobile?text=${Uri.encodeComponent(text)}";
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
            if (theme == "Modern Boxed") _buildModernBoxed(),
            if (theme == "Classic Minimal") _buildClassicMinimal(),
            if (theme == "Dark Header") _buildDarkHeader(),

            const SizedBox(height: 20),

            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thermal Printer connected soon!'))); },
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
                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF feature coming soon!'))); },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Save PDF"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], foregroundColor: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendWhatsAppBill, // WhatsApp logic call kiya
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
  // 1. MODERN BOXED THEME
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
            _buildQrAndFooter(businessName),
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
            _buildQrAndFooter(businessName),
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
                _buildQrAndFooter(businessName),
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

  // QR Code aur Footer
  Widget _buildQrAndFooter(String businessName) {
    String upiId = _settings?['upiId'] ?? "";
    String totalAmount = _billData!['totalAmount'].toString();
    
    // UPI Link format: upi://pay?pa=upi_id&pn=Business_Name&am=Amount&cu=INR
    String upiLink = "upi://pay?pa=$upiId&pn=$businessName&am=$totalAmount&cu=INR";

    return Center(
      child: Column(
        children: [
          if (upiId.isNotEmpty) ...[
            const Text("SCAN TO PAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 5),
            // QR Code Widget
            QrImageView(
              data: upiLink,
              version: QrVersions.auto,
              size: 120.0,
            ),
            Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 10),
          ],
          Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
