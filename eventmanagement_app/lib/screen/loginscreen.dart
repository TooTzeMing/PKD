import 'package:eventmanagement_app/screen/additionaldata.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Track validation errors
  String? _emailError;
  String? _passwordError;

  void _validateAndLogin() async {
    setState(() {
      _emailError = null; // Reset error messages
      _passwordError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email cannot be empty';
      });
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
      });
    }

    if (_emailError != null || _passwordError != null) return;

    final result = await AuthService().signin(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _emailError = result["emailError"];
      _passwordError = result["passwordError"];
    });

    if (_emailError == null && _passwordError == null) {
      Navigator.popAndPushNamed(context, "/home");
    }
  }
  
void _googleLogin() async {
    try {
      final result = await AuthService().googleSignIn();

      if (result != null) {
        // Navigate to AdditionalDataScreen if user data is incomplete
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdditionalData(
              userId: result['userId']!,
              username: result['username']!,
            ),
          ),
        );
      } else {
        // Navigate to Home if data is already complete
        Navigator.popAndPushNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/gladiator_logo.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 15),

              // Email TextField
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _emailError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: _emailError != null
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Password TextField
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _passwordError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: _passwordError != null
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _validateAndLogin,
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Forgot Password
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgetpassword');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.black),
                ),
              ),

              // Divider with "OR"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey[600],
                      thickness: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey[600],
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              GestureDetector(
                onTap: _googleLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google_icon.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Login with Google',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Additional options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
