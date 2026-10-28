import 'package:flutter/material.dart';
import 'database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsSaved; 

  const SettingsScreen({super.key, this.onSettingsSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _upiController = TextEditingController();
  final _gstController = TextEditingController();
  
  String _selectedTheme = "Modern Boxed";
  String _selectedType = "Wholesaler";

  final List<String> _themes = ["Mobile (Thermal)", "Modern Boxed", "Classic Minimal", "Dark Header"];
  final List<String> _types = ["Wholesaler", "Retailer", "Distributor"];

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
        _gstController.text = data['gst'] ?? "";
        _selectedTheme = data['theme'] ?? "Modern Boxed";
        _selectedType = data['businessType'] ?? "Wholesaler";
      });
    }
  }

  // Theme badalte hi turant Database me save karo
  void _onThemeChanged(String? newTheme) async {
    if (newTheme == null) return;
    setState(() {
      _selectedTheme = newTheme;
    });
    await DatabaseHelper().updateTheme(newTheme);
    widget.onSettingsSaved?.call();
  }

  void _saveData() async {
    await DatabaseHelper().saveSettings({
      'businessName': _businessController.text,
      'ownerName': _ownerController.text,
      'mobile': _mobileController.text,
      'address': _addressController.text,
      'upiId': _upiController.text,
      'gst': _gstController.text,
      'theme': _selectedTheme,
      'businessType': _selectedType,
    });
    
    if (mounted) {
      widget.onSettingsSaved?.call(); 
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved Successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard khulne par padding adjust karne ke liye
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Drawer(
      child: Column(
        children: [
          // Header (Fixed on top)
          AppBar(
            title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.indigo[900],
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          
          // Scrollable Form Content (Keyboard safe)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding + 16.0),
              child: Column(
                children: [
                  // --- APP SHARE BUTTON ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: Colors.white),
                        SizedBox(width: 8),
                        Text("App Share Karein (Link)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BILL SETTINGS ---
                  _buildSectionTitle("Bill Layout & Theme"),
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_android, size: 18),
                          label: const Text("Mobile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[900], 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text("A4 Wide"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300], 
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Invoice Theme Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Invoice Theme", 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    value: _selectedTheme,
                    items: _themes.map((theme) => DropdownMenuItem(value: theme, child: Text(theme))).toList(),
                    onChanged: _onThemeChanged,
                  ),
                  const SizedBox(height: 20),

                  // --- UPI & QR SETTINGS ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text("UPI ID (Payment QR ke liye)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _upiController,
                          decoration: const InputDecoration(
                            hintText: "e.g., 9904178658@ybl",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BUSINESS DETAILS ---
                  _buildSectionTitle("Business Details"),
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: _businessController, 
                    decoration: const InputDecoration(
                      labelText: "Business Name *", 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    )
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Type", 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          value: _selectedType,
                          isExpanded: true,
                          items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (value) => setState(() => _selectedType = value!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ownerController, 
                          decoration: const InputDecoration(
                            labelText: "Owner Name", 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          )
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mobileController, 
                          keyboardType: TextInputType.phone, 
                          decoration: const InputDecoration(
                            labelText: "Mobile No.", 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          )
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _gstController, 
                          decoration: const InputDecoration(
                            labelText: "GST No.", 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          )
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressController, 
                    decoration: const InputDecoration(
                      labelText: "Address", 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    )
                  ),
                  
                  const SizedBox(height: 24),

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900], 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: const Text("Save Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
    );
  }
}
