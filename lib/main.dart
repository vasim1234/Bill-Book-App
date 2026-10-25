import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_bill_screen.dart';
import 'stock_screen.dart';
import 'settings_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.indigo, scaffoldBackgroundColor: Colors.grey[100]),
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
  String _businessName = "My Dukan"; // Default naam

  final List<Widget> _screens = [
    const KhataScreen(),
    const StockScreen(),
    const Center(child: Text("Cash Screen (Coming Soon)")),
    const Center(child: Text("Quick Add (Coming Soon)")),
    const Center(child: Text("Staff Screen (Coming Soon)")),
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  void _loadBusinessName() async {
    final data = await DatabaseHelper().getSettings();
    if (data != null && data['businessName'] != null && data['businessName'].toString().isNotEmpty) {
      setState(() {
        _businessName = data['businessName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.white),
            const SizedBox(width: 8),
            Text(_businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.indigo[900], // Dark blue
        foregroundColor: Colors.white,
        actions: [
  Builder(
    builder: (context) => IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        // Sirf drawer kholo, await hata do
        Scaffold.of(context).openDrawer();
      },
    ),
  )
],
      ),
      // Ye Drawer ko sidebar ke liye call karta hai
      drawer: SettingsScreen(),
      
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
      
      // Bada "+" button (Sale ke liye)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
          setState(() { _currentIndex = 0; });
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
    return Column(
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
    );
  }
}
