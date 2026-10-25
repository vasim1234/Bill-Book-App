import 'package:flutter/material.dart';
import 'database_helper.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Map<String, dynamic>> _staffList = [];
  int _presentCount = 0;
  int _absentCount = 0;
  double _totalSalary = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final staff = await DatabaseHelper().getAllStaff();
    String today = DateTime.now().toString().substring(0, 10);
    final attendance = await DatabaseHelper().getTodayAttendance(today);

    int present = 0;
    int absent = 0;
    double totalWage = 0;

    for (var s in staff) {
      totalWage += (s['dailyWage'] as num).toDouble();
      // Check karo aaj present hai ya absent
      var record = attendance.where((a) => a['staffId'] == s['id']).toList();
      if (record.isNotEmpty) {
        if (record.first['status'] == 'Present') present++;
        if (record.first['status'] == 'Absent') absent++;
      }
    }

    setState(() {
      _staffList = staff;
      _presentCount = present;
      _absentCount = absent;
      _totalSalary = totalWage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Header (Dark Blue)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Staff Haazri", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text("Attendance aur Pagar Book", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAddStaffDialog(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
                      child: const Text("+ NAYA"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showAddAttendanceDialog(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo),
                      child: const Text("+ HAAZRI"),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard("PRESENT", _presentCount.toString(), Colors.green),
                _buildSummaryCard("ABSENT", _absentCount.toString(), Colors.red),
                _buildSummaryCard("SALARY", "₹${_totalSalary.toStringAsFixed(0)}", Colors.indigo),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Staff ka naam dhundhein...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Staff List
          Expanded(
            child: _staffList.isEmpty
                ? const Center(child: Text("Koi staff add nahi kiya gaya hai."))
                : ListView.builder(
                    itemCount: _staffList.length,
                    itemBuilder: (context, index) {
                      final staff = _staffList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.indigo[100], child: Text(staff['name'][0])),
                          title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Mo: ${staff['mobile']} | ₹${staff['dailyWage']}/day"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }

  // Dialog: Naya Staff Add karna
  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final wageController = TextEditingController(text: "500");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.indigo),
            SizedBox(width: 8),
            Text("Naya Staff Jodein"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Naam likhein", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: wageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Roz ka Pagar", border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper().insertStaff({
                  'name': nameController.text,
                  'mobile': mobileController.text,
                  'dailyWage': double.tryParse(wageController.text) ?? 0.0,
                });
                Navigator.pop(context);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900]),
            child: const Text("Save Staff", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Dialog: Haazri Lagana
  void _showAddAttendanceDialog() {
    String? selectedStaffId;
    String selectedStatus = "Present";
    String selectedPayment = "Baki (Khata)";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.indigo),
                SizedBox(width: 8),
                Text("Haazri Lagayein"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  readOnly: true,
                  controller: TextEditingController(text: DateTime.now().toString().substring(0, 10)),
                  decoration: const InputDecoration(labelText: "Tariq (Date)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Staff Chunein", border: OutlineInputBorder()),
                  items: _staffList.map((s) => DropdownMenuItem<String>(value: s['id'].toString(), child: Text(s['name']))).toList(),
                  onChanged: (val) => setState(() => selectedStaffId = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                        value: selectedStatus,
                        items: const [
                          DropdownMenuItem(value: "Present", child: Text("✅ Present")),
                          DropdownMenuItem(value: "Absent", child: Text("❌ Absent")),
                        ],
                        onChanged: (val) => setState(() => selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Payment", border: OutlineInputBorder()),
                        value: selectedPayment,
                        items: const [
                          DropdownMenuItem(value: "Baki (Khata)", child: Text("📝 Baki (Khata)")),
                          DropdownMenuItem(value: "Paid", child: Text("💵 Paid")),
                        ],
                        onChanged: (val) => setState(() => selectedPayment = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStaffId != null) {
                    await DatabaseHelper().insertAttendance({
                      'staffId': int.parse(selectedStaffId!),
                      'date': DateTime.now().toString().substring(0, 10),
                      'status': selectedStatus,
                      'paymentStatus': selectedPayment,
                    });
                    Navigator.pop(context);
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900]),
                child: const Text("Save Haazri", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }
}
