import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_bill_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() async {
    final data = await DatabaseHelper().getAllBills();
    setState(() {
      _bills = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bill Book'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _bills.isEmpty
          ? const Center(child: Text('Koi bill nahi hai. Naya bill banao!'))
          : ListView.builder(
              itemCount: _bills.length,
              itemBuilder: (context, index) {
                final bill = _bills[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("${bill['customerName']} - ₹${bill['totalAmount']}"),
                    subtitle: Text("${bill['itemName']} x ${bill['quantity']}"),
                    trailing: Text(bill['date']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => AddBillScreen()));
          _loadBills(); // Wapas aane par list refresh karo
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
