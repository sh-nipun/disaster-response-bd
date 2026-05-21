import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FirstAidGuide extends StatelessWidget {
  const FirstAidGuide({super.key});

  static const List<Map<String, dynamic>> _guides = [
    {
      'title': 'রক্তপাত বন্ধ করা',
      'icon': Icons.healing,
      'color': Colors.red,
      'steps': [
        'পরিষ্কার কাপড় বা ব্যান্ডেজ দিয়ে চাপ দিন',
        'আঘাতের স্থান হৃদপিণ্ডের উপরে উঁচু রাখুন',
        'কমপক্ষে ১০-১৫ মিনিট চাপ ধরে রাখুন',
        'রক্ত না থামলে দ্রুত হাসপাতালে নিয়ে যান',
      ],
    },
    {
      'title': 'পানিতে ডোবা ব্যক্তি',
      'icon': Icons.water,
      'color': Colors.blue,
      'steps': [
        'নিরাপদে পানি থেকে বের করুন',
        'শ্বাস-প্রশ্বাস চলছে কিনা দেখুন',
        'শ্বাস না থাকলে CPR শুরু করুন',
        'অ্যাম্বুলেন্স ডাকুন: 999',
      ],
    },
    {
      'title': 'আগুনে পোড়া',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
      'steps': [
        'ঠান্ডা চলমান পানি ২০ মিনিট ঢালুন',
        'বরফ বা বরফ-ঠান্ডা পানি ব্যবহার করবেন না',
        'পোড়া স্থান পরিষ্কার কাপড় দিয়ে ঢাকুন',
        'দ্রুত হাসপাতালে নিয়ে যান',
      ],
    },
    {
      'title': 'ভূমিকম্পে আটকা পড়লে',
      'icon': Icons.terrain,
      'color': Colors.brown,
      'steps': [
        'Drop (মাটিতে বসুন), Cover (মাথা ঢাকুন), Hold on',
        'শক্ত টেবিল বা বিমের নিচে আশ্রয় নিন',
        'কাঁচ ও বাইরের দেয়াল থেকে দূরে থাকুন',
        'কম্পন থামলে সিঁড়ি দিয়ে বের হন, লিফট না',
      ],
    },
    {
      'title': 'বন্যায় করণীয়',
      'icon': Icons.flood,
      'color': Colors.indigo,
      'steps': [
        'উঁচু স্থানে আশ্রয় নিন',
        'বৈদ্যুতিক সরঞ্জাম থেকে দূরে থাকুন',
        'বন্যার পানি পান করবেন না',
        'SOS signal দিন এবং সাহায্যের অপেক্ষা করুন',
      ],
    },
    {
      'title': 'CPR পদ্ধতি',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'steps': [
        'বুকের মাঝখানে দুই হাত রাখুন',
        'শক্তভাবে ৩০ বার চাপ দিন (প্রতি মিনিটে ১০০-১২০ বার)',
        'মুখে মুখ দিয়ে ২ বার শ্বাস দিন',
        'অ্যাম্বুলেন্স না আসা পর্যন্ত চালিয়ে যান',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guide',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _guides.length,
        itemBuilder: (context, index) {
          final guide = _guides[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor:
                    (guide['color'] as Color).withOpacity(0.15),
                child: Icon(guide['icon'] as IconData,
                    color: guide['color'] as Color),
              ),
              title: Text(
                guide['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: (guide['steps'] as List<String>)
                  .asMap()
                  .entries
                  .map(
                    (e) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                      title: Text(e.value, style: AppTextStyles.body),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
