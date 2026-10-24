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
  final _addressController = TextEditingController();
  
  List<Map<String, dynamic>> _stockItems = [];
  Map<String, dynamic>? _selectedItem;
  int _quantity = 1;
  double _currentItemPrice = 0.0;

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

  void _saveBill() async {
    if (_customerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer ka naam likho!')));
      return;
    }
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item select karo!')));
      return;
    }
    
    if (_selectedItem!['stock'] < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itna stock nahi hai!')));
      return;
    }

    double total = _currentItemPrice * _quantity;
    String date = DateTime.now().toString().substring(0, 10);

    await DatabaseHelper().insertBill({
      'customerName': _customerController.text,
      'itemName': _selectedItem!['itemName'],
      'quantity': _quantity,
      'price': _currentItemPrice,
      'totalAmount': total,
      'date': date,
      'itemId': _selectedItem!['id'], 
    });

    Navigator.pop(context); 
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Details Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(labelText: "Customer Name", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Mobile Number (Optional)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Address (Optional)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Items Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_bag, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text("Items Jodein", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Dropdown to select item (FIXED)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(labelText: "Select Item", border: OutlineInputBorder()),
                      // Yahan fix kiya gaya hai:
                      value: _selectedItem == null ? null : _stockItems.firstWhere((element) => element['id'] == _selectedItem!['id'], orElse: () => _stockItems.first),
                      items: _stockItems.map((item) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: item,
                          child: Text("${item['itemName']} (Stock: ${item['stock']})"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedItem = value;
                          _currentItemPrice = value!['price'];
                        });
                      },
                    ),
                    
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(text: _currentItemPrice.toString()),
                            decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quantity
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                            controller: TextEditingController(text: _quantity.toString()),
                            onChanged: (value) {
                              setState(() {
                                _quantity = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    
                    // Total Amount Show
                    Text(
                      "Total Amount: ₹${(_currentItemPrice * _quantity).toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save Bill", style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
