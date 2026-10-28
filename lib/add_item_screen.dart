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
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Purani values fields mein daal do
    _nameController.text = widget.item['itemName'];
    _purchasePriceController.text = (widget.item['purchasePrice'] ?? 0.0).toString();
    _salePriceController.text = widget.item['price'].toString();
    _stockController.text = widget.item['stock'].toString();
  }

  void _updateItem() async {
    String name = _nameController.text;
    double purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    double salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    int stock = int.tryParse(_stockController.text) ?? 0;

    if (name.isNotEmpty) {
      // Yahan 5 arguments pass kiye hain
      await DatabaseHelper().updateItem(
        widget.item['id'], 
        name, 
        salePrice, 
        purchasePrice, 
        stock
      );
      if (mounted) Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam likhna zaroori hai!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Edit Item"), 
        backgroundColor: Colors.indigo[900], 
        foregroundColor: Colors.white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ITEM NAME", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 5),
              TextField(
                controller: _nameController, 
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PURCHASE (₹)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _purchasePriceController, 
                          keyboardType: TextInputType.number, 
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("SALE (₹)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _salePriceController, 
                          keyboardType: TextInputType.number, 
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("TOTAL PCS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 5),
              TextField(
                controller: _stockController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _updateItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Update Item", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
