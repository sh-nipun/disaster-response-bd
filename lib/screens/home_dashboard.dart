import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import 'map_screen.dart';
import 'first_aid_guide.dart';
import 'emergency_contacts.dart';
import 'help_request_feed.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'weather_screen.dart';
import 'admin/admin_dashboard.dart';

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
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _userName = doc.data()?['name'] ?? '');
      }
    }
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json'),
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
    } catch (e) {}
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout করবেন?'),
        content: const Text('আপনি কি সত্যিই logout করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('হ্যাঁ, Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.notifications, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () { setModalState(() {}); setState(() {}); },
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('সব Clear'),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('alerts').orderBy('createdAt', descending: true).limit(20).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('কোনো notification নেই', style: TextStyle(color: Colors.grey)),
                          ],
                        ));
                      }
                      final docs = snapshot.data!.docs.where((d) => !_dismissedIds.contains(d.id)).toList();
                      if (docs.isEmpty) {
                        return Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('সব clear!', style: TextStyle(color: Colors.grey)),
                          ],
                        ));
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                        itemBuilder: (_, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final isResolved = data['isResolved'] == true;
                          final severity = data['severity'] ?? 'medium';
                          final createdAt = data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : DateTime.now();
                          final diff = DateTime.now().difference(createdAt);
                          final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : diff.inHours < 24 ? '${diff.inHours}h ago' : '${diff.inDays}d ago';
                          Color color = severity == 'critical' ? Colors.red : severity == 'high' ? Colors.orange : severity == 'medium' ? Colors.amber : Colors.green;

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) { setModalState(() => _dismissedIds.add(doc.id)); setState(() {}); },
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isResolved ? Colors.grey[200] : color.withOpacity(0.15),
                                child: Icon(data['type'] == 'sos' ? Icons.sos : data['type'] == 'flood' ? Icons.water : data['type'] == 'fire' ? Icons.local_fire_department : Icons.warning, color: isResolved ? Colors.grey : color, size: 20),
                              ),
                              title: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isResolved ? Colors.grey : Colors.black)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                Text(timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                onPressed: () { setModalState(() => _dismissedIds.add(doc.id)); setState(() {}); },
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
      ),
    );
  }

  Future<void> _sendSOS() async {
    setState(() => _sosSending = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _showSnack('⚠️ Location service বন্ধ!'); setState(() => _sosSending = false); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); }
      if (permission == LocationPermission.denied) { _showSnack('❌ Location permission নেই!'); setState(() => _sosSending = false); return; }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final locationName = await _getLocationName(position.latitude, position.longitude);
      final user = _auth.currentUser;
      String userName = 'Unknown', userPhone = '';
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) { userName = doc.data()?['name'] ?? 'Unknown'; userPhone = doc.data()?['phone'] ?? ''; }
      }

      await _firestore.collection('alerts').add({
        'title': '🆘 SOS — $userName', 'description': '$userName জরুরি সাহায্য চাইছেন! ফোন: $userPhone',
        'type': 'sos', 'severity': 'critical', 'location': locationName,
        'latitude': position.latitude, 'longitude': position.longitude,
        'isResolved': false, 'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid ?? 'unknown', 'createdByName': userName, 'createdByPhone': userPhone,
      });

      setState(() => _sosSending = false);
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 8), Text('SOS পাঠানো হয়েছে!')]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✅ আপনার emergency alert পাঠানো হয়েছে।'),
            const SizedBox(height: 8),
            Text('📍 $locationName', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Responder রা শীঘ্রই যোগাযোগ করবে।'),
          ]),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('ঠিক আছে', style: TextStyle(color: Colors.white)))],
        ));
      }
    } catch (e) {
      setState(() => _sosSending = false);
      _showSnack('❌ SOS পাঠাতে সমস্যা: $e');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final currentEmail = _auth.currentUser?.email ?? '';
    final isAdmin = currentEmail == adminEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.crisis_alert, color: Colors.white, size: 28),
                              const SizedBox(width: 8),
                              const Text('DisasterAid BD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ]),
                            Row(children: [
                              // Notification
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore.collection('alerts').where('isResolved', isEqualTo: false).snapshots(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.docs.length ?? 0;
                                  return Stack(children: [
                                    IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: _showNotifications),
                                    if (count > 0) Positioned(right: 6, top: 6, child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                                      child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                    )),
                                  ]);
                                },
                              ),
                              IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                              if (isAdmin) IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
                              IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Greeting
                        Text(
                          _userName.isNotEmpty ? 'স্বাগতম, $_userName! 👋' : 'স্বাগতম! 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text('আপনি কি নিরাপদ আছেন?', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('DisasterAid BD', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SOS Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        const Text('🆘 Emergency?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('SOS চাপলে আপনার location সহ alert যাবে', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        _sosSending
                            ? const Column(children: [CircularProgressIndicator(color: Colors.red), SizedBox(height: 8), Text('পাঠানো হচ্ছে...', style: TextStyle(color: Colors.red))])
                            : SOSButton(onPressed: () {
                                showDialog(context: context, builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('🆘 SOS পাঠাবেন?'),
                                  content: const Text('আপনার GPS location সহ emergency alert সব responder-দের কাছে পাঠানো হবে।'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () { Navigator.pop(context); _sendSOS(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('পাঠান', style: TextStyle(color: Colors.white))),
                                  ],
                                ));
                              }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active alerts banner
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('alerts').where('isResolved', isEqualTo: false).limit(1).snapshots(),
                    builder: (context, snapshot) {
                      final hasAlerts = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasAlerts ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasAlerts ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(hasAlerts ? Icons.warning_amber : Icons.check_circle, color: hasAlerts ? Colors.red : Colors.green),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            hasAlerts ? 'Active disaster alerts আছে! সতর্ক থাকুন।' : 'বর্তমানে কোনো active alert নেই।',
                            style: TextStyle(color: hasAlerts ? Colors.red[700] : Colors.green[700], fontWeight: FontWeight.w500, fontSize: 13),
                          )),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions title
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),

                  // Modern grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: [
                      _modernCard(context, '🗺️', 'Disaster\nMap', const Color(0xFF1565C0), const Color(0xFF42A5F5), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))),
                      _modernCard(context, '🏥', 'First Aid\nGuide', const Color(0xFF2E7D32), const Color(0xFF66BB6A), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAidGuide()))),
                      _modernCard(context, '📞', 'Emergency\nContacts', const Color(0xFFE65100), const Color(0xFFFF9800), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContacts()))),
                      _modernCard(context, '🆘', 'Help\nRequests', const Color(0xFF6A1B9A), const Color(0xFFAB47BC), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpRequestFeed()))),
                      _modernCard(context, '👤', 'My\nProfile', const Color(0xFF00695C), const Color(0xFF26A69A), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                      _modernCard(context, '🌤️', 'আবহাওয়া', const Color(0xFF0277BD), const Color(0xFF29B6F6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()))),
                      if (isAdmin)
                        _modernCard(context, '🛡️', 'Admin\nPanel', const Color(0xFF283593), const Color(0xFF5C6BC0), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recent alerts section
                  const Text('সাম্প্রতিক Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('alerts').orderBy('createdAt', descending: true).limit(3).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('কোনো alert নেই', style: TextStyle(color: Colors.grey))),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final severity = data['severity'] ?? 'low';
                          final isResolved = data['isResolved'] == true;
                          Color color = severity == 'critical' ? Colors.red : severity == 'high' ? Colors.orange : severity == 'medium' ? Colors.amber : Colors.green;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                            ),
                            child: Row(children: [
                              Container(width: 4, height: 40, decoration: BoxDecoration(color: isResolved ? Colors.grey : color, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(data['location'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: (isResolved ? Colors.grey : color).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(isResolved ? 'Resolved' : severity.toUpperCase(), style: TextStyle(color: isResolved ? Colors.grey : color, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernCard(BuildContext context, String emoji, String title, Color dark, Color light, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [dark, light], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: dark.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
