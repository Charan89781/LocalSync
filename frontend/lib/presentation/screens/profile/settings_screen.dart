import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../core/services/gemini_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _prefsInitialized = false;

  bool _notificationEmergency = true;
  bool _notificationCommunity = true;
  bool _notificationMarketplace = false;
  bool _notificationEvents = true;

  bool _locationSharing = true;
  bool _profileVisibility = true;

  bool _darkMode = true;
  double _textSizeMultiplier = 1.0;

  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationEmergency = _prefs.getBool('settings_notif_emergency') ?? true;
        _notificationCommunity = _prefs.getBool('settings_notif_community') ?? true;
        _notificationMarketplace = _prefs.getBool('settings_notif_marketplace') ?? false;
        _notificationEvents = _prefs.getBool('settings_notif_events') ?? true;
        _locationSharing = _prefs.getBool('settings_location_sharing') ?? true;
        _profileVisibility = _prefs.getBool('settings_profile_visibility') ?? true;
        _darkMode = _prefs.getBool('settings_dark_mode') ?? true;
        
        final multiplier = _prefs.get('settings_text_size_multiplier');
        if (multiplier is double) {
          _textSizeMultiplier = multiplier;
        } else if (multiplier is int) {
          _textSizeMultiplier = multiplier.toDouble();
        } else {
          _textSizeMultiplier = 1.0;
        }
        
        _apiKeyController.text = _prefs.getString('localsync_gemini_api_key') ?? '';
        _prefsInitialized = true;
      });
    } catch (e) {
      debugPrint('[Settings] Error loading preferences: $e');
      setState(() {
        _prefsInitialized = true;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (!_prefsInitialized) return;
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }

    // Sync to Firestore user settings to persist across devices
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final newSettings = UserSettings(
          enablePushNotifications: _notificationEmergency || _notificationCommunity || _notificationMarketplace || _notificationEvents,
          showLocation: _locationSharing,
          darkMode: _darkMode,
          biometricLock: user.settings.biometricLock,
        );
        final updatedUser = user.copyWith(settings: newSettings);
        await ref.read(authRepositoryProvider).updateProfile(updatedUser);
      } catch (e) {
        debugPrint('Firestore sync error: $e');
      }
    }
  }

  Future<void> _handleUpdatePassword() async {
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.secondaryNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Update Password',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter a new secure password for your LocalSync profile account.',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Password field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: passController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'New password',
                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm Password field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: confirmController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white30)),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      final pass = passController.text.trim();
                      final confirm = confirmController.text.trim();
                      if (pass.isEmpty || confirm.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields.')),
                        );
                        return;
                      }
                      if (pass != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match.')),
                        );
                        return;
                      }
                      if (pass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters.')),
                        );
                        return;
                      }

                      setDialogState(() => dialogLoading = true);
                      try {
                        await FirebaseAuth.instance.currentUser?.updatePassword(pass);
                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password successfully updated!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() => dialogLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating password: ${e.toString()}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: dialogLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy))
                  : Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout Account', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to log out of LocalSync? You will need to sign in again to stay connected.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white30)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background subtle ambient glows
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SECTION: ACCOUNT
                  _buildSectionHeader('ACCOUNT SECURITY'),
                  const SizedBox(height: 12),
                  _buildOptionCard([
                    _buildSettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile Details',
                      subtitle: 'Change name, phone, or bio',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const Divider(),
                    _buildSettingsRow(
                      icon: Icons.lock_reset_rounded,
                      title: 'Update Password',
                      subtitle: 'Change Firebase account secret key',
                      onTap: _handleUpdatePassword,
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // SECTION: NOTIFICATIONS
                  _buildSectionHeader('PUSH NOTIFICATIONS'),
                  const SizedBox(height: 12),
                  _buildOptionCard([
                    _buildSwitchSettingsRow(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.errorRed,
                      title: 'Emergency Alerts',
                      subtitle: 'SOS broadcasts & critical updates',
                      value: _notificationEmergency,
                      onChanged: (val) {
                        setState(() => _notificationEmergency = val);
                        _saveSetting('settings_notif_emergency', val);
                      },
                    ),
                    const Divider(),
                    _buildSwitchSettingsRow(
                      icon: Icons.campaign_rounded,
                      color: AppColors.neonCyan,
                      title: 'Community Broadcasts',
                      subtitle: 'Notice board pins & direct flyers',
                      value: _notificationCommunity,
                      onChanged: (val) {
                        setState(() => _notificationCommunity = val);
                        _saveSetting('settings_notif_community', val);
                      },
                    ),
                    const Divider(),
                    _buildSwitchSettingsRow(
                      icon: Icons.storefront_rounded,
                      color: Colors.greenAccent,
                      title: 'Marketplace Requests',
                      subtitle: 'Lending queries & approval updates',
                      value: _notificationMarketplace,
                      onChanged: (val) {
                        setState(() => _notificationMarketplace = val);
                        _saveSetting('settings_notif_marketplace', val);
                      },
                    ),
                    const Divider(),
                    _buildSwitchSettingsRow(
                      icon: Icons.event_available_rounded,
                      color: AppColors.neonPurple,
                      title: 'RSVP Event Reminders',
                      subtitle: 'Remind before attending scheduled acts',
                      value: _notificationEvents,
                      onChanged: (val) {
                        setState(() => _notificationEvents = val);
                        _saveSetting('settings_notif_events', val);
                      },
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // SECTION: PRIVACY
                  _buildSectionHeader('DATA PRIVACY & VISIBILITY'),
                  const SizedBox(height: 12),
                  _buildOptionCard([
                    _buildSwitchSettingsRow(
                      icon: Icons.location_searching_rounded,
                      color: AppColors.neonCyan,
                      title: 'Live Location Sharing',
                      subtitle: 'Allows precise 2km neighborhood mapping',
                      value: _locationSharing,
                      onChanged: (val) {
                        setState(() => _locationSharing = val);
                        _saveSetting('settings_location_sharing', val);
                      },
                    ),
                    const Divider(),
                    _buildSwitchSettingsRow(
                      icon: Icons.remove_red_eye_outlined,
                      color: Colors.orangeAccent,
                      title: 'Public Profile Visibility',
                      subtitle: 'Show trust stats and listing counts',
                      value: _profileVisibility,
                      onChanged: (val) {
                        setState(() => _profileVisibility = val);
                        _saveSetting('settings_profile_visibility', val);
                      },
                    ),
                  ]),
                  const SizedBox(height: 28),
                  // SECTION: AI CONFIGURATION
                  _buildSectionHeader('AI ASSISTANT CONFIGURATION'),
                  const SizedBox(height: 12),
                  _buildOptionCard([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.vpn_key_rounded, color: AppColors.neonCyan, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gemini API Key',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Direct cloud connection for neighborhood AI companion',
                                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceNavy,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _apiKeyController,
                                    obscureText: true,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Enter Gemini API Key (starts with AIzaSy)',
                                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                    ),
                                    onChanged: (val) async {
                                      await _prefs.setString('localsync_gemini_api_key', val.trim());
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.neonGreen, size: 20),
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final savedKey = _apiKeyController.text.trim();
                                    if (savedKey.isNotEmpty && !savedKey.startsWith('AIzaSy')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Warning: Gemini API keys usually start with AIzaSy'),
                                          backgroundColor: Colors.orangeAccent,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Gemini API Key saved successfully!'),
                                          backgroundColor: AppColors.neonGreen,
                                        ),
                                      );
                                    }
                                    await GeminiService.instance.runConnectivityTest();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // SECTION: SYSTEM & LOOKS
                  _buildSectionHeader('INTERFACE & VISUALS'),
                  const SizedBox(height: 12),
                  _buildOptionCard([
                    _buildSwitchSettingsRow(
                      icon: Icons.dark_mode_outlined,
                      color: Colors.white,
                      title: 'Dark Theme Mode',
                      subtitle: 'Enables deep slate premium dark skin',
                      value: _darkMode,
                      onChanged: (val) {
                        setState(() => _darkMode = val);
                        _saveSetting('settings_dark_mode', val);
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_size_rounded, color: Colors.white54, size: 20),
                              const SizedBox(width: 16),
                              Text(
                                'Text Size Multiplier',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Slider(
                            value: _textSizeMultiplier,
                            min: 0.8,
                            max: 1.4,
                            divisions: 3,
                            label: '${(_textSizeMultiplier * 100).toInt()}%',
                            activeColor: AppColors.neonCyan,
                            inactiveColor: Colors.white10,
                            onChanged: (val) {
                              setState(() => _textSizeMultiplier = val);
                              _saveSetting('settings_text_size_multiplier', val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 36),

                  // LOGOUT BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
                    ),
                    child: TextButton(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Logout LocalSync Account',
                            style: GoogleFonts.inter(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildOptionCard(List<Widget> children) {
    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white30, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSettingsRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.neonCyan,
            activeTrackColor: AppColors.neonCyan.withValues(alpha: 0.2),
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

}
