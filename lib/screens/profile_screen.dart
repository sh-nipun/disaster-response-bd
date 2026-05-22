import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _role = 'victim';
  String _email = '';
  String? _photoBase64; // Base64 image string

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _role = data['role'] ?? 'victim';
        _email = data['email'] ?? user.email ?? '';
        _photoBase64 = data['photoBase64'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _email = user.email ?? '';
        _isLoading = false;
      });
    }
  }

  // Profile pic upload
  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'photoBase64': base64String,
        });

        setState(() {
          _photoBase64 = base64String;
          _isUploadingImage = false;
        });

        _showSnack('✅ Profile photo update হয়েছে!');
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnack('❌ Error: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('নাম দিতে হবে!');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      setState(() => _isSaving = false);
      _showSnack('✅ Profile update হয়েছে!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('❌ Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'volunteer': return Colors.green;
      case 'responder': return Colors.blue;
      case 'admin': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'volunteer': return '🤝 স্বেচ্ছাসেবক';
      case 'responder': return '👮 Responder';
      case 'admin': return '🛡️ Admin';
      default: return '🆘 Victim';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আমার Profile',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile photo
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor:
                              AppColors.primary.withOpacity(0.15),
                          backgroundImage: _photoBase64 != null
                              ? MemoryImage(
                                  Uint8List.fromList(
                                      base64Decode(_photoBase64!)))
                              : null,
                          child: _photoBase64 == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary),
                                )
                              : null,
                        ),
                        // Camera icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Photo change করতে tap করুন',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _roleColor(_role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _roleColor(_role).withOpacity(0.5)),
                    ),
                    child: Text(
                      _roleLabel(_role),
                      style: TextStyle(
                          color: _roleColor(_role),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(_email,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),

                  // Edit form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Profile Edit করুন',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'পূর্ণ নাম',
                            prefixIcon:
                                const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'ফোন নম্বর',
                            prefixIcon:
                                const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),

                        // Email readonly
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Email',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                    Text(_email),
                                  ],
                                ),
                              ),
                              const Icon(Icons.lock_outline,
                                  color: Colors.grey, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save করুন',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alert history
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('আমার Alert History',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('alerts')
                              .where('createdBy',
                                  isEqualTo: _auth.currentUser?.uid)
                              .orderBy('createdAt', descending: true)
                              .limit(5)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text(
                                'কোনো alert পাঠানো হয়নি',
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            return Column(
                              children: snapshot.data!.docs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final isResolved =
                                    data['isResolved'] == true;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    data['type'] == 'sos'
                                        ? Icons.sos
                                        : Icons.warning,
                                    color: isResolved
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                  title: Text(data['title'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isResolved
                                          ? Colors.green
                                              .withOpacity(0.15)
                                          : Colors.red.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isResolved ? 'Resolved' : 'Active',
                                      style: TextStyle(
                                          color: isResolved
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 11),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}