import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _sendWhatsAppBill() async {
    String mobile = _billData!['customerMobile'] ?? "";
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer ka mobile number nahi hai!')));
      return;
    }
    if (!mobile.startsWith('91')) mobile = '91$mobile';
    
    String businessName = _settings?['businessName'] ?? "My Dukan";
    String total = _billData!['totalAmount'].toString();
    
    String text = "Namaste ${_billData!['customerName']},\n\nAapka bill details:\nBusiness: $businessName\nTotal Amount: ₹$total\n\nThank you!";
    String url = "https://wa.me/$mobile?text=${Uri.encodeComponent(text)}";
    
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
Widget build(BuildContext context) {
  if (_billData == null) {
    return const Center(child: CircularProgressIndicator());
  }

  String theme = _settings?['theme'] ?? "Modern Boxed"; 

  // Yahan se apna Scaffold aur AppBar hata diya hai
  return Container(
    color: Colors.grey[200],
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      // ... baaki code waisa hi rahega
        child: Column(
          children: [
            // Theme ke hisaab se bill design render karo
            if (theme == "Modern Boxed") _buildModernBoxed(),
            if (theme == "Classic Minimal") _buildClassicMinimal(),
            if (theme == "Dark Header") _buildDarkHeader(),

            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thermal Printer feature coming next!'))); },
                icon: const Icon(Icons.print),
                label: const Text("Thermal Printer / Bluetooth Print", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    onPressed: _sendWhatsAppBill,
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
                onPressed: () { 
                  Navigator.pop(context); // Wapas main screen par jao
                },
                child: const Text("New Sale", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
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
    String ownerName = _settings?['ownerName'] ?? "Owner";
    String address = _settings?['address'] ?? "";
    String upiId = _settings?['upiId'] ?? "";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 2),
                    const Text("PREMIUM QUALITY", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("INVOICE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text("#INV-${_billData!['id']}", style: const TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            Container(height: 2, color: Colors.indigo),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CUSTOMER DETAILS", style: TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Ph: ${_billData!['customerMobile']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("BILLED BY", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Date: ${_billData!['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              color: Colors.indigo[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: const Row(
                children: [
                  Expanded(flex: 4, child: Text("ITEM DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo))),
                  Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo))),
                  Expanded(flex: 2, child: Text("RATE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo))),
                  Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo))),
                ],
              ),
            ),
            ..._billItems.map((item) {
              double amount = item['price'] * item['quantity'];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("₹${item['price']}", textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("TOTAL AMOUNT", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.indigo)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQrAndFooter(businessName, upiId),
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
    String address = _settings?['address'] ?? "";
    String upiId = _settings?['upiId'] ?? "";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 24, letterSpacing: 3, fontWeight: FontWeight.w300)),
                  const Text("PREMIUM SHOWROOM", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2)),
                  const SizedBox(height: 5),
                  Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("BILL TO:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_billData!['customerMobile'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("DATE:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(_billData!['date']),
                    Text("INV: #${_billData!['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(flex: 4, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text("PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            const Divider(),
            ..._billItems.map((item) {
              double amount = item['price'] * item['quantity'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(item['itemName'])),
                    Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("₹${item['price']}", textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("TOTAL: ₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            _buildQrAndFooter(businessName, upiId),
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
    String address = _settings?['address'] ?? "";
    String upiId = _settings?['upiId'] ?? "";

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            color: const Color(0xFF1E293B), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(address, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("INVOICE", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BILL TO", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_billData!['customerMobile'], style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("DATE", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(_billData!['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                ..._billItems.map((item) {
                  double amount = item['price'] * item['quantity'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(item['itemName'])),
                        Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildQrAndFooter(businessName, upiId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMMON FOOTER & QR
  // ==========================================
  Widget _buildQrAndFooter(String businessName, String upiId) {
    String totalAmount = _billData!['totalAmount'].toString();
    String upiLink = "upi://pay?pa=$upiId&pn=$businessName&am=$totalAmount&cu=INR";

    return Center(
      child: Column(
        children: [
          if (upiId.isNotEmpty) ...[
            const Text("SCAN TO PAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 5),
            QrImageView(
              data: upiLink,
              version: QrVersions.auto,
              size: 100.0,
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
