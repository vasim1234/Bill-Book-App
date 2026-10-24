import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddBillScreen extends StatefulWidget {
  @override
  _AddBillScreenState createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _customerController = TextEditingController();
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  
  void _saveBill() async {
    String customer = _customerController.text;
    String item = _itemController.text;
    int qty = int.tryParse(_qtyController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0.0;
    double total = qty * price;
    String date = DateTime.now().toString().substring(0, 10);

    if (customer.isNotEmpty && item.isNotEmpty && qty > 0 && price > 0) {
      await DatabaseHelper().insertBill({
        'customerName': customer,
        'itemName': item,
        'quantity': qty,
        'price': price,
        'totalAmount': total,
        'date': date,
      });
      Navigator.pop(context); // Wapas home screen par jao
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Naya Bill Banao")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _customerController, decoration: InputDecoration(labelText: "Customer ka Naam")),
            TextField(controller: _itemController, decoration: InputDecoration(labelText: "Item ka Naam")),
            TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantity")),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price per item")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBill,
              child: Text("Bill Save Karo"),
            )
          ],
        ),
      ),
    );
  }
}
