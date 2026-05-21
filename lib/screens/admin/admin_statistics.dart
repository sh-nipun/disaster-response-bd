import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AdminStatistics extends StatelessWidget {
  const AdminStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistics & Reports',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disaster type breakdown
            const Text('Disaster Type Breakdown',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _disasterTypeChart(),
            const SizedBox(height: 20),

            // Monthly stats
            const Text('মাসিক Alert সংখ্যা',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _monthlyChart(),
            const SizedBox(height: 20),

            // Response time
            const Text('Response Statistics',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _responseStats(),
            const SizedBox(height: 20),

            // Area wise
            const Text('এলাকা অনুযায়ী Disaster',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _areaStats(),
          ],
        ),
      ),
    );
  }

  Widget _disasterTypeChart() {
    final data = [
      {'label': '🌊 বন্যা', 'count': 45, 'color': Colors.blue},
      {'label': '🔥 আগুন', 'count': 23, 'color': Colors.orange},
      {'label': '🏥 আহত', 'count': 67, 'color': Colors.red},
      {'label': '⛰️ ভূমিধস', 'count': 12, 'color': Colors.brown},
      {'label': '🌀 ঘূর্ণিঝড়', 'count': 8, 'color': Colors.purple},
      {'label': '🍚 খাদ্য সংকট', 'count': 34, 'color': Colors.green},
    ];
    final total = data.fold<int>(0, (sum, d) => sum + (d['count'] as int));

    return Container(
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
        children: data.map((d) {
          final pct = ((d['count'] as int) / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d['label'] as String,
                        style: const TextStyle(fontSize: 13)),
                    Text('${d['count']} ($pct%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: d['color'] as Color,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (d['count'] as int) / total,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(d['color'] as Color),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthlyChart() {
    final months = [
      {'month': 'জানু', 'count': 12},
      {'month': 'ফেব্রু', 'count': 8},
      {'month': 'মার্চ', 'count': 15},
      {'month': 'এপ্রিল', 'count': 23},
      {'month': 'মে', 'count': 45},
      {'month': 'জুন', 'count': 67},
    ];
    final maxVal = months.fold<int>(
        0, (m, d) => (d['count'] as int) > m ? (d['count'] as int) : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: months.map((m) {
          final height = ((m['count'] as int) / maxVal * 120).toDouble();
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${m['count']}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(m['month'] as String,
                  style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _responseStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('গড় Response\nসময়', '8 মিনিট', Colors.blue),
          _statItem('Resolution\nRate', '78%', Colors.green),
          _statItem('Active\nVolunteers', '45', Colors.orange),
          _statItem('Avg Daily\nAlerts', '12', Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _areaStats() {
    final areas = [
      {'area': 'মিরপুর, ঢাকা', 'count': 34, 'color': Colors.red},
      {'area': 'মোহাম্মদপুর', 'count': 28, 'color': Colors.orange},
      {'area': 'যাত্রাবাড়ী', 'count': 22, 'color': Colors.amber},
      {'area': 'চট্টগ্রাম', 'count': 45, 'color': Colors.blue},
      {'area': 'কক্সবাজার', 'count': 19, 'color': Colors.purple},
    ];

    return Container(
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
        children: areas
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            (e.value['color'] as Color).withOpacity(0.15),
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                color: e.value['color'] as Color,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e.value['area'] as String,
                              style: const TextStyle(fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (e.value['color'] as Color)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.value['count']} alerts',
                          style: TextStyle(
                              color: e.value['color'] as Color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
