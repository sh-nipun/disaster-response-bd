import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _firestore = FirebaseFirestore.instance;

  // Role change
  Future<void> _changeRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
    _showSnack('✅ Role পরিবর্তন হয়েছে!');
  }

  // User delete
  Future<void> _deleteUser(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('User Delete করবেন?'),
        content: Text('$name কে delete করতে চান?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('হ্যাঁ, Delete করুন',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('users').doc(uid).delete();
      _showSnack('🗑️ User delete হয়েছে!');
    }
  }

  // Ban/Unban
  Future<void> _toggleBan(String uid, bool currentlyBanned) async {
    await _firestore.collection('users').doc(uid).update({
      'banned': !currentlyBanned,
    });
    _showSnack(currentlyBanned ? '✅ User unban হয়েছে!' : '🚫 User ban হয়েছে!');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showUserDetails(Map<String, dynamic> user, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user['name'] ?? 'Unknown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.email, user['email'] ?? ''),
            _detailRow(Icons.phone, user['phone'] ?? ''),
            _detailRow(Icons.verified_user, 'Role: ${user['role'] ?? ''}'),
            _detailRow(Icons.block,
                'Status: ${user['banned'] == true ? 'Banned' : 'Active'}'),
            const SizedBox(height: 12),
            const Text('Role পরিবর্তন:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['victim', 'volunteer', 'responder', 'admin']
                  .map((role) => ChoiceChip(
                        label: Text(role),
                        selected: user['role'] == role,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: user['role'] == role
                                ? Colors.white
                                : Colors.black),
                        onSelected: (_) {
                          _changeRole(uid, role);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _toggleBan(uid, user['banned'] == true);
              Navigator.pop(context);
            },
            child: Text(
              user['banned'] == true ? 'Unban করুন' : 'Ban করুন',
              style: TextStyle(
                  color:
                      user['banned'] == true ? Colors.green : Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(uid, user['name'] ?? '');
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Close',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'volunteer': return Colors.green;
      case 'responder': return Colors.blue;
      case 'admin': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'নাম বা email দিয়ে খুঁজুন...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'victim', 'volunteer', 'responder', 'admin']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f == 'all' ? 'সবাই' : f),
                            selected: _selectedFilter == f,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                                color: _selectedFilter == f
                                    ? Colors.white
                                    : Colors.black),
                            onSelected: (_) =>
                                setState(() => _selectedFilter = f),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Real-time user list from Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('কোনো user নেই'));
                }

                // Filter করো
                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final matchRole = _selectedFilter == 'all' ||
                      data['role'] == _selectedFilter;
                  final matchSearch = _searchQuery.isEmpty ||
                      (data['name'] ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      (data['email'] ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  return matchRole && matchSearch;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('${docs.length} জন user',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final data =
                              docs[i].data() as Map<String, dynamic>;
                          final uid = docs[i].id;
                          final isBanned = data['banned'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _roleColor(
                                        data['role'] ?? 'victim')
                                    .withOpacity(0.15),
                                child: Text(
                                  (data['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                      color: _roleColor(
                                          data['role'] ?? 'victim'),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(data['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (isBanned)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text('BANNED',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 9,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Text(data['email'] ?? '',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Chip(
                                label: Text(data['role'] ?? 'victim',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11)),
                                backgroundColor: _roleColor(
                                    data['role'] ?? 'victim'),
                                padding: EdgeInsets.zero,
                              ),
                              onTap: () => _showUserDetails(data, uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}