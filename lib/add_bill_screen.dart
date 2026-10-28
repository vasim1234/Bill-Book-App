import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _customerController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController(); // Nayi
  final _cityController = TextEditingController();    // Nayi
  
  List<Map<String, dynamic>> _stockItems = [];
  List<Map<String, dynamic>> _billItems = []; // Cart
  
  int? _selectedItemId;
  int _quantity = 1;
  double _currentItemPrice = 0.0;
  
  String _paymentStatus = "UNPAID";

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  void _loadStockItems() async {
    final items = await DatabaseHelper().getAllItems();
    setState(() {
      _stockItems = items;
    });
  }

  double get _grandTotal {
    double total = 0;
    for (var item in _billItems) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  void _addItemToCart() {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pehle item select karo!')));
      return;
    }
    
    final selectedItem = _stockItems.firstWhere((element) => element['id'] == _selectedItemId);
    
    if (selectedItem['stock'] < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itna stock nahi hai!')));
      return;
    }

    setState(() {
      _billItems.add({
        'itemName': selectedItem['itemName'],
        'quantity': _quantity,
        'price': _currentItemPrice,
      });
      
      _selectedItemId = null;
      _quantity = 1;
      _currentItemPrice = 0.0;
    });
  }

  void _saveFinalBill() async {
    if (_customerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer ka naam likho!')));
      return;
    }
    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koi item add nahi kiya!')));
      return;
    }

    String date = DateTime.now().toString().substring(0, 10);

    int billId = await DatabaseHelper().saveFullBill(
      {
        'customerName': _customerController.text,
        'customerMobile': _mobileController.text,
        'totalAmount': _grandTotal,
        'date': date,
        'paymentStatus': _paymentStatus,
      },
      _billItems,
    );

    if (mounted) {
      Navigator.pop(context, billId); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background color change kiya
      appBar: AppBar(
        title: const Text("New Sale (Bill)"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- PREMIUM CUSTOMER DETAILS CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      // Contacts Button (PWA Style)
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.contact_phone, size: 18, color: Colors.orange),
                        label: const Text("CONTACTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  TextField(
                    controller: _customerController,
                    decoration: InputDecoration(
                      labelText: "Customer Name",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mobile
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address aur City (Side by side)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: "Address",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: "City / Town",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- ITEMS JODEIN CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.pink),
                      SizedBox(width: 8),
                      Text("Items Jodein", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            hintText: "-- Select Item --",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          value: _selectedItemId,
                          items: _stockItems.map((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'] as int,
                              child: Text("${item['itemName']} (Stock: ${item['stock']})"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedItemId = value;
                              final selected = _stockItems.firstWhere((element) => element['id'] == value);
                              _currentItemPrice = selected['price'];
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.indigo),
                          onPressed: () {
                            // Yahan naya item add karne ka popup khol sakte hain
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price aur Qty
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(text: "₹$_currentItemPrice"),
                          decoration: InputDecoration(
                            labelText: "Price (₹)",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: _quantity.toString()),
                          decoration: InputDecoration(
                            labelText: "Qty",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) {
                            setState(() { _quantity = int.tryParse(val) ?? 1; });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add to Bill Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addItemToCart,
                      icon: const Icon(Icons.add, color: Colors.indigo),
                      label: const Text("+ Add to Bill", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[50],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- BILL TALLY (Agar item add hua hai toh dikhega) ---
            if (_billItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bill Tally (${_billItems.length} Items)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                    const Divider(),
                    ..._billItems.map((item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item['quantity']} Pcs x ₹${item['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("₹${(item['quantity'] * item['price']).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() { _billItems.remove(item); });
                              },
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --- PAYMENT STATUS & TOTAL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text("PAYMENT STATUS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPayButton("UNPAID", Colors.red),
                      _buildPayButton("CASH", Colors.green),
                      _buildPayButton("UPI", Colors.blue),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("₹${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveFinalBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900], 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Generate Final Bill", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(String status, Color color) {
    bool isSelected = _paymentStatus == status;
    return GestureDetector(
      onTap: () { setState(() { _paymentStatus = status; }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(status, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
