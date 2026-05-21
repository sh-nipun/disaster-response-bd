import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/firebase_auth_service.dart';
import 'home_dashboard.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'victim';
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> _roles = [
    {'value': 'victim', 'label': '🆘 সাহায্য দরকার (Victim)'},
    {'value': 'volunteer', 'label': '🤝 স্বেচ্ছাসেবক (Volunteer)'},
    {'value': 'responder', 'label': '👮 Responder / Authority'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnack('নাম দিতে হবে!');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnack('ফোন নম্বর দিতে হবে!');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Email দিতে হবে!');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password কমপক্ষে ৬ অক্ষরের হতে হবে!');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Password দুটো মিলছে না!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Step 1: Firebase Auth এ user তৈরি করো
      final user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // ✅ Step 2: user null হলে মানে registration fail হয়েছে
      if (user == null) {
        _showSnack('❌ Registration হয়নি! Email আগে থেকে registered থাকতে পারে।');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Step 3: Firestore এ user এর extra info save করো
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        _showSnack('✅ Registration সফল হয়েছে!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('❌ Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('নতুন Account খুলুন',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person_add,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Sign Up', style: AppTextStyles.heading),
                    Text('একটি account তৈরি করুন',
                        style: AppTextStyles.subheading),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Name
              _buildLabel('পূর্ণ নাম *'),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('আপনার নাম লিখুন', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildLabel('ফোন নম্বর *'),
              TextField(
                controller: _phoneController,
                decoration: _inputDecoration('01XXXXXXXXX', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              _buildLabel('Email *'),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('example@email.com', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Role selection
              _buildLabel('আপনি কে? *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roles
                        .map((r) => DropdownMenuItem(
                              value: r['value'],
                              child: Text(r['label']!),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              _buildLabel('Password *'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePass,
                decoration: _inputDecoration('কমপক্ষে ৬ অক্ষর', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildLabel('Password নিশ্চিত করুন *'),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration:
                    _inputDecoration('আবার password দিন', Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Signup button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Account খুলুন',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already account আছে? ',
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Login করুন',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }
}