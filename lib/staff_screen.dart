import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'staff_detail_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStaff = [];

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
      var record = attendance.where((a) => a['staffId'] == s['id']).toList();
      if (record.isNotEmpty) {
        if (record.first['status'] == 'Present') present++;
        if (record.first['status'] == 'Absent') absent++;
      }
    }

    setState(() {
      _staffList = staff;
      _filteredStaff = staff;
      _presentCount = present;
      _absentCount = absent;
      _totalSalary = totalWage;
    });
  }

  void _filterStaff(String query) {
    setState(() {
      _filteredStaff = _staffList.where((staff) {
        return staff['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // PWA jaisa light grey background
      body: Column(
        children: [
          // Top Header (PWA Style Floating Card)
          // Top Header (PWA Style Floating Card)
Container(
  margin: const EdgeInsets.all(16),
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Padding adjust ki
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A4B),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Left Side Text
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: const Text(
                    "Staff Haazri", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text("Attendance aur Pagar Book", style: TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      
      // Right Side Buttons
      Row(
        children: [
          // + NAYA Button (Chhota kiya)
          OutlinedButton(
            onPressed: () => _showAddStaffDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white, 
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding kam ki
              minimumSize: const Size(0, 32), // Height fix ki
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text("+ NAYA", style: TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 6),
          // + HAAZRI Button (Chhota kiya)
          ElevatedButton(
            onPressed: () => _showAddAttendanceDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: const Color(0xFF1A1A4B),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding kam ki
              minimumSize: const Size(0, 32), // Height fix ki
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text("+ HAAZRI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    ],
  ),
),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard("PRESENT", _presentCount.toString(), Colors.green),
                _buildSummaryCard("ABSENT", _absentCount.toString(), Colors.red),
                _buildSummaryCard("SALARY", "₹${_totalSalary.toStringAsFixed(0)}", Colors.indigo),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStaff,
              decoration: InputDecoration(
                hintText: "Staff ka naam dhundhein...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Staff List
          Expanded(
            child: _filteredStaff.isEmpty
                ? const Center(child: Text("Koi staff add nahi kiya gaya hai.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _filteredStaff[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => StaffDetailScreen(staff: staff)
                            ));
                            _loadData();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(staff['name'].toString().toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("Mo: ${staff['mobile']} • Roz: ₹${staff['dailyWage']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
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

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final wageController = TextEditingController(text: "500");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _showAddAttendanceDialog() {
    String? selectedStaffId;
    String selectedStatus = "Present";
    String selectedPayment = "Baki (Khata)";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Staff Chunein", border: OutlineInputBorder()),
                  items: _staffList.map((s) => DropdownMenuItem<String>(value: s['id'].toString(), child: Text(s['name']))).toList(),
                  onChanged: (val) => setState(() => selectedStaffId = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                        value: selectedStatus,
                        items: const [
                          DropdownMenuItem(value: "Present", child: Text("✅ Present", overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: "Absent", child: Text("❌ Absent", overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) => setState(() => selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Payment", border: OutlineInputBorder()),
                        value: selectedPayment,
                        items: const [
                          DropdownMenuItem(value: "Baki (Khata)", child: Text("📝 Baki", overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: "Paid", child: Text("💵 Paid", overflow: TextOverflow.ellipsis)),
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
