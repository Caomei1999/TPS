import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/SERVICES/auth_service.dart';
// IMPORT REUSABLE WIDGETS
import 'package:user_interface/SCREENS/login/utils/custom_text_field.dart';
import 'package:user_interface/SCREENS/login/utils/custom_auth_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  
  // Added state for password visibility toggles
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSendCode() async {
    if (_emailController.text.isEmpty) {
      _showSnackbar("Please enter your email", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.requestPasswordReset(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar("Reset code sent to your email!");
      setState(() => _currentStep = 1);
    } else {
      _showSnackbar(
        "Failed to send code. Check email or network.",
        isError: true,
      );
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (_codeController.text.isEmpty ||
        newPass.isEmpty ||
        confirmPass.isEmpty) {
      _showSnackbar("Please fill all fields", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackbar("Passwords do not match!", isError: true);
      return;
    }

    RegExp hasUppercase = RegExp(r'[A-Z]');
    RegExp hasLowercase = RegExp(r'[a-z]');
    RegExp hasNumber = RegExp(r'\d');

    if (newPass.length < 8 || 
        !hasUppercase.hasMatch(newPass) || 
        !hasLowercase.hasMatch(newPass) || 
        !hasNumber.hasMatch(newPass)) {
      
      _showSnackbar(
        'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number.',
        isError: true
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.confirmPasswordReset(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: newPass,
      newPasswordConfirm: confirmPass,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _showSnackbar("Password reset successful! Please login.");
      Navigator.pop(context);
    } else {
      _showSnackbar(
        "Reset failed. Invalid code or weak password.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
          child: Column(
            children: [
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
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
                    if (_currentStep == 0) ...[
                      const Text("Enter your email to receive a reset code.",textAlign: TextAlign.center,style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      CustomTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 30),
                      CustomAuthButton(text: "Send Code", onPressed: _handleSendCode, isLoading: _isLoading),
                      
                    ] else ...[
                      const Text(
                        "Enter the code sent to your email and your new password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      CustomTextField(controller: _codeController, label: "Code / Token", icon: Icons.vpn_key),
                      const SizedBox(height: 15),
                      CustomTextField(controller: _newPasswordController, label: "New Password", icon: Icons.lock_outline, isPassword: true, obscureText: !_showNewPassword, onVisibilityToggle: () { setState(() => _showNewPassword = !_showNewPassword); }),
                      const SizedBox(height: 15),
                      CustomTextField(controller: _confirmPasswordController, label: "Confirm Password", icon: Icons.lock_outline, isPassword: true, obscureText: !_showConfirmPassword, onVisibilityToggle: () { setState(() => _showConfirmPassword = !_showConfirmPassword); }),
                      const SizedBox(height: 30),
                      CustomAuthButton(text: "Confirm Reset", onPressed: _handleResetPassword, isLoading: _isLoading),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}