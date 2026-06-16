import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
   const LoginScreen({super.key});
 
   @override
   ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends ConsumerState<LoginScreen> {
   final _emailController = TextEditingController();
   final _passwordController = TextEditingController();
   bool _isLoading = false;
   bool _obscurePassword = true;
   bool _emailFocused = false;
   bool _passwordFocused = false;
   bool _rememberMe = false;

   String? _emailError;
   String? _passwordError;
 
   final _focusNodeEmail = FocusNode();
   final _focusNodePassword = FocusNode();

   static const String _kRememberMeKey = 'localsync_remember_me';
   static const String _kSavedEmailKey = 'localsync_saved_email';
 
   @override
   void initState() {
     super.initState();
     _loadRememberMe();
     _focusNodeEmail.addListener(() {
       setState(() => _emailFocused = _focusNodeEmail.hasFocus);
     });
     _focusNodePassword.addListener(() {
       setState(() => _passwordFocused = _focusNodePassword.hasFocus);
     });
   }
 
   @override
   void dispose() {
     _emailController.dispose();
     _passwordController.dispose();
     _focusNodeEmail.dispose();
     _focusNodePassword.dispose();
     super.dispose();
   }

   Future<void> _loadRememberMe() async {
     try {
       final prefs = await SharedPreferences.getInstance();
       final savedRemember = prefs.getBool(_kRememberMeKey) ?? false;
       final savedEmail = prefs.getString(_kSavedEmailKey) ?? '';
       if (mounted) {
         setState(() {
           _rememberMe = savedRemember;
           if (_rememberMe && savedEmail.isNotEmpty) {
             _emailController.text = savedEmail;
           }
         });
       }
     } catch (_) {}
   }

   Future<void> _saveRememberMe() async {
     try {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setBool(_kRememberMeKey, _rememberMe);
       if (_rememberMe) {
         await prefs.setString(_kSavedEmailKey, _emailController.text.trim());
       } else {
         await prefs.remove(_kSavedEmailKey);
       }
     } catch (_) {}
   }

   bool _validateFields() {
     final email = _emailController.text.trim();
     final password = _passwordController.text.trim();
     bool isValid = true;

     setState(() {
       _emailError = null;
       _passwordError = null;
     });

     if (email.isEmpty) {
       setState(() => _emailError = 'Email address cannot be empty');
       isValid = false;
     } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
       setState(() => _emailError = 'Please enter a valid email address');
       isValid = false;
     }

     if (password.isEmpty) {
       setState(() => _passwordError = 'Password cannot be empty');
       isValid = false;
     } else if (password.length < 6) {
       setState(() => _passwordError = 'Password must be at least 6 characters');
       isValid = false;
     }

     return isValid;
   }
 
   Future<void> _handleLogin() async {
     if (!_validateFields()) {
       HapticFeedback.vibrate();
       return;
     }

     final email = _emailController.text.trim();
     final password = _passwordController.text.trim();
 
     setState(() => _isLoading = true);
     HapticFeedback.mediumImpact();

     try {
       await ref.read(authRepositoryProvider).signInWithEmail(email, password);
       await _saveRememberMe();
     } catch (e) {
       String errMsg = 'An unexpected error occurred';
       final cleanMsg = e.toString().toLowerCase();
       if (cleanMsg.contains('user-not-found')) {
         setState(() => _emailError = 'No resident account found for this email');
         errMsg = 'Resident account not found';
       } else if (cleanMsg.contains('wrong-password')) {
         setState(() => _passwordError = 'Incorrect password entered');
         errMsg = 'Incorrect password';
       } else if (cleanMsg.contains('invalid-email')) {
         setState(() => _emailError = 'Invalid email address format');
         errMsg = 'Invalid email address';
       } else if (cleanMsg.contains('network-request-failed')) {
         errMsg = 'Network failure. Please check your internet connection.';
       } else {
         errMsg = e.toString().replaceFirst('Exception:', '').trim();
       }
       HapticFeedback.vibrate();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             backgroundColor: AppColors.errorRed,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             content: Text(errMsg, style: const TextStyle(fontWeight: FontWeight.bold)),
           ),
         );
       }
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
   }
 
   Future<void> _handleGoogleSignIn() async {
     setState(() => _isLoading = true);
     HapticFeedback.mediumImpact();
     try {
       await ref.read(authRepositoryProvider).signInWithGoogle();
     } catch (e) {
       HapticFeedback.vibrate();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             backgroundColor: AppColors.errorRed,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             content: Text('Google Sign-In failed: ${e.toString()}'),
           ),
         );
       }
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
   }

   void _showForgotPasswordDialog() {
     final emailCtrl = TextEditingController(text: _emailController.text);
     bool isResetting = false;
     String? resetError;

     showDialog(
       context: context,
       builder: (context) => StatefulBuilder(
         builder: (context, setDialogState) => Dialog(
           backgroundColor: Colors.transparent,
           child: GlassCard(
             borderRadius: 24,
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: AppColors.neonCyan.withOpacity(0.12),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.lock_reset_rounded, color: AppColors.neonCyan, size: 24),
                     ),
                     const SizedBox(width: 14),
                     Expanded(
                       child: Text(
                         'Reset Password',
                         style: GoogleFonts.outfit(
                           color: Colors.white,
                           fontSize: 20,
                           fontWeight: FontWeight.w800,
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 Text(
                   'Enter your email address. We will send you a secure link to reset your password.',
                   style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.5),
                 ),
                 const SizedBox(height: 20),
                 Container(
                   decoration: BoxDecoration(
                     color: AppColors.surfaceNavy,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                       color: resetError != null ? AppColors.errorRed : Colors.white.withOpacity(0.08),
                       width: 1.5,
                     ),
                   ),
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: TextField(
                     controller: emailCtrl,
                     keyboardType: TextInputType.emailAddress,
                     style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                     decoration: const InputDecoration(
                       hintText: 'Email address',
                       hintStyle: TextStyle(color: Colors.white30),
                       border: InputBorder.none,
                     ),
                     onChanged: (_) {
                       if (resetError != null) {
                         setDialogState(() => resetError = null);
                       }
                     },
                   ),
                 ),
                 if (resetError != null) ...[
                   const SizedBox(height: 8),
                   Text(
                     resetError!,
                     style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 11, fontWeight: FontWeight.w600),
                   ),
                 ],
                 const SizedBox(height: 28),
                 isResetting
                     ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                     : Row(
                         children: [
                           Expanded(
                             child: TextButton(
                               onPressed: () => Navigator.pop(context),
                               child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                             ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: ElevatedButton(
                               onPressed: () async {
                                 final email = emailCtrl.text.trim();
                                 if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                   setDialogState(() => resetError = 'Please enter a valid email address');
                                   HapticFeedback.vibrate();
                                   return;
                                 }

                                 setDialogState(() => isResetting = true);
                                 HapticFeedback.mediumImpact();

                                 try {
                                   await ref.read(authRepositoryProvider).resetPassword(email);
                                   if (context.mounted) Navigator.pop(context);
                                   if (mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         backgroundColor: AppColors.neonGreen,
                                         behavior: SnackBarBehavior.floating,
                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                         content: Text(
                                           'Password reset link successfully sent to $email!',
                                           style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                                         ),
                                       ),
                                     );
                                   }
                                 } catch (e) {
                                   setDialogState(() {
                                     resetError = e.toString().replaceFirst('Exception:', '').trim();
                                     isResetting = false;
                                   });
                                   HapticFeedback.vibrate();
                                 }
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: AppColors.neonCyan,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 minimumSize: const Size(0, 48),
                               ),
                               child: Text(
                                 'SEND LINK',
                                 style: GoogleFonts.inter(
                                   color: AppColors.primaryNavy,
                                   fontWeight: FontWeight.bold,
                                 ),
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
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: const Color(0xFF0A121A),
       body: Stack(
         children: [
           // Background ambient lights
           Positioned(
             top: -80,
             right: -80,
             child: Container(
               width: 260,
               height: 260,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: AppColors.neonCyan.withOpacity(0.06),
               ),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                 child: Container(color: Colors.transparent),
               ),
             ),
           ),
           Positioned(
             bottom: -100,
             left: -100,
             child: Container(
               width: 300,
               height: 300,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: AppColors.primaryBlue.withOpacity(0.06),
               ),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                 child: Container(color: Colors.transparent),
               ),
             ),
           ),
           SafeArea(
             child: Center(
               child: SingleChildScrollView(
                 physics: const BouncingScrollPhysics(),
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     // Brand Logo header
                     Center(
                       child: Column(
                         children: [
                           Container(
                             width: 80,
                             height: 80,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Colors.white,
                               boxShadow: [
                                 BoxShadow(
                                   color: AppColors.neonCyan.withOpacity(0.25),
                                   blurRadius: 20,
                                   spreadRadius: 2,
                                 ),
                               ],
                             ),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(40),
                               child: Image.asset(
                                 'assets/images/app_symbol.png',
                                 fit: BoxFit.contain,
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           Text(
                             'LocalSync',
                             style: GoogleFonts.outfit(
                               color: Colors.white,
                               fontSize: 32,
                               fontWeight: FontWeight.w800,
                               letterSpacing: -1,
                             ),
                           ),
                           Text(
                             'BUILDING STRONGER COMMUNITY CONNECTIONS',
                             style: GoogleFonts.inter(
                               color: AppColors.neonCyan.withOpacity(0.85),
                               fontSize: 11,
                               fontWeight: FontWeight.w800,
                               letterSpacing: 1.2,
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 32),
                     // Glass Card Form
                     GlassCard(
                   borderRadius: 24,
                       padding: const EdgeInsets.all(24),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                           Semantics(
                             label: 'SIGN IN',
                             child: Text(
                               'SIGN IN',
                               style: GoogleFonts.outfit(
                                 color: Colors.white,
                                 fontSize: 20,
                                 fontWeight: FontWeight.w800,
                                 letterSpacing: 1.5,
                               ),
                               textAlign: TextAlign.center,
                             ),
                           ),
                           const SizedBox(height: 24),
                           // Email Field
                           _buildInputWrapper(
                             focused: _emailFocused,
                             error: _emailError != null,
                             child: Semantics(
                               label: 'Email address',
                               child: TextField(
                                 controller: _emailController,
                                 focusNode: _focusNodeEmail,
                                 keyboardType: TextInputType.emailAddress,
                                 style: GoogleFonts.inter(color: Colors.white),
                                 decoration: InputDecoration(
                                   prefixIcon: Icon(
                                     Icons.mail_outline_rounded,
                                     color: _emailError != null
                                         ? AppColors.errorRed
                                         : (_emailFocused ? AppColors.neonCyan : Colors.white38),
                                   ),
                                   hintText: 'Email address',
                                   border: InputBorder.none,
                                   enabledBorder: InputBorder.none,
                                   focusedBorder: InputBorder.none,
                                   filled: false,
                                   contentPadding: const EdgeInsets.symmetric(
                                       vertical: 16, horizontal: 16),
                                 ),
                                 onChanged: (_) {
                                   if (_emailError != null) {
                                     setState(() => _emailError = null);
                                   }
                                 },
                               ),
                             ),
                           ),
                           if (_emailError != null) ...[
                             const SizedBox(height: 6),
                             Padding(
                               padding: const EdgeInsets.only(left: 8),
                               child: Text(
                                 _emailError!,
                                 style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 11, fontWeight: FontWeight.w600),
                               ),
                             ),
                           ],
                           const SizedBox(height: 16),
                           // Password Field
                           _buildInputWrapper(
                             focused: _passwordFocused,
                             error: _passwordError != null,
                             child: Semantics(
                               label: 'Password',
                               child: TextField(
                                 controller: _passwordController,
                                 focusNode: _focusNodePassword,
                                 obscureText: _obscurePassword,
                                 style: GoogleFonts.inter(color: Colors.white),
                                 decoration: InputDecoration(
                                   prefixIcon: Icon(
                                     Icons.lock_outline_rounded,
                                     color: _passwordError != null
                                         ? AppColors.errorRed
                                         : (_passwordFocused ? AppColors.neonCyan : Colors.white38),
                                   ),
                                   suffixIcon: IconButton(
                                     icon: Icon(
                                       _obscurePassword
                                           ? Icons.visibility_off_rounded
                                           : Icons.visibility_rounded,
                                       color: Colors.white38,
                                       size: 18,
                                     ),
                                     onPressed: () {
                                       setState(() {
                                         _obscurePassword = !_obscurePassword;
                                       });
                                     },
                                   ),
                                   hintText: 'Password',
                                   border: InputBorder.none,
                                   enabledBorder: InputBorder.none,
                                   focusedBorder: InputBorder.none,
                                   filled: false,
                                   contentPadding: const EdgeInsets.symmetric(
                                       vertical: 16, horizontal: 16),
                                 ),
                                 onChanged: (_) {
                                   if (_passwordError != null) {
                                     setState(() => _passwordError = null);
                                   }
                                 },
                               ),
                             ),
                           ),
                           if (_passwordError != null) ...[
                             const SizedBox(height: 6),
                             Padding(
                               padding: const EdgeInsets.only(left: 8),
                               child: Text(
                                 _passwordError!,
                                 style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 11, fontWeight: FontWeight.w600),
                               ),
                             ),
                           ],
                           const SizedBox(height: 8),
                           // Remember Me & Forgot Password Row
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Row(
                                 children: [
                                   SizedBox(
                                     width: 24,
                                     height: 24,
                                     child: Checkbox(
                                       value: _rememberMe,
                                       activeColor: AppColors.neonCyan,
                                       checkColor: AppColors.primaryNavy,
                                       side: const BorderSide(color: Colors.white38, width: 1.5),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                       onChanged: (val) {
                                         if (val != null) {
                                           HapticFeedback.selectionClick();
                                           setState(() => _rememberMe = val);
                                         }
                                       },
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Text(
                                     'Remember Me',
                                     style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                                   ),
                                 ],
                                ),
                               TextButton(
                                 onPressed: _showForgotPasswordDialog,
                                 style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                                 child: Text(
                                   'Forgot Password?',
                                   style: GoogleFonts.inter(
                                     color: AppColors.neonCyan,
                                     fontWeight: FontWeight.w600,
                                     fontSize: 12,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 16),
                           // Sign In Button
                           _isLoading
                               ? const Center(
                                   child: Padding(
                                     padding: EdgeInsets.symmetric(vertical: 14),
                                     child: CircularProgressIndicator(color: AppColors.neonCyan),
                                   ),
                                 )
                               : Semantics(
                                   label: 'Sign In',
                                   button: true,
                                   child: GradientButton(
                                     label: 'Sign In',
                                     onPressed: _handleLogin,
                                   ),
                                 ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 24),
                     // Divider
                     Row(
                       children: [
                         const Expanded(child: Divider(color: Colors.white10)),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           child: Text(
                             'OR CONTINUE WITH',
                             style: GoogleFonts.inter(
                               color: Colors.white30,
                               fontSize: 11,
                               fontWeight: FontWeight.w600,
                               letterSpacing: 1.5,
                             ),
                           ),
                         ),
                         const Expanded(child: Divider(color: Colors.white10)),
                       ],
                     ),
                     const SizedBox(height: 24),
                     // Google Sign In
                     Container(
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.04),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.white.withOpacity(0.08)),
                       ),
                       child: TextButton(
                         onPressed: _isLoading ? null : _handleGoogleSignIn,
                         style: TextButton.styleFrom(
                           minimumSize: const Size(double.infinity, 56),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                         ),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Image.network(
                               'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/2048px-Google_%22G%22_logo.svg.png',
                               height: 20,
                               errorBuilder: (c, e, s) => const Icon(
                                 Icons.g_mobiledata_rounded,
                                 color: Colors.white,
                               ),
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'Continue with Google',
                               style: GoogleFonts.inter(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w600,
                                 fontSize: 15,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                     const SizedBox(height: 24),
                     // Go to Register
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           "Don't have an account?",
                           style: GoogleFonts.inter(
                             color: Colors.white54,
                             fontSize: 14,
                           ),
                         ),
                         TextButton(
                           onPressed: () => context.push('/register'),
                           child: Text(
                             'Register',
                             style: GoogleFonts.inter(
                               color: AppColors.neonCyan,
                               fontWeight: FontWeight.w700,
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
     );
   }
 
   Widget _buildInputWrapper({required bool focused, required bool error, required Widget child}) {
     return AnimatedContainer(
       duration: const Duration(milliseconds: 200),
       decoration: BoxDecoration(
         color: AppColors.surfaceNavy,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: error 
               ? AppColors.errorRed 
               : (focused ? AppColors.neonCyan : Colors.white.withOpacity(0.08)),
           width: 1.5,
         ),
       ),
       child: child,
     );
   }
}
