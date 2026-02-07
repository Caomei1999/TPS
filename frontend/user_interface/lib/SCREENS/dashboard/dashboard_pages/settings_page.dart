import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/services/user_service.dart';
import 'package:user_interface/main.dart';
import 'package:user_interface/STATE/map_style_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  final SecureStorageService _storageService = SecureStorageService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Remove _loadMapStylePreference - now handled by provider
  }

  Future<void> _toggleMapStyle(bool value) async {
    await ref.read(mapStyleProvider.notifier).toggleStyle(value);
  }

  Future<void> _handleLogout() async {
    await _storageService.deleteTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => const Center(
      child: CircularProgressIndicator(color: Colors.redAccent),
    ),
  );

  bool success = false;

  try {
    success = await _userService.deleteAccount();
  } catch (e) {
    debugPrint("Error deleting account: $e");
    success = false;
  }

  if (!mounted) return;

  Navigator.of(context, rootNavigator: true).pop(); 

  if (success) {
    await _handleLogout();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to delete account. Please try again."),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Sfondo scuro che si adatta al tema
          backgroundColor: const Color.fromARGB(255, 2, 11, 60),
          elevation: 10,
          // Bordo arrotondato con linea sottile bianca
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actions: [
            // Tasto ANNULLA
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Tasto LOGOUT (Rosso)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialog
                _handleLogout(); // Esegue il logout
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        bool showOldPassword = false;
        bool showNewPassword = false;
        bool showConfirmPassword = false;
        String? oldPasswordError;
        String? newPasswordError;
        String? confirmPasswordError;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromARGB(255, 52, 12, 108),
                      Color.fromARGB(255, 2, 11, 60),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Change Password',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Current Password Field
                      _buildPasswordField(
                        controller: oldPassController,
                        label: 'Current Password',
                        showPassword: showOldPassword,
                        errorText: oldPasswordError,
                        onToggleVisibility: () {
                          setStateDialog(() => showOldPassword = !showOldPassword);
                        },
                        onChanged: (value) {
                          if (oldPasswordError != null) {
                            setStateDialog(() => oldPasswordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // New Password Field
                      _buildPasswordField(
                        controller: newPassController,
                        label: 'New Password',
                        showPassword: showNewPassword,
                        errorText: newPasswordError,
                        onToggleVisibility: () {
                          setStateDialog(() => showNewPassword = !showNewPassword);
                        },
                        onChanged: (value) {
                          if (newPasswordError != null) {
                            setStateDialog(() => newPasswordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Confirm New Password Field
                      _buildPasswordField(
                        controller: confirmPassController,
                        label: 'Confirm New Password',
                        showPassword: showConfirmPassword,
                        errorText: confirmPasswordError,
                        onToggleVisibility: () {
                          setStateDialog(() => showConfirmPassword = !showConfirmPassword);
                        },
                        onChanged: (value) {
                          if (confirmPasswordError != null) {
                            setStateDialog(() => confirmPasswordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Password must be at least 8 characters',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Update Button
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final oldPass = oldPassController.text.trim();
                                final newPass = newPassController.text.trim();
                                final confirmPass = confirmPassController.text.trim();

                                // Validation
                                bool hasError = false;

                                if (oldPass.isEmpty) {
                                  setStateDialog(() {
                                    oldPasswordError = 'Current password is required';
                                    hasError = true;
                                  });
                                }

                                if (newPass.isEmpty) {
                                  setStateDialog(() {
                                    newPasswordError = 'New password is required';
                                    hasError = true;
                                  });
                                } else if (newPass.length < 8) {
                                  setStateDialog(() {
                                    newPasswordError = 'Password must be at least 8 characters';
                                    hasError = true;
                                  });
                                } else if (newPass == oldPass) {
                                  setStateDialog(() {
                                    newPasswordError = 'New password must be different';
                                    hasError = true;
                                  });
                                }

                                if (confirmPass.isEmpty) {
                                  setStateDialog(() {
                                    confirmPasswordError = 'Please confirm your password';
                                    hasError = true;
                                  });
                                } else if (newPass != confirmPass) {
                                  setStateDialog(() {
                                    confirmPasswordError = 'Passwords do not match';
                                    hasError = true;
                                  });
                                }

                                if (hasError) return;

                                // Show confirmation dialog with logout warning
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (confirmCtx) => AlertDialog(
                                    backgroundColor: const Color(0xFF020B3C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Confirm Password Change',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Are you sure you want to change your password?',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.logout, color: Colors.amber, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'You will be logged out and redirected to the login page.',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.amber,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'You will need to log in again with your new password.',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white60,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(confirmCtx, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(color: Colors.white54),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(confirmCtx, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.greenAccent,
                                        ),
                                        child: Text(
                                          'Change Password',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                setStateDialog(() => isLoading = true);

                                final success = await _userService.changePassword(
                                  oldPassword: oldPass,
                                  newPassword: newPass,
                                );

                                if (ctx.mounted) {
                                  setStateDialog(() => isLoading = false);
                                  if (success) {
                                    Navigator.pop(ctx);
                                    // Log out and redirect to login
                                    await _storageService.deleteTokens();
                                    if (this.mounted) {
                                      Navigator.of(this.context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  } else {
                                    setStateDialog(() {
                                      oldPasswordError = 'Incorrect current password';
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      cursorColor: Colors.white,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: errorText != null 
                ? Colors.redAccent 
                : Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: errorText != null ? Colors.redAccent : Colors.white,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMapStyle = ref.watch(mapStyleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: AppSizes.screenHeight,
        width: AppSizes.screenWidth,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // PREFERENCES SECTION (First)
                _buildSectionHeader('Preferences'),
                const SizedBox(height: 15),
                _buildSwitchTile(
                  context,
                  icon: IconlyBold.notification,
                  title: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  context,
                  icon: darkMapStyle ? Icons.nightlight_round : Icons.wb_sunny,
                  title: 'Dark Map Style',
                  subtitle: 'Toggle between light and dark map',
                  value: darkMapStyle,
                  onChanged: _toggleMapStyle,
                ),
                const SizedBox(height: 30),
                // ACCOUNT SECTION (Merged with Danger Zone)
                _buildSectionHeader('Account'),
                const SizedBox(height: 15),
                _buildSettingsTile(
                  context,
                  icon: IconlyBold.profile,
                  title: 'Edit Profile',
                  subtitle: 'Update personal details',
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 3;
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: IconlyBold.lock,
                  title: 'Change Password',
                  subtitle: 'Update your security',
                  onTap: _showChangePasswordDialog,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDangerTile(
                  context,
                  icon: IconlyBold.logout,
                  title: 'Logout',
                  onTap: _showLogoutDialog,
                ),
                const SizedBox(height: 10),
                _buildDangerTile(
                  context,
                  icon: IconlyBold.delete,
                  title: 'Delete Account',
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(
          IconlyLight.arrow_right_2,
          color: Colors.white54,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.greenAccent,
          activeTrackColor: Colors.greenAccent.withOpacity(0.4),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildDangerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.redAccent, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isConfirmingDelete = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromARGB(255, 52, 12, 108),
                      Color.fromARGB(255, 2, 11, 60),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconlyBold.danger,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isConfirmingDelete
                          ? 'Final Confirmation'
                          : 'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isConfirmingDelete
                          ? 'Clicking delete again will permanently erase all your data.'
                          : 'Are you sure you want to delete your account?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        if (!isConfirmingDelete) {
                          setStateDialog(() {
                            isConfirmingDelete = true;
                          });
                        } else {
                          Navigator.pop(ctx);
                          _handleDeleteAccount();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: isConfirmingDelete
                            ? const BorderSide(color: Colors.red, width: 2)
                            : BorderSide.none,
                        backgroundColor: isConfirmingDelete
                            ? Colors.red.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        isConfirmingDelete
                            ? 'Yes, Delete Everything!'
                            : 'Delete Forever',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
