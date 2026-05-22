import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/custom_card.dart';
import 'map_screen.dart';
import 'first_aid_guide.dart';
import 'emergency_contacts.dart';
import 'help_request_feed.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'weather_screen.dart';
import 'admin/admin_dashboard.dart';
import 'weather_screen.dart';

const String adminEmail = 'admin@gmail.com';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _sosSending = false;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final Set<String> _dismissedIds = {};

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
        ),
        headers: {'Accept-Language': 'bn,en'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        final parts = [
          address['village'] ?? address['suburb'] ?? address['neighbourhood'],
          address['city'] ?? address['town'] ?? address['county'],
          address['state'],
        ].where((p) => p != null && (p as String).isNotEmpty).toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      // fallback
    }
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  // Logout
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout করবেন?'),
        content: const Text('আপনি কি সত্যিই logout করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('হ্যাঁ, Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Notification panel
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Notifications',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('সব Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('বন্ধ'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('alerts')
                      .orderBy('createdAt', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('কোনো notification নেই',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs
                        .where((d) => !_dismissedIds.contains(d.id))
                        .toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('সব notification clear হয়েছে',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final isResolved = data['isResolved'] == true;
                        final severity = data['severity'] ?? 'medium';
                        final createdAt = data['createdAt'] != null
                            ? (data['createdAt'] as dynamic).toDate()
                            : DateTime.now();
                        final diff = DateTime.now().difference(createdAt);
                        final timeAgo = diff.inMinutes < 60
                            ? '${diff.inMinutes} মিনিট আগে'
                            : diff.inHours < 24
                                ? '${diff.inHours} ঘণ্টা আগে'
                                : '${diff.inDays} দিন আগে';

                        Color color = severity == 'critical'
                            ? Colors.red
                            : severity == 'high'
                                ? Colors.orange
                                : severity == 'medium'
                                    ? Colors.amber
                                    : Colors.green;

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            setModalState(() => _dismissedIds.add(doc.id));
                            setState(() {});
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isResolved
                                  ? Colors.grey[200]
                                  : color.withOpacity(0.15),
                              child: Icon(
                                data['type'] == 'sos'
                                    ? Icons.sos
                                    : data['type'] == 'flood'
                                        ? Icons.water
                                        : data['type'] == 'fire'
                                            ? Icons.local_fire_department
                                            : Icons.warning,
                                color: isResolved ? Colors.grey : color,
                                size: 20,
                              ),
                            ),
                            title: Text(data['title'] ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isResolved
                                        ? Colors.grey
                                        : Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(timeAgo,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    if (isResolved) ...[
                                      const SizedBox(width: 8),
                                      const Text('✅ Resolved',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                              onPressed: () {
                                setModalState(
                                    () => _dismissedIds.add(doc.id));
                                setState(() {});
                              },
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendSOS() async {
    setState(() => _sosSending = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('⚠️ Location service বন্ধ আছে!');
        setState(() => _sosSending = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('❌ Location permission দেওয়া হয়নি!');
          setState(() => _sosSending = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationName =
          await _getLocationName(position.latitude, position.longitude);

      final user = _auth.currentUser;
      String userName = 'Unknown';
      String userPhone = '';

      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? 'Unknown';
          userPhone = userDoc.data()?['phone'] ?? '';
        }
      }

      await _firestore.collection('alerts').add({
        'title': '🆘 SOS — $userName',
        'description': '$userName জরুরি সাহায্য চাইছেন! ফোন: $userPhone',
        'type': 'sos',
        'severity': 'critical',
        'location': locationName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isResolved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid ?? 'unknown',
        'createdByName': userName,
        'createdByPhone': userPhone,
      });

      setState(() => _sosSending = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('SOS পাঠানো হয়েছে!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ আপনার emergency alert সফলভাবে পাঠানো হয়েছে।'),
                const SizedBox(height: 8),
                Text('📍 Location: $locationName',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                const Text('Responder রা শীঘ্রই যোগাযোগ করবে।'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('ঠিক আছে',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _sosSending = false);
      _showSnack('❌ SOS পাঠাতে সমস্যা: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = _auth.currentUser?.email ?? '';
    final isAdmin = currentEmail == adminEmail;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          // Notification bell
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('alerts')
                .where('isResolved', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: _showNotifications,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Profile button
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),

          // Admin button
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              ),
            ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'বিপদে পড়লে SOS বাটন চাপুন!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text('Emergency? Press SOS',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 12),

            Center(
              child: _sosSending
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(height: 8),
                        Text('SOS পাঠানো হচ্ছে...',
                            style: TextStyle(color: Colors.red)),
                      ],
                    )
                  : SOSButton(onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('🆘 SOS পাঠাবেন?'),
                          content: const Text(
                            'আপনার GPS location সহ emergency alert সব responder-দের কাছে পাঠানো হবে।',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _sendSOS();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('পাঠান',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }),
            ),
            const SizedBox(height: 28),

            Text('Quick Actions', style: AppTextStyles.heading),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                CustomCard(
                  icon: Icons.map_outlined,
                  title: 'Disaster Map',
                  color: Colors.blue,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MapScreen())),
                ),
                CustomCard(
                  icon: Icons.medical_services_outlined,
                  title: 'First Aid Guide',
                  color: Colors.green,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FirstAidGuide())),
                ),
                CustomCard(
                  icon: Icons.contacts_outlined,
                  title: 'Emergency Contacts',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmergencyContacts())),
                ),
                CustomCard(
                  icon: Icons.people_outline,
                  title: 'Help Requests',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpRequestFeed())),
                ),
                CustomCard(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
                CustomCard(
                  icon: Icons.cloud,
                  title: 'আবহাওয়া',
                  color: Colors.lightBlue,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WeatherScreen())),
                ),
                CustomCard(
                  icon: Icons.cloud_outlined,
                  title: 'আবহাওয়া',
                  color: Colors.cyan,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WeatherScreen())),
                ),
                if (isAdmin)
                  CustomCard(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminDashboard())),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
