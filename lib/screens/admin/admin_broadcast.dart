import 'package:flutter/material.dart';
import '../../utils/constants.dart';

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

  final List<Map<String, dynamic>> _history = [
    {
      'title': 'বন্যা সতর্কতা',
      'message': 'মিরপুর এলাকায় বন্যার পানি বাড়ছে। সবাই সতর্ক থাকুন।',
      'target': 'সবাই',
      'type': 'warning',
      'time': '২ ঘণ্টা আগে',
      'sentTo': '1,248',
    },
    {
      'title': 'Relief Camp খোলা হয়েছে',
      'message': 'ডেমরায় নতুন relief camp খোলা হয়েছে। সাহায্য নিতে আসুন।',
      'target': 'সবাই',
      'type': 'info',
      'time': 'গতকাল',
      'sentTo': '1,248',
    },
    {
      'title': 'Volunteer Call',
      'message': 'মোহাম্মদপুরে volunteer দরকার। আগ্রহীরা যোগাযোগ করুন।',
      'target': 'Volunteers',
      'type': 'urgent',
      'time': '২ দিন আগে',
      'sentTo': '312',
    },
  ];

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

  void _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম ও বার্তা দিতে হবে!')),
      );
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate sending

    setState(() {
      _history.insert(0, {
        'title': _titleController.text,
        'message': _messageController.text,
        'target': _selectedTarget == 'all'
            ? 'সবাই'
            : _selectedTarget == 'volunteer'
                ? 'Volunteers'
                : 'Responders',
        'type': _selectedType,
        'time': 'এইমাত্র',
        'sentTo': _selectedTarget == 'all' ? '1,248' : '312',
      });
      _titleController.clear();
      _messageController.clear();
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('✅ Broadcast সফলভাবে পাঠানো হয়েছে!')),
    );
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
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('নতুন Broadcast',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'শিরোনাম *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
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

                  // Target audience
                  const Text('কাদের কাছে পাঠাবেন:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'value': 'all', 'label': '👥 সবাই'},
                      {'value': 'volunteer', 'label': '🤝 Volunteers'},
                      {'value': 'responder', 'label': '👮 Responders'},
                    ].map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t['label']!,
                              style: const TextStyle(fontSize: 12)),
                          selected: _selectedTarget == t['value'],
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: _selectedTarget == t['value']
                                  ? Colors.white
                                  : Colors.black),
                          onSelected: (_) => setState(
                              () => _selectedTarget = t['value']!),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Type
                  const Text('ধরন:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'value': 'info', 'label': 'ℹ️ Info'},
                      {'value': 'warning', 'label': '⚠️ Warning'},
                      {'value': 'urgent', 'label': '🚨 Urgent'},
                    ].map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
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
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Send button
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
                          _isSending
                              ? 'পাঠানো হচ্ছে...'
                              : 'Broadcast পাঠান',
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

            // History
            const Text('Broadcast History',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ..._history.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _typeColor(h['type']).withOpacity(0.15),
                      child: Icon(_typeIcon(h['type']),
                          color: _typeColor(h['type']), size: 20),
                    ),
                    title: Text(h['title'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h['message'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                            '📤 ${h['target']} • ${h['sentTo']} জন • ${h['time']}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
