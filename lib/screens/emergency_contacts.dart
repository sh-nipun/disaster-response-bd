import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Call korar jonno
import '../utils/constants.dart';

class EmergencyContacts extends StatelessWidget {
  const EmergencyContacts({super.key});

  static const List<Map<String, String>> _contacts = [
    {
      'name': 'জাতীয় জরুরি সেবা',
      'number': '999',
      'icon': '🆘',
      'desc': 'Police, Fire, Ambulance',
    },
    {
      'name': 'ফায়ার সার্ভিস ও সিভিল ডিফেন্স',
      'number': '199',
      'icon': '🔥',
      'desc': 'আগুন ও উদ্ধার কাজ',
    },
    {
      'name': 'পুলিশ কন্ট্রোল রুম',
      'number': '100',
      'icon': '👮',
      'desc': 'আইনশৃঙ্খলা পরিস্থিতি',
    },
    {
      'name': 'অ্যাম্বুলেন্স সেবা',
      'number': '16430',
      'icon': '🚑',
      'desc': 'চিকিৎসা জরুরি সেবা',
    },
    {
      'name': 'দুর্যোগ ব্যবস্থাপনা অধিদপ্তর',
      'number': '1090',
      'icon': '⚠️',
      'desc': 'প্রাকৃতিক দুর্যোগ সংক্রান্ত',
    },
    {
      'name': 'বাংলাদেশ রেড ক্রিসেন্ট',
      'number': '01713-109999',
      'icon': '🏥',
      'desc': 'মানবিক সহায়তা',
    },
    {
      'name': 'সেনাবাহিনী সাহায্য',
      'number': '1900',
      'icon': '🪖',
      'desc': 'বড় দুর্যোগে সামরিক সহায়তা',
    },
  ];

  void _callNumber(BuildContext context, String number) {
    // Real calling er jonno url_launcher use korun:
    // final uri = Uri.parse('tel:$number');
    // launchUrl(uri);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling: $number')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = _contacts[index];
          return ListTile(
            leading: Text(c['icon']!,
                style: const TextStyle(fontSize: 28)),
            title: Text(c['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['desc']!, style: AppTextStyles.caption),
                Text(
                  c['number']!,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.call, color: Colors.green, size: 28),
              onPressed: () => _callNumber(context, c['number']!),
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
