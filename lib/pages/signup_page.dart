import 'package:flutter/material.dart';
import 'package:air/pages/login_page.dart';
import 'package:air/services/logs_manager.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback toggleThemeMode;
  final bool isDarkMode;

  const SignupPage({Key? key, required this.toggleThemeMode, required this.isDarkMode}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // At least 6 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 6 &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password);
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Check if username already exists (demo check)
    if (username == 'admin') {
      setState(() {
        _errorMessage = 'Username already exists. Please choose a different username.';
      });
      
      LogsManager.addLog(
        message: "Signup failed - username already exists: $username",
        source: "Authentication"
      );
    } else {
      // Simulate successful signup
      setState(() {
        _successMessage = 'Account created successfully! You can now login.';
      });
      
      LogsManager.addLog(
        message: "New user signed up: $username ($email)",
        source: "Authentication"
      );

      // Clear form
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Robot Head Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/air_robot_head1.PNG',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[800],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join AIR - Your AI Assistant',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              hintText: 'Enter your username',
                              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                              prefixIcon: Icon(Icons.person, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              if (value.trim() == 'admin') {
                                return 'Username already exists';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                              prefixIcon: Icon(Icons.email, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!_isValidEmail(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                              prefixIcon: Icon(Icons.lock, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                  color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (!_isValidPassword(value)) {
                                return 'Password must be at least 6 characters with uppercase, lowercase, and number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              hintText: 'Confirm your password',
                              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                              prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                  color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[900]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[400]!),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[200],
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          if (_errorMessage != null) const SizedBox(height: 16),

                          // Success Message
                          if (_successMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[900]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[400]!),
                              ),
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: Colors.green[200],
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          if (_successMessage != null) const SizedBox(height: 16),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.blueGrey[800] : Colors.blueGrey[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(
                                        toggleThemeMode: widget.toggleThemeMode,
                                        isDarkMode: widget.isDarkMode,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 