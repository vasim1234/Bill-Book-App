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

  // PWA ke jaisa exact theme matching PDF Generator
  Future<pw.Document> _generatePdfDocument() async {
    final pdf = pw.Document();
    String theme = _settings?['theme'] ?? "Modern Boxed";
    
    String businessName = _settings?['businessName'] ?? "HUR GARMENTS";
    String ownerName = _settings?['ownerName'] ?? "Mansuri Vasimraj";
    String address = _settings?['address'] ?? "Bodeli";
    String mobile = _settings?['mobile'] ?? "9904178658";
    String upiId = _settings?['upiId'] ?? "9904178658@ybl";
    String businessType = _settings?['businessType'] ?? "Wholesaler";
    String paymentStatus = _billData!['paymentStatus'] ?? "UNPAID";

    pw.Widget pdfBody;

    if (theme == "Modern Boxed") {
      pdfBody = pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.indigo900, width: 1.5), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(businessType.toUpperCase(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text("Address: $address | Ph: $mobile", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INVOICE", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Invoice: #HUR-${_billData!['id']}", style: const pw.TextStyle(fontSize: 9)),
                    pw.Text("Date: ${_billData!['date']}", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.Divider(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILL TO:", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    pw.Text(_billData!['customerName'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text("Phone: ${_billData!['customerMobile'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(color: paymentStatus == "PAID" ? PdfColors.green : PdfColors.red, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text("STATUS: $paymentStatus", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['ITEM DESCRIPTION', 'QTY', 'UNIT PRICE', 'AMOUNT'],
              data: _billItems.map((item) {
                double amount = item['price'] * item['quantity'];
                return [item['itemName'], item['quantity'].toString(), "₹${item['price']}", "₹${amount.toStringAsFixed(2)}"];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (upiId.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR", width: 50, height: 50),
                      pw.Text(upiId, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  )
                else
                  pw.SizedBox(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Subtotal: ₹${_billData!['totalAmount']}", style: const pw.TextStyle(fontSize: 9)),
                    pw.Text("Tax (0%): ₹0.00", style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text("GRAND TOTAL: ₹${_billData!['totalAmount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.indigo900)),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(child: pw.Text("Thank you for shopping with $businessName! We appreciate your business.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
          ],
        ),
      );
    } else if (theme == "Corporate Dark (Dark Header)") {
      pdfBody = pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
        child: pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(color: PdfColors.grey900),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.Text("PREMIUM SHOWROOM • $address", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
                    ],
                  ),
                  pw.Text("INVOICE", style: pw.TextStyle(fontSize: 14, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("BILL TO:", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                          pw.Text(_billData!['customerName'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text(_billData!['customerMobile'] ?? '', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("INV: #${_billData!['id']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text(_billData!['date'], style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headers: ['ITEM', 'QTY', 'PRICE', 'AMOUNT'],
                    data: _billItems.map((item) {
                      double amount = item['price'] * item['quantity'];
                      return [item['itemName'], item['quantity'].toString(), "₹${item['price']}", "₹${amount.toStringAsFixed(2)}"];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey900),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text("TOTAL DUE: ₹${_billData!['totalAmount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red)),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        if (upiId.isNotEmpty) ...[
                          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: "upi://pay?pa=$upiId&pn=$businessName&am=${_billData!['totalAmount']}&cu=INR", width: 50, height: 50),
                          pw.Text(upiId, style: const pw.TextStyle(fontSize: 7)),
                        ],
                        pw.Text("Thank you for shopping with us!", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Classic Minimal (Black & White)
      pdfBody = pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text("GSTIN / Billed By: $ownerName", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text(address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.Divider(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("CUSTOMER:", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    pw.Text(_billData!['customerName'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INVOICE #${_billData!['id']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(_billData!['date'], style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['DESCRIPTION', 'QTY', 'PRICE', 'TOTAL'],
              data: _billItems.map((item) {
                double amount = item['price'] * item['quantity'];
                return [item['itemName'], item['quantity'].toString(), "₹${item['price']}", "₹${amount.toStringAsFixed(2)}"];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.black),
              headerDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("GRAND TOTAL: ₹${_billData!['totalAmount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("Authorized Signatory", style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 10),
                  pw.Text("Thank You!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => pdfBody,
      ),
    );

    return pdf;
  }

  void _printInvoice() async {
    final pdf = await _generatePdfDocument();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _savePdf() async {
    final pdf = await _generatePdfDocument();
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${_billData!['id']}.pdf');
  }

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
          title: const Text("Select Invoice Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              "Modern Boxed",
              "Corporate Dark (Dark Header)",
              "Classic Minimal (Black & White)"
            ].map((themeName) {
              return ListTile(
                title: Text(themeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
            onPressed: () => _showThemePickerDialog(context),
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
              // Screen preview card based on theme selection
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((_settings?['businessName'] ?? "HUR GARMENTS").toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(_settings?['businessType'] ?? "Wholesaler", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("INVOICE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("UNPAID", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Text("Customer: ${_billData!['customerName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Phone: ${_billData!['customerMobile'] ?? 'N/A'}"),
                      const Divider(),
                      ..._billItems.map((item) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item['itemName']} (x${item['quantity']})"),
                          Text("₹${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                        ],
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL DUE:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("₹${_billData!['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Save PDF"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("New Sale", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
