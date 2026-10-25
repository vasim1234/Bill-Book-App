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
  
  List<Map<String, dynamic>> _stockItems = [];
  List<Map<String, dynamic>> _billItems = []; // Cart
  
  int? _selectedItemId;
  int _quantity = 1;
  double _currentItemPrice = 0.0;
  
  String _paymentStatus = "UNPAID"; // Default

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
    
    // Check stock
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
      
      // Reset fields
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

    // Database mein save karo aur Bill ID return karo
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

    // Save hone ke baad Named Route se Preview par bhejo
    // Isse upar aur neeche ke bars wahi rahenge
    Navigator.pushReplacementNamed(context, '/bill_preview', arguments: billId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Sale (Bill)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- CUSTOMER DETAILS ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(labelText: "Customer Name", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Mobile Number (Optional)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),

            // --- ITEMS JODEIN (Add to Cart) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Items Jodein", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 10),
                    // Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "-- Select Item --", border: OutlineInputBorder()),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(text: "₹$_currentItemPrice"),
                            decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Qty
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: _quantity.toString()),
                            decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()),
                            onChanged: (val) {
                              setState(() { _quantity = int.tryParse(val) ?? 1; });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addItemToCart,
                        icon: const Icon(Icons.add),
                        label: const Text("+ Add to Bill"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[50], foregroundColor: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- BILL TALLY (Cart List) ---
            if (_billItems.isNotEmpty)
              Card(
                color: Colors.indigo[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bill Tally (${_billItems.length} Items)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                      const Divider(color: Colors.indigo),
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
                                icon: const Icon(Icons.close, color: Colors.red),
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
              ),

            // --- PAYMENT STATUS & TOTAL ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("PAYMENT STATUS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        Text("₹${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveFinalBill,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                        child: const Text("Generate Final Bill", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(status, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
