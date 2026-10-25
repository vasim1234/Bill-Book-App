import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Purani values fields mein daal do
    _nameController.text = widget.item['itemName'];
    _priceController.text = widget.item['price'].toString();
    _stockController.text = widget.item['stock'].toString();
  }

  void _updateItem() async {
    String name = _nameController.text;
    double price = double.tryParse(_priceController.text) ?? 0.0;
    int stock = int.tryParse(_stockController.text) ?? 0;

    if (name.isNotEmpty) {
      await DatabaseHelper().updateItem(widget.item['id'], name, price, stock);
      Navigator.pop(context, true); // Wapas jao aur batao ki save ho gaya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam likhna zaroori hai!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Item"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stock (Pcs)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text("Update Item", style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
