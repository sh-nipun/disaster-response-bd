import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class HelpRequestFeed extends StatefulWidget {
  const HelpRequestFeed({super.key});

  @override
  State<HelpRequestFeed> createState() => _HelpRequestFeedState();
}

class _HelpRequestFeedState extends State<HelpRequestFeed> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _dismissedIds = {}; // Local এ dismiss track

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber[700]!;
      default: return Colors.green;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'flood': return Icons.water;
      case 'fire': return Icons.local_fire_department;
      case 'sos': return Icons.sos;
      case 'earthquake': return Icons.terrain;
      default: return Icons.warning;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  // Nominatim API দিয়ে location নাম — Web ও Android দুটোতেই কাজ করে
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
        ].where((p) => p != null && p.isNotEmpty).toList();
        return parts.join(', ');
      }
    } catch (e) {
      // fallback
    }
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  // Map dialog
  void _showLocationOnMap(Map<String, dynamic> data) {
    final double lat = (data['latitude'] ?? 23.8103).toDouble();
    final double lng = (data['longitude'] ?? 90.4125).toDouble();
    final String title = data['title'] ?? 'Alert';
    final String desc = data['description'] ?? '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.disaster.response.bd',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 3),
                            ],
                          ),
                          child: const Icon(Icons.sos,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<String>(
                future: _getLocationName(lat, lng),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty)
                        Text(desc,
                            style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              snapshot.data ??
                                  'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // নিজের request delete করা
  Future<void> _deleteMyRequest(String alertId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Delete করবেন?'),
        content: Text('"$title" delete করতে চান?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete করুন',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('alerts').doc(alertId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🗑️ Request delete হয়েছে!'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _respondToAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'isResolved': true,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Response পাঠানো হয়েছে!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  Future<void> _addHelpRequest() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _HelpRequestDialog(),
    );

    if (result == null) return;

    try {
      // GPS location নাও
      double lat = 23.8103;
      double lng = 90.4125;
      String locationName = 'ঢাকা';

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            lat = position.latitude;
            lng = position.longitude;

            // Location নাম বের করো
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
              ].where((p) => p != null && (p as String).isNotEmpty).toList();
              if (parts.isNotEmpty) locationName = parts.join(', ');
            }
          }
        }
      } catch (e) {
        // Location না পেলে default Dhaka
      }

      final user = _auth.currentUser;
      String userName = 'Unknown';
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? 'Unknown';
        }
      }

      await _firestore.collection('alerts').add({
        'title': result['title'],
        'description': result['description'],
        'type': result['type'],
        'severity': result['severity'],
        'latitude': lat,
        'longitude': lng,
        'location': locationName,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid ?? 'unknown',
        'createdByName': userName,
        'isResolved': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Help request পাঠানো হয়েছে! 📍 $locationName'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('alerts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('কোনো help request নেই'));
          }

          // Dismissed গুলো বাদ দাও
          final docs = snapshot.data!.docs
              .where((d) => !_dismissedIds.contains(d.id))
              .toList();

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('কোনো request নেই',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final alertId = doc.id;
              final title = data['title'] ?? 'No Title';
              final description = data['description'] ?? '';
              final type = data['type'] ?? 'other';
              final severity = data['severity'] ?? 'medium';
              final isResolved = data['isResolved'] ?? false;
              final createdAt = data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
              final hasLocation = data['latitude'] != null &&
                  data['longitude'] != null;
              final isMyRequest = data['createdBy'] == currentUid;

              return Dismissible(
                key: Key(alertId),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  setState(() => _dismissedIds.add(alertId));
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off, color: Colors.white),
                      Text('Hide', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: isResolved ? Colors.grey[100] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isResolved
                                  ? Colors.grey
                                  : _severityColor(severity),
                              radius: 18,
                              child: Icon(_typeIcon(type),
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                      ),
                                      // নিজের request — delete button
                                      if (isMyRequest)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _deleteMyRequest(alertId, title),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Delete করুন',
                                        ),
                                      // সবার জন্য — hide button
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey, size: 20),
                                        onPressed: () =>
                                            setState(() => _dismissedIds.add(alertId)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Hide করুন',
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${severity.toUpperCase()} • ${_timeAgo(createdAt)}'
                                    '${isResolved ? ' • ✅ Resolved' : ''}'
                                    '${isMyRequest ? ' • 👤 আমার' : ''}',
                                    style: TextStyle(
                                        color: isResolved
                                            ? Colors.grey
                                            : _severityColor(severity),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(description,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: hasLocation
                                  ? () => _showLocationOnMap(data)
                                  : null,
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: Text(hasLocation ? 'Map' : 'No Location'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hasLocation
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isResolved)
                              ElevatedButton.icon(
                                onPressed: () => _respondToAlert(alertId),
                                icon: const Icon(Icons.volunteer_activism,
                                    size: 16, color: Colors.white),
                                label: const Text('Respond',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHelpRequest,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Request Help',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _HelpRequestDialog extends StatefulWidget {
  @override
  State<_HelpRequestDialog> createState() => _HelpRequestDialogState();
}

class _HelpRequestDialogState extends State<_HelpRequestDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'flood';
  String _severity = 'medium';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('নতুন Help Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: 'শিরোনাম *'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'বিবরণ'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'ধরন'),
              items: const [
                DropdownMenuItem(value: 'flood', child: Text('🌊 বন্যা')),
                DropdownMenuItem(value: 'fire', child: Text('🔥 আগুন')),
                DropdownMenuItem(
                    value: 'earthquake', child: Text('🏔️ ভূমিকম্প')),
                DropdownMenuItem(
                    value: 'other', child: Text('⚠️ অন্যান্য')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(labelText: 'তীব্রতা'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                DropdownMenuItem(
                    value: 'medium', child: Text('🟡 Medium')),
                DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                DropdownMenuItem(
                    value: 'critical', child: Text('🔴 Critical')),
              ],
              onChanged: (v) => setState(() => _severity = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty) return;
            Navigator.pop(context, {
              'title': _titleController.text,
              'description': _descController.text,
              'type': _type,
              'severity': _severity,
            });
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary),
          child: const Text('পাঠান',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}