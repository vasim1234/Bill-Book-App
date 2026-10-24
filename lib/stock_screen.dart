import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_item_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Map<String, dynamic>> _items = [];
  double _totalStockValue = 0.0; // Total Stock Value nikalne ke liye

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final data = await DatabaseHelper().getAllItems();
    double totalValue = 0;
    for (var item in data) {
      double price = (item['price'] as num).toDouble();
      int stock = (item['stock'] as num).toInt();
      totalValue += (price * stock); // Price x Stock
    }
    setState(() {
      _items = data;
      _totalStockValue = totalValue;
    });
  }

  // Stock Update karne ka function (IN/OUT ke liye)
  void _updateStock(int id, int currentStock, bool isIn) async {
    int newStock = isIn ? currentStock + 1 : (currentStock > 0 ? currentStock - 1 : 0);
    await DatabaseHelper().updateItemStock(id, newStock);
    _loadItems(); // Refresh list
  }

  // Item Delete karne ka function
  void _deleteItem(int id) async {
    await DatabaseHelper().deleteItem(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mera Stock'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Total Stock Value ka Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              children: [
                const Text('TOTAL STOCK VALUE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  '₹ ${_totalStockValue.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                ),
              ],
            ),
          ),

          // Items ki List
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Abhi koi maal nahi hai. Add karo!'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key(item['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteItem(item['id']);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item ka Naam
                                Text(
                                  item['itemName'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                
                                // Price aur Stock
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Sale Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text('₹ ${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('In Stock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text('${item['stock']} Pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    
                                    // IN / OUT Buttons
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _updateStock(item['id'], item['stock'], true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(color: Colors.grey),
                                          ),
                                          child: const Text('+ IN'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateStock(item['id'], item['stock'], false),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                          child: const Text('- OUT'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen()));
          _loadItems();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
