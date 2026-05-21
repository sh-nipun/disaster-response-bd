import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminAlerts extends StatefulWidget {
  const AdminAlerts({super.key});

  @override
  State<AdminAlerts> createState() => _AdminAlertsState();
}

class _AdminAlertsState extends State<AdminAlerts> {
  String _selectedSeverity = 'all';
  final _firestore = FirebaseFirestore.instance;

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber[700]!;
      default: return Colors.green;
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'flood': return '🌊';
      case 'fire': return '🔥';
      case 'injury': return '🏥';
      case 'food': return '🍚';
      case 'landslide': return '⛰️';
      case 'cyclone': return '🌀';
      default: return '⚠️';
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'অজানা সময়';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
  }

  Future<void> _resolveAlert(String id, bool currentStatus) async {
    await _firestore.collection('alerts').doc(id).update({
      'isResolved': !currentStatus,
      'resolvedAt': !currentStatus ? FieldValue.serverTimestamp() : null,
    });
    _showSnack(currentStatus ? '↩️ Alert unresolved হয়েছে' : '✅ Alert resolved হয়েছে');
  }

  Future<void> _deleteAlert(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alert Delete করবেন?'),
        content: Text('"$title" delete করতে চান?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete করুন',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('alerts').doc(id).delete();
      _showSnack('🗑️ Alert delete হয়েছে!');
    }
  }

  Future<void> _addAlert() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = 'flood';
    String selectedSeverity = 'high';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('নতুন Alert তৈরি করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      labelText: 'শিরোনাম *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'বিবরণ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                      labelText: 'এলাকা', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                      labelText: 'ধরন', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'flood', child: Text('🌊 বন্যা')),
                    DropdownMenuItem(value: 'fire', child: Text('🔥 আগুন')),
                    DropdownMenuItem(value: 'injury', child: Text('🏥 আহত')),
                    DropdownMenuItem(value: 'food', child: Text('🍚 খাদ্য সংকট')),
                    DropdownMenuItem(value: 'cyclone', child: Text('🌀 ঘূর্ণিঝড়')),
                    DropdownMenuItem(value: 'landslide', child: Text('⛰️ ভূমিধস')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(
                      labelText: 'Severity', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'critical', child: Text('🔴 Critical')),
                    DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                    DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                    DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedSeverity = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await _firestore.collection('alerts').add({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'location': locationController.text.trim(),
                  'type': selectedType,
                  'severity': selectedSeverity,
                  'isResolved': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': 'admin',
                });
                if (context.mounted) Navigator.pop(context);
                _showSnack('✅ নতুন Alert তৈরি হয়েছে!');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('তৈরি করুন',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertActions(Map<String, dynamic> data, String id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? '',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(data['description'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            Text('📍 ${data['location'] ?? ''} • 👤 ${data['createdBy'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            ListTile(
              leading: Icon(
                data['isResolved'] == true
                    ? Icons.refresh
                    : Icons.check_circle,
                color: Colors.green,
              ),
              title: Text(data['isResolved'] == true
                  ? 'Unresolved করুন'
                  : 'Resolved করুন'),
              onTap: () {
                Navigator.pop(context);
                _resolveAlert(id, data['isResolved'] == true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete করুন'),
              onTap: () {
                Navigator.pop(context);
                _deleteAlert(id, data['title'] ?? '');
              },
            ),
          ],
        ),
      ),
    );
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
        automaticallyImplyLeading: false,
        title: const Text('Alert Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'critical', 'high', 'medium', 'low', 'resolved']
                    .map((f) {
                  Color chipColor = f == 'critical'
                      ? Colors.red
                      : f == 'high'
                          ? Colors.orange
                          : f == 'medium'
                              ? Colors.amber
                              : f == 'resolved'
                                  ? Colors.green
                                  : AppColors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f == 'all' ? 'সব' : f.toUpperCase()),
                      selected: _selectedSeverity == f,
                      selectedColor: chipColor,
                      labelStyle: TextStyle(
                          color: _selectedSeverity == f
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12),
                      onSelected: (_) =>
                          setState(() => _selectedSeverity = f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Real-time alert list from Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('alerts')
                  .orderBy('createdAt', descending: true)
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
                        Icon(Icons.warning_amber, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('কোনো alert নেই',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Filter
                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedSeverity == 'all') return true;
                  if (_selectedSeverity == 'resolved') {
                    return data['isResolved'] == true;
                  }
                  return data['severity'] == _selectedSeverity &&
                      data['isResolved'] != true;
                }).toList();

                // Summary counts
                final allDocs = snapshot.data!.docs;
                final active =
                    allDocs.where((d) => (d.data() as Map)['isResolved'] != true).length;
                final critical = allDocs
                    .where((d) =>
                        (d.data() as Map)['severity'] == 'critical' &&
                        (d.data() as Map)['isResolved'] != true)
                    .length;

                return Column(
                  children: [
                    // Summary bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem('মোট', '${allDocs.length}', Colors.grey),
                          _summaryItem('Active', '$active', Colors.orange),
                          _summaryItem('Critical', '$critical', Colors.red),
                          _summaryItem('Resolved',
                              '${allDocs.length - active}', Colors.green),
                        ],
                      ),
                    ),

                    Expanded(
                      child: docs.isEmpty
                          ? const Center(child: Text('এই filter এ কোনো alert নেই'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: docs.length,
                              itemBuilder: (_, i) {
                                final data = docs[i].data() as Map<String, dynamic>;
                                final id = docs[i].id;
                                final isResolved = data['isResolved'] == true;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _showAlertActions(data, id),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Text(
                                            _typeEmoji(data['type'] ?? 'other'),
                                            style: const TextStyle(fontSize: 28),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        data['title'] ?? '',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            decoration: isResolved
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: _severityColor(
                                                                data['severity'] ??
                                                                    'low')
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        (data['severity'] ?? 'low')
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                            color: _severityColor(
                                                                data['severity'] ??
                                                                    'low'),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  data['description'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on,
                                                        size: 12,
                                                        color: Colors.grey),
                                                    Text(
                                                      data['location'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.access_time,
                                                        size: 12,
                                                        color: Colors.grey),
                                                    Text(
                                                      _timeAgo(data['createdAt']
                                                          as Timestamp?),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isResolved)
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 20),
                                        ],
                                      ),
                                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlert,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('নতুন Alert', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}