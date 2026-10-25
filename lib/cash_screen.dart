import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'customer_detail_screen.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  double _totalLena = 0.0;
  double _totalDena = 0.0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final customers = await DatabaseHelper().getAllCustomers();
    final summary = await DatabaseHelper().getTotalCashSummary();

    setState(() {
      _customers = customers;
      _filteredCustomers = customers;
      _totalLena = summary['lena'] ?? 0.0;
      _totalDena = summary['dena'] ?? 0.0;
    });
  }

  void _searchCustomer(String query) {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        return customer['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- Upar ka Summary Card ---
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("💰 Credit / Debit", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Lena hai (Red)
                    Column(
                      children: [
                        const Text("AAPKO LENE HAIN", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("₹ ${_totalLena.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    // Dena hai (White)
                    Column(
                      children: [
                        const Text("AAPKO DENE HAIN", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("₹ ${_totalDena.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),

          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchCustomer,
              decoration: InputDecoration(
                hintText: "Naam se dhundhein...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- Customer List ---
          Expanded(
            child: _filteredCustomers.isEmpty
                ? const Center(child: Text("Koi customer nahi mila. Add karein!"))
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () async {
                            // Customer detail screen par jao
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CustomerDetailScreen(customerId: customer['id'], customerName: customer['name'], customerMobile: customer['mobile'] ?? '')
                            ));
                            _loadData(); // Wapas aane par refresh karo
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Text(customer['name'][0].toUpperCase(), style: const TextStyle(color: Colors.indigo)),
                          ),
                          title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Mo: ${customer['mobile'] ?? 'N/A'}"),
                          trailing: FutureBuilder<double>(
                            future: DatabaseHelper().getCustomerBalance(customer['id']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              double bal = snapshot.data!;
                              if (bal == 0) return const Text("CLEAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold));
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("BALANCE", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    "₹ ${bal.abs().toStringAsFixed(0)}",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: bal > 0 ? Colors.red : Colors.green),
                                  ),
                                  Text(
                                    bal > 0 ? "LENE HAIN" : "DENE HAIN",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bal > 0 ? Colors.red : Colors.green),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog();
        },
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTransactionDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String transactionType = "LIYA"; // Default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // StatefulBuilder use kiya taaki popup ke andar color change ho sake
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Naya Lena-Dena", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 15),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Bande ka Naam", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile", border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: noteController, decoration: const InputDecoration(labelText: "Wajah / Note", border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  
                  // Type Selector (Diya / Liya)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => transactionType = "DIYA"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: transactionType == "DIYA" ? Colors.red[50] : Colors.white,
                              border: Border.all(color: transactionType == "DIYA" ? Colors.red : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text("🔴 Diya", style: TextStyle(fontWeight: FontWeight.bold, color: transactionType == "DIYA" ? Colors.red : Colors.grey)),
                                Text("UDHAAR LENE HAIN", style: TextStyle(fontSize: 10, color: transactionType == "DIYA" ? Colors.red : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => transactionType = "LIYA"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: transactionType == "LIYA" ? Colors.green[50] : Colors.white,
                              border: Border.all(color: transactionType == "LIYA" ? Colors.green : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text("🟢 Liya", style: TextStyle(fontWeight: FontWeight.bold, color: transactionType == "LIYA" ? Colors.green : Colors.grey)),
                                Text("ADVANCE DENE HAIN", style: TextStyle(fontSize: 10, color: transactionType == "LIYA" ? Colors.green : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          // 1. Customer check karo, nahi toh naya banao
                          int customerId;
                          final existing = await DatabaseHelper().getAllCustomers();
                          var found = existing.where((c) => c['name'].toString().toLowerCase() == nameController.text.toLowerCase()).toList();
                          
                          if (found.isNotEmpty) {
                            customerId = found.first['id'];
                          } else {
                            customerId = await DatabaseHelper().insertCustomer({
                              'name': nameController.text,
                              'mobile': mobileController.text,
                            });
                          }

                          // 2. Transaction save karo
                          await DatabaseHelper().insertTransaction({
                            'customerId': customerId,
                            'amount': double.parse(amountController.text),
                            'type': transactionType,
                            'note': noteController.text,
                            'date': DateTime.now().toString(),
                          });

                          Navigator.pop(context);
                          _loadData();
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam aur Amount likhna zaroori hai!')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
                      child: const Text("Save Transaction", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
