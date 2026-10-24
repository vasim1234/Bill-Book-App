import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  void _saveItem() async {
    String item = _itemController.text;
    double price = double.tryParse(_priceController.text) ?? 0.0;
    int stock = int.tryParse(_stockController.text) ?? 0;

    if (item.isNotEmpty && price > 0 && stock >= 0) {
      await DatabaseHelper().insertItem({
        'itemName': item,
        'price': price,
        'stock': stock,
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi detail bharo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Naya Maal Add Karo"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _itemController, decoration: const InputDecoration(labelText: "Item ka Naam (e.g., Baby Wipes)")),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Sale Price (₹)")),
            TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Kitna Stock Hai?")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("Maal Save Karo"),
            )
          ],
        ),
      ),
    );
  }
}
