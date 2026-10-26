import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_bill_screen.dart';
import 'stock_screen.dart';
import 'settings_screen.dart';
import 'cash_screen.dart'; 
import 'bill_preview_screen.dart';
import 'staff_screen.dart';
import 'auth_screen.dart';

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
        scaffoldBackgroundColor: Colors.grey[100]
      ),
      home: const AuthScreen(), 
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
  String _businessName = "My Dukan"; 
  int? _previewBillId; 

  final List<Widget> _screens = [
    const CashScreen(),       
    const StockScreen(),      
    const Center(child: Text("Quick Add (Coming Soon)")),  
    const Center(child: Text("Add Bill Screen (Coming Soon)")), 
    const StaffScreen(), 
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
    Widget bodyWidget = _previewBillId != null 
        ? BillPreviewScreen(billId: _previewBillId!) 
        : _screens[_currentIndex];                   

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.white),
            const SizedBox(width: 8),
            Text(_businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.indigo[900], 
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          )
        ],
      ),
      drawer: const SettingsScreen(),
      
      body: bodyWidget,
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _previewBillId = null; 
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
      
      floatingActionButton: _previewBillId != null ? null : FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
          if (result != null && result is int) {
             setState(() {
               _previewBillId = result; 
             });
          } else {
             setState(() { _currentIndex = 0; }); 
          }
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      
      // Yahan bilkul sahi syntax hai
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
