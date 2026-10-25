import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart'; // Main app import karo

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email aur Password dono daalein!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login Logic
        final user = await DatabaseHelper().loginUser(email, password);
        if (user != null) {
          // Login successful, ab Main App kholein
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Galat Email ya Password!')));
        }
      } else {
        // Register Logic
        await DatabaseHelper().registerUser(email, password);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account ban gaya! Ab Login karein.')));
        setState(() => _isLogin = true); // Login tab par switch karo
      }
    } catch (e) {
      // Agar email pehle se hai toh error aayega
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ye email pehle se registered hai!')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo / Icon
              Icon(Icons.storefront, size: 80, color: Colors.indigo[900]),
              const SizedBox(height: 20),
              Text(
                _isLogin ? "Welcome Back!" : "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
              ),
              const SizedBox(height: 10),
              const Text("Apni dukan ka hisaab aasaan banayein", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900], 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle Login/Signup
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? "Naya account hai? Sign Up karein" : "Pehle se account hai? Login karein",
                  style: const TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
