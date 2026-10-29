import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  // --- VIP PDF Document Generator (Jo Screen jaisa hi bill print/share karega) ---
   Future<pw.Document> _generatePdfDocument() async {
    final pdf = pw.Document();
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String ownerName = _settings?['ownerName'] ?? "Mansuri Vasimraj";
    String address = _settings?['address'] ?? "Bodeli";
    String mobile = _settings?['mobile'] ?? "9904178658";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";
    String businessType = _settings?['businessType'] ?? "WHOLESALER";
    String paymentStatus = _billData!['paymentStatus'] ?? "UNPAID";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(businessName.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(businessType.toUpperCase(), style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("INVOICE", style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text("#HUR-${_billData!['id']}", style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Est. 2021 • Premium Quality", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Row(
                      children: [
                        pw.Text("Date: ${_billData!['date']}  |  Status: ", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(paymentStatus, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: paymentStatus == "PAID" ? PdfColors.green : PdfColors.red)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 15),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("CUSTOMER DETAILS", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            pw.SizedBox(height: 4),
                            pw.Text("Name: ${_billData!['customerName']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                            pw.Text("Phone: ${_billData!['customerMobile'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("BILLED BY", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            pw.SizedBox(height: 4),
                            pw.Text(ownerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                            pw.Text("Address: $address (Ph: $mobile)", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Table.fromTextArray(
                  headers: ['ITEM DESCRIPTION', 'QTY', 'UNIT PRICE', 'AMOUNT'],
                  data: _billItems.map((item) {
                    double amount = item['price'] * item['quantity'];
                    return [
                      item['itemName'],
                      item['quantity'].toString(),
                      "₹${item['price']}",
                      "₹${amount.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (upiId.isNotEmpty)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("SCAN & PAY VIA UPI", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR",
                            width: 65,
                            height: 65,
                          ),
                          pw.Text(upiId, style: const pw.TextStyle(fontSize: 7)),
                        ],
                      )
                    else
                      pw.SizedBox(),
                    pw.Container(
                      width: 180,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: pw.BorderRadius.circular(6)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Subtotal: ₹${_billData!['totalAmount']}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("Tax (0%): ₹0.00", style: const pw.TextStyle(fontSize: 9)),
                          pw.Divider(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.indigo900)),
                              pw.Text("₹${_billData!['totalAmount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.indigo900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(), // const hata diya gaya hai
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("Thank you for shopping with $businessName!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 2),
                      pw.Text("For returns or questions, contact us within 7 days. • Bodeli", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
   }

  // 1. Thermal Printer / Bluetooth Print Button
  void _printInvoice() async {
    final pdf = await _generatePdfDocument();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // 2. Save PDF Button
  void _savePdf() async {
    final pdf = await _generatePdfDocument();
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${_billData!['id']}.pdf');
  }

  // 3. WhatsApp Bill PDF Send Button
  void _sendWhatsAppBillPdf() async {
    String mobile = _billData!['customerMobile'] ?? "";
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer ka mobile number nahi hai!')));
      return;
    }
    final pdf = await _generatePdfDocument();
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${_billData!['id']}.pdf');
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
              if (theme == "Mobile (Thermal)") _buildVipThermalReceipt(),
              if (theme == "Modern Boxed") _buildVipModernBoxed(),
              if (theme == "Classic Minimal") _buildVipClassicMinimal(),
              if (theme == "Dark Header") _buildVipDarkHeader(),

              const SizedBox(height: 20),

              // --- 1. THERMAL PRINTER / BLUETOOTH PRINT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _printInvoice,
                  icon: const Icon(Icons.print),
                  label: const Text("Thermal Printer / Bluetooth Print", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  // --- 2. SAVE PDF BUTTON ---
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Save PDF"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // --- 3. WHATSAPP BILL (PDF SHARE) BUTTON ---
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendWhatsAppBillPdf,
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
  // 1. VIP MODERN BOXED THEME
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
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

  // ==========================================
  // 2. VIP MOBILE THERMAL RECEIPT THEME
  // ==========================================
  Widget _buildVipThermalReceipt() {
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String address = _settings?['address'] ?? "Bodeli";
    String mobile = _settings?['mobile'] ?? "9904178658";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";
    String businessType = _settings?['businessType'] ?? "WHOLESALER";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text(businessType.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(fontSize: 12)),
          Text("Mob: $mobile", style: const TextStyle(fontSize: 12)),
          const Divider(thickness: 1, color: Colors.black54),
          _buildThermalRow("Bill No:", "#HUR-${_billData!['id']}"),
          _buildThermalRow("Date:", _billData!['date']),
          _buildThermalRow("Customer:", _billData!['customerName']),
          _buildThermalRow("Phone:", _billData!['customerMobile'] ?? ""),
          const Divider(thickness: 1, color: Colors.black54),
          const Row(
            children: [
              Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          const Divider(color: Colors.grey),
          ..._billItems.map((item) {
            double amount = item['price'] * item['quantity'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item['itemName'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
          const Divider(thickness: 1, color: Colors.black54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹ ${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black54),
          const SizedBox(height: 10),
          if (upiId.isNotEmpty) ...[
            QrImageView(
              data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR",
              version: QrVersions.auto,
              size: 100.0,
            ),
            const SizedBox(height: 6),
            Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          const Text("THANK YOU, VISIT AGAIN!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildThermalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // 3. VIP CLASSIC MINIMAL THEME
  // ==========================================
  Widget _buildVipClassicMinimal() {
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String address = _settings?['address'] ?? "Bodeli";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w300)),
                const Text("PREMIUM SHOWROOM", style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                  const Text("BILL TO:", style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_billData!['customerMobile'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("DATE & INV:", style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(_billData!['date'], style: const TextStyle(fontSize: 11)),
                  Text("INV: #${_billData!['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(flex: 4, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text("PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          const Divider(),
          ..._billItems.map((item) {
            double amount = item['price'] * item['quantity'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(item['itemName'], style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text("₹${item['price']}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("TOTAL: ₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                if (upiId.isNotEmpty) ...[
                  QrImageView(
                    data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR",
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                  const SizedBox(height: 4),
                  Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 8),
                ],
                Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. VIP DARK HEADER THEME
  // ==========================================
  Widget _buildVipDarkHeader() {
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String address = _settings?['address'] ?? "Bodeli";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(address, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
                const Text("INVOICE", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BILL TO", style: TextStyle(fontSize: 9, color: Colors.grey)),
                        Text(_billData!['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_billData!['customerMobile'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("DATE", style: TextStyle(fontSize: 9, color: Colors.grey)),
                        Text(_billData!['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ..._billItems.map((item) {
                  double amount = item['price'] * item['quantity'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(item['itemName'], style: const TextStyle(fontSize: 11))),
                        Expanded(flex: 1, child: Text(item['quantity'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                        Expanded(flex: 2, child: Text("₹${amount.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      if (upiId.isNotEmpty) ...[
                        QrImageView(
                          data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR",
                          version: QrVersions.auto,
                          size: 80.0,
                        ),
                        const SizedBox(height: 4),
                        Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 8),
                      ],
                      Text("Thank you for shopping with $businessName!", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
