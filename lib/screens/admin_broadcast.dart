import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class AdminBroadcast extends StatefulWidget {
  const AdminBroadcast({super.key});

  @override
  State<AdminBroadcast> createState() => _AdminBroadcastState();
}

class _AdminBroadcastState extends State<AdminBroadcast> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'all';
  String _selectedType = 'info';
  bool _isSending = false;
  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  Color _typeColor(String type) {
    switch (type) {
      case 'warning': return Colors.orange;
      case 'urgent': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning': return Icons.warning_amber;
      case 'urgent': return Icons.crisis_alert;
      default: return Icons.info_outline;
    }
  }

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম ও বার্তা দিতে হবে!')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Firestore এ save করো
      await _firestore.collection('broadcasts').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'target': _selectedTarget,
        'type': _selectedType,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });

      // Local notification দেখাও (FCM setup হলে সবার কাছে যাবে)
      await _notificationService.showNotification(
        title: '📢 ${_titleController.text.trim()}',
        body: _messageController.text.trim(),
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      setState(() {
        _titleController.clear();
        _messageController.clear();
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Broadcast সফলভাবে পাঠানো হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Broadcast Notification',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compose section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('নতুন Broadcast',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'শিরোনাম *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'বার্তা *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Target
                  const Text('কাদের কাছে:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'value': 'all', 'label': '👥 সবাই'},
                      {'value': 'volunteer', 'label': '🤝 Volunteers'},
                      {'value': 'responder', 'label': '👮 Responders'},
                    ].map((t) {
                      return ChoiceChip(
                        label: Text(t['label']!,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedTarget == t['value'],
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: _selectedTarget == t['value']
                                ? Colors.white
                                : Colors.black),
                        onSelected: (_) =>
                            setState(() => _selectedTarget = t['value']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Type
                  const Text('ধরন:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'value': 'info', 'label': 'ℹ️ Info'},
                      {'value': 'warning', 'label': '⚠️ Warning'},
                      {'value': 'urgent', 'label': '🚨 Urgent'},
                    ].map((t) {
                      return ChoiceChip(
                        label: Text(t['label']!,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedType == t['value'],
                        selectedColor: _typeColor(t['value']!),
                        labelStyle: TextStyle(
                            color: _selectedType == t['value']
                                ? Colors.white
                                : Colors.black),
                        onSelected: (_) =>
                            setState(() => _selectedType = t['value']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendBroadcast,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                          _isSending ? 'পাঠানো হচ্ছে...' : 'Broadcast পাঠান',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Broadcast history from Firebase
            const Text('Broadcast History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('broadcasts')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('কোনো broadcast history নেই',
                      style: TextStyle(color: Colors.grey));
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _typeColor(data['type'] ?? 'info').withOpacity(0.15),
                          child: Icon(
                              _typeIcon(data['type'] ?? 'info'),
                              color: _typeColor(data['type'] ?? 'info'),
                              size: 20),
                        ),
                        title: Text(data['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['message'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                            Text(
                              '📤 ${data['target'] == 'all' ? 'সবাই' : data['target']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
