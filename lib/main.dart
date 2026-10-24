import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_bill_screen.dart';
import 'stock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Dukan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainNavigationScreen(), 
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Saari screens ki list
  final List<Widget> _screens = [
    const KhataScreen(),       // 0
    const StockScreen(),       // 1
    const Center(child: Text("Cash Screen (Coming Soon)")), // 2
    const Center(child: Text("Quick Add (Coming Soon)")),   // 3
    const Center(child: Text("Staff Screen (Coming Soon)")),// 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Saare items dikhane ke liye
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Cash'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Quick'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
        ],
      ),
      
      // Center wala bada "+" button (Sale ke liye)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => AddBillScreen()));
          // Bill save hone ke baad list refresh karne ke liye
          setState(() {
            _currentIndex = 0; // Wapas Khata par le aao
          });
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ==========================================
// KHATA SCREEN (Jo humne pehle banaya tha)
// ==========================================
class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List<Map<String, dynamic>> _bills = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() async {
    final data = await DatabaseHelper().getAllBills();
    double total = 0;
    for (var bill in data) {
      total += (bill['totalAmount'] as num).toDouble();
    }
    setState(() {
      _bills = data;
      _totalAmount = total;
    });
  }

  void _deleteBill(int id) async {
    await DatabaseHelper().deleteBill(id);
    _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mera Khata'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Text(
              'Total Udhaar: ₹${_totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _bills.isEmpty
                ? const Center(child: Text('Koi bill nahi hai. Naya bill banao!'))
                : ListView.builder(
                    itemCount: _bills.length,
                    itemBuilder: (context, index) {
                      final bill = _bills[index];
                      return Dismissible(
                        key: Key(bill['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteBill(bill['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bill delete ho gaya!')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text("${bill['customerName']} - ₹${bill['totalAmount']}"),
                            subtitle: Text("${bill['itemName']} x ${bill['quantity']}"),
                            trailing: Text(bill['date']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
