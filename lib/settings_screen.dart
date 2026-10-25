import 'package:flutter/material.dart';
import 'database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _upiController = TextEditingController();
  
  String _selectedTheme = "Modern Boxed"; // Default Theme

  final List<String> _themes = [
    "Modern Boxed",
    "Classic Minimal",
    "Dark Header"
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final data = await DatabaseHelper().getSettings();
    if (data != null) {
      setState(() {
        _businessController.text = data['businessName'] ?? "";
        _ownerController.text = data['ownerName'] ?? "";
        _mobileController.text = data['mobile'] ?? "";
        _addressController.text = data['address'] ?? "";
        _upiController.text = data['upiId'] ?? "";
        _selectedTheme = data['theme'] ?? "Modern Boxed"; // Purana theme load karo
      });
    }
  }

  void _saveData() async {
    await DatabaseHelper().saveSettings({
      'businessName': _businessController.text,
      'ownerName': _ownerController.text,
      'mobile': _mobileController.text,
      'address': _addressController.text,
      'upiId': _upiController.text,
      'theme': _selectedTheme, // Theme save karo
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _businessController, decoration: const InputDecoration(labelText: "Business Name")),
                const SizedBox(height: 10),
                TextField(controller: _ownerController, decoration: const InputDecoration(labelText: "Owner Name")),
                const SizedBox(height: 10),
                TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile No")),
                const SizedBox(height: 10),
                TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
                const SizedBox(height: 10),
                TextField(controller: _upiController, decoration: const InputDecoration(labelText: "UPI ID (For QR)")),
                const SizedBox(height: 20),
                
                // --- NAYA DROPDOWN (Bill Theme) ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Invoice Theme", border: OutlineInputBorder()),
                  value: _selectedTheme,
                  items: _themes.map((theme) {
                    return DropdownMenuItem(value: theme, child: Text(theme));
                  }).toList(),
                  onChanged: (value) {
                    setState(() { _selectedTheme = value!; });
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    child: const Text("Save Settings", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
