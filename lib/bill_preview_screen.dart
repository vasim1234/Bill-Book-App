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
    var settings = await DatabaseHelper().getSettings();

    if (settings == null) {
      await DatabaseHelper().saveSettings({'businessName': 'HUR GARMENTS', 'theme': 'Modern Boxed'});
      settings = await DatabaseHelper().getSettings();
    }

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
    
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String total = _billData!['totalAmount'].toString();
    
    String text = "Namaste ${_billData!['customerName']},\n\nAapka bill details:\nBusiness: $businessName\nTotal Amount: ₹$total\n\nThank you!";
    String url = "https://wa.me/$mobile?text=${Uri.encodeComponent(text)}";
    
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showThemePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Bill Theme Change Karein"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              "Mobile (Thermal)",
              "Modern Boxed",
              "Classic Minimal",
              "Dark Header"
            ].map((themeName) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(themeName, style: const TextStyle(fontWeight: FontWeight.w500)),
                leading: Radio<String>(
                  value: themeName,
                  groupValue: _settings?['theme'] ?? "Modern Boxed",
                  onChanged: (value) async {
                    await DatabaseHelper().updateTheme(value!);
                    setState(() {
                      _settings?['theme'] = value;
                    });
                    Navigator.pop(dialogContext); 
                  },
                ),
                onTap: () async {
                  await DatabaseHelper().updateTheme(themeName);
                  setState(() {
                    _settings?['theme'] = themeName;
                  });
                  Navigator.pop(dialogContext); 
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_billData == null || _settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Bill Preview")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String theme = _settings?['theme'] ?? "Modern Boxed"; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Preview"),
        backgroundColor: Colors.indigo[900],
        actions: [
          TextButton.icon(
            onPressed: () {
              _showThemePickerDialog(context);
            },
            icon: const Icon(Icons.palette, color: Colors.white),
            label: const Text("Theme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (theme == "Mobile (Thermal)") _buildThermalReceipt(),
              if (theme == "Modern Boxed") _buildVipModernBoxed(), // Yehi naya VIP Design hai!
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
                    Navigator.pop(context); 
                  },
                  child: const Text("New Sale", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIP MODERN BOXED THEME (Aapke photo jaisa exact look)
  // ==========================================
  Widget _buildVipModernBoxed() {
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String ownerName = _settings?['ownerName'] ?? "Mansuri Vasimraj";
    String address = _settings?['address'] ?? "Bodeli";
    String mobile = _settings?['mobile'] ?? "9904178658";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";
    String businessType = _settings?['businessType'] ?? "WHOLESALER";
    String paymentStatus = _billData!['paymentStatus'] ?? "UNPAID";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP BLUE HEADER
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Rich Dark Blue
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("H", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Text(businessType.toUpperCase(), style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("INVOICE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text("#HUR-${_billData!['id']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

                    // Sub-header info (Date & Status Badge Fixed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("Est. 2021 • Premium Quality", style: TextStyle(fontSize: 9, color: Colors.grey)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Date: ${_billData!['date']} | ", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    const Text("Status: ", style: TextStyle(fontSize: 9, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentStatus == "PAID" ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(paymentStatus, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. CUSTOMER & BILLED BY DETAILS BOX
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 4),
                            Text("CUSTOMER DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("Customer Name:\n${_billData!['customerName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Phone: ${_billData!['customerMobile'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Billed By:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("Store Address:\n$address", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text("Ph: $mobile", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BILL ITEMS TABLE BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFE0E7FF),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: const Row(
                      children: [
                        Expanded(flex: 4, child: Text("ITEM DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                        Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                        Expanded(flex: 2, child: Text("UNIT PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                        Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                      ],
                    ),
                  ),
                  ..._billItems.map((item) {
                    double amount = item['price'] * item['quantity'];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                const Text("SKU: ITM-0791", style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text("₹${item['price']}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 4. QR & TOTAL SECTION
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code
                if (upiId.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SCAN & PAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      QrImageView(
                        data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR",
                        version: QrVersions.auto,
                        size: 70.0,
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                ],
                
                // Totals
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Subtotal: ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Tax (0%): ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("₹0.00", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text("₹${_billData!['totalAmount']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. FOOTER
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[150],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text("For returns or questions, contact us within 7 days. • Bodeli", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dummy methods for other themes if selected
  Widget _buildThermalReceipt() => Container(padding: const EdgeInsets.all(16), color: Colors.white, child: const Text("Thermal Receipt"));
  Widget _buildClassicMinimal() => Container(padding: const EdgeInsets.all(16), color: Colors.white, child: const Text("Classic Minimal"));
  Widget _buildDarkHeader() => Container(padding: const EdgeInsets.all(16), color: Colors.white, child: const Text("Dark Header"));
}
