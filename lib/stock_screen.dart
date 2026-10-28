import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Map<String, dynamic>> _items = [];
  double _totalStockValue = 0.0; 
  double _thisMonthSale = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final items = await DatabaseHelper().getAllItems();
    double totalValue = 0;
    for (var item in items) {
      double price = (item['price'] as num).toDouble();
      int stock = (item['stock'] as num).toInt();
      totalValue += (price * stock);
    }

    double monthSale = await DatabaseHelper().getThisMonthSale();

    setState(() { 
      _items = items; 
      _totalStockValue = totalValue; 
      _thisMonthSale = monthSale;
    });
  }

  void _updateStock(int id, int currentStock, bool isIn) async {
    int newStock = isIn ? currentStock + 1 : (currentStock > 0 ? currentStock - 1 : 0);
    await DatabaseHelper().updateItemStock(id, newStock);
    _loadData();
  }

  void _deleteItem(int id) async {
    await DatabaseHelper().deleteItem(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- NAYA PREMIUM DASHBOARD HEADER ---
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stock Value Box
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2, color: Colors.indigo),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'STOCK VALUE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹ ${_totalStockValue.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider Line
                Container(
                  height: 60,
                  width: 1.5,
                  color: Colors.grey[200],
                ),
                
                // This Month Sale Box
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'THIS MONTH SOLD',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹ ${_thisMonthSale.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
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
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        onDismissed: (direction) { _deleteItem(item['id']); },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['itemName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    // Edit Button
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () async {
                                        final result = await Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => EditItemScreen(item: item)
                                        ));
                                        if (result == true) { _loadData(); } 
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _updateStock(item['id'], item['stock'], true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
                                          child: const Text('+ IN'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateStock(item['id'], item['stock'], false),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
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
          _loadData();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
