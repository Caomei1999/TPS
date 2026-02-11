import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/login/utils/blocked_account_alert.dart';
import 'package:user_interface/SCREENS/login/utils/custom_auth_button.dart';
import 'package:user_interface/SCREENS/login/utils/custom_switch.dart';
import 'package:user_interface/SCREENS/login/utils/custom_text_field.dart'; 
import 'package:user_interface/SCREENS/root_screen.dart';
import 'package:user_interface/SERVICES/auth_service.dart';
import 'package:user_interface/services/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final SecureStorageService _storageService = SecureStorageService();

  bool isLogin = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool _isLoading = false;
  bool _isAccountBlocked = false;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(slideRoute(const RootPage()));
  }

  void _handleSignUp() async {
    String password = _passwordController.text;

    if (password != _confirmPasswordController.text) { // Fixed reference to confirm controller logic
      _showErrorSnackbar('Passwords do not match.');
      return;
    }

    RegExp hasUppercase = RegExp(r'[A-Z]');
    RegExp hasLowercase = RegExp(r'[a-z]');
    RegExp hasNumber = RegExp(r'\d');

    if (password.length < 8 || 
        !hasUppercase.hasMatch(password) || 
        !hasLowercase.hasMatch(password) || 
        !hasNumber.hasMatch(password)) {
      
      _showErrorSnackbar(
        'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number.'
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      firstName: _nameController.text.trim(),
      lastName: _surnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: password,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      final accessToken = result['tokens']['access'];
      final refreshToken = result['tokens']['refresh'];

      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      _navigateToMain();
    } else {
      _showErrorSnackbar(
        'Registration failed. Please check the information entered.',
      );
    }
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _isAccountBlocked = false;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (result != null) {
        final accessToken = result['access'];
        final refreshToken = result['refresh'];

        await _storageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _navigateToMain();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      String errorMessage = e.toString().replaceAll("Exception: ", "");

      if (errorMessage.toLowerCase().contains("blocked") || 
          errorMessage.toLowerCase().contains("violations")) {
        setState(() {
          _isAccountBlocked = true;
        });
      } else {
        _showErrorSnackbar(errorMessage);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text(
                  'Sign Up or Log In',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                CustomSwitch(leftLabel: "Login",rightLabel: "Register", primaryColor: Colors.white, secondaryColor: Colors.white24, textColor: Colors.black, isLoginSelected: isLogin,
                  onChanged: (value) {
                    setState(() => isLogin = value);
                  }),
                const SizedBox(height: 40),

                if (_isAccountBlocked && isLogin)
                    const BlockedAccountAlert(),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        CustomTextField(controller: _nameController,label: "First Name",icon: Icons.person_outline,),
                        const SizedBox(height: 16),
                        CustomTextField(controller: _surnameController,label: "Last Name",icon: Icons.person_outline,),
                        const SizedBox(height: 16),
                      ],
                      CustomTextField(controller: _emailController,label: "Email",icon: Icons.email_outlined,keyboardType: TextInputType.emailAddress,),
                      const SizedBox(height: 16),
                      CustomTextField(controller: _passwordController,label: "Password",icon: Icons.lock_outline,isPassword: true,obscureText: !showPassword,
                        onVisibilityToggle: () {
                          setState(() => showPassword = !showPassword);
                        },),

                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        CustomTextField(controller: _confirmPasswordController,label: "Confirm Password",icon: Icons.lock_outline,isPassword: true,obscureText: !showConfirmPassword,onVisibilityToggle: () {
                            setState(() => showConfirmPassword = !showConfirmPassword);
                          })
                        ],
                      if (isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                            },
                            child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70,decoration: TextDecoration.underline),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                      CustomAuthButton(text: isLogin ? "Log In" : "Sign Up", isLoading: _isLoading, onPressed: () { if (isLogin) { _handleLogin(); } else { _handleSignUp(); } }),
                    ],
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