import 'package:flutter/material.dart';
import 'package:air/pages/home_page.dart';
import 'package:air/pages/signup_page.dart';
import 'package:air/services/logs_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  final VoidCallback toggleThemeMode;
  final bool isDarkMode;

  const LoginPage({Key? key, required this.toggleThemeMode, required this.isDarkMode}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isFaceIdEnabled = false;
  bool _isAuthenticating = false;
  
  late AnimationController _robotAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _robotFloatAnimation;
  late Animation<double> _pulseAnimation;

  // Hardcoded credentials
  static const String _validUsername = 'admin';
  static const String _validEmail = 'admin@gmail.com';
  static const String _validPassword = 'admin123';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFaceIdAvailability();
  }

  void _initializeAnimations() {
    _robotAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _robotFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _robotAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _robotAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _checkFaceIdAvailability() async {
    if (Platform.isIOS) {
      try {
        final localAuth = LocalAuthentication();
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        final availableBiometrics = await localAuth.getAvailableBiometrics();
        
        // Check if Face ID is available and enabled in settings
        final prefs = await SharedPreferences.getInstance();
        final faceIdEnabled = prefs.getBool('face_id_enabled') ?? false;
        
        setState(() {
          _isFaceIdEnabled = canCheckBiometrics && 
                            availableBiometrics.contains(BiometricType.face) &&
                            faceIdEnabled;
        });
      } catch (e) {
        print('Error checking Face ID availability: $e');
        setState(() {
          _isFaceIdEnabled = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _robotAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithFaceId() async {
    if (!_isFaceIdEnabled) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final localAuth = LocalAuthentication();
      final isAuthenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access AIR',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        LogsManager.addLog(
          message: "User authenticated with Face ID",
          source: "Authentication"
        );
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = 'Face ID authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Face ID not available: $e';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Check credentials
    if ((username == _validUsername || username == _validEmail) && 
        password == _validPassword) {
      
      LogsManager.addLog(
        message: "User logged in successfully: $username",
        source: "Authentication"
      );

      _navigateToHome();
    } else {
      setState(() {
        _errorMessage = 'Invalid username/email or password';
      });
      
      LogsManager.addLog(
        message: "Failed login attempt for: $username",
        source: "Authentication"
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            toggleThemeMode: widget.toggleThemeMode,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Animated Robot Head Image
                AnimatedBuilder(
                  animation: _robotFloatAnimation,
                  builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _robotFloatAnimation.value),
                        child: Container(
                          width: 120,
                          height: 120,
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
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[800],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                  },
                ),
                  
                  const SizedBox(height: 16),
                  
                  // AIR Title
                  Text(
                    'AIR',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 6,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    'Artificial Intelligence Robot',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      letterSpacing: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    'SYSTEM ACCESS',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Face ID Button (if available)
                  if (_isFaceIdEnabled) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ElevatedButton.icon(
                              onPressed: _isAuthenticating ? null : _authenticateWithFaceId,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.blueGrey[800] : Colors.blueGrey[200],
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              icon: _isAuthenticating
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.face, size: 24),
                              label: Text(
                                _isAuthenticating ? 'Authenticating...' : 'Login with Face ID',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],

                  // Login Form Card
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
                          children: [
                            // Username/Email Field
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Username or Email',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                hintText: 'Enter your username or email',
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
                                  return 'Please enter your username or email';
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
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                                  return 'Please enter your password';
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

                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.blueGrey[800] : Colors.blueGrey[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'ACCESS SYSTEM',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Demo Credentials Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueGrey[900]!.withOpacity(0.3) : Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.blueGrey[700]!.withOpacity(0.5) : Colors.blueGrey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Demo Credentials',
                              style: TextStyle(
                                color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Username/Email: admin or admin@gmail.com',
                          style: TextStyle(
                            color: isDark ? Colors.blueGrey[100] : Colors.blueGrey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Password: admin123',
                          style: TextStyle(
                            color: isDark ? Colors.blueGrey[100] : Colors.blueGrey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New to AIR? ",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupPage(
                                toggleThemeMode: widget.toggleThemeMode,
                                isDarkMode: widget.isDarkMode,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Create Account',
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
    );
  }
} 