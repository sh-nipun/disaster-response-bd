import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AdminResources extends StatefulWidget {
  const AdminResources({super.key});

  @override
  State<AdminResources> createState() => _AdminResourcesState();
}

class _AdminResourcesState extends State<AdminResources>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _camps = [
    {
      'name': 'ডেমরা Relief Camp',
      'location': 'ডেমরা, ঢাকা',
      'capacity': 500,
      'current': 342,
      'food': 'পর্যাপ্ত',
      'water': 'পর্যাপ্ত',
      'medical': 'সীমিত',
      'status': 'active',
    },
    {
      'name': 'মিরপুর শেল্টার',
      'location': 'মিরপুর ১২, ঢাকা',
      'capacity': 300,
      'current': 289,
      'food': 'সীমিত',
      'water': 'পর্যাপ্ত',
      'medical': 'নেই',
      'status': 'critical',
    },
    {
      'name': 'চট্টগ্রাম Emergency Camp',
      'location': 'পতেঙ্গা, চট্টগ্রাম',
      'capacity': 800,
      'current': 156,
      'food': 'পর্যাপ্ত',
      'water': 'পর্যাপ্ত',
      'medical': 'পর্যাপ্ত',
      'status': 'active',
    },
  ];

  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'Rescue Team Alpha',
      'members': 12,
      'location': 'মিরপুর, ঢাকা',
      'status': 'deployed',
      'task': 'বন্যায় আটকা মানুষ উদ্ধার',
    },
    {
      'name': 'Medical Team 1',
      'members': 8,
      'location': 'মোহাম্মদপুর',
      'status': 'deployed',
      'task': 'আহতদের চিকিৎসা',
    },
    {
      'name': 'Relief Distribution Team',
      'members': 20,
      'location': 'ডেমরা Camp',
      'status': 'active',
      'task': 'খাবার ও পানি বিতরণ',
    },
    {
      'name': 'Rescue Team Beta',
      'members': 10,
      'location': 'Base (Available)',
      'status': 'available',
      'task': 'অপেক্ষায় আছে',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'critical': return Colors.red;
      case 'deployed': return Colors.blue;
      case 'available': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Resource Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Relief Camps'),
            Tab(icon: Icon(Icons.groups), text: 'Teams'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ===== CAMPS TAB =====
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _camps.length,
            itemBuilder: (_, i) {
              final camp = _camps[i];
              final occupancy = camp['current'] / camp['capacity'];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(camp['name'],
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(camp['status'])
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              camp['status'].toUpperCase(),
                              style: TextStyle(
                                  color: _statusColor(camp['status']),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('📍 ${camp['location']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),

                      // Occupancy bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Occupancy:',
                              style: TextStyle(fontSize: 12)),
                          Text(
                              '${camp['current']}/${camp['capacity']} জন',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: occupancy > 0.85
                                      ? Colors.red
                                      : Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: occupancy,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                              occupancy > 0.85 ? Colors.red : Colors.green),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Resources
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _resourceChip('🍚 খাবার', camp['food']),
                          _resourceChip('💧 পানি', camp['water']),
                          _resourceChip('💊 Medical', camp['medical']),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${camp['name']} এ সাপ্লাই পাঠানো হচ্ছে...')),
                            );
                          },
                          child: const Text('Supply পাঠান'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ===== TEAMS TAB =====
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _teams.length,
            itemBuilder: (_, i) {
              final team = _teams[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _statusColor(team['status']).withOpacity(0.15),
                    child: Icon(Icons.groups,
                        color: _statusColor(team['status'])),
                  ),
                  title: Text(team['name'],
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👥 ${team['members']} জন • 📍 ${team['location']}',
                          style: const TextStyle(fontSize: 12)),
                      Text('📋 ${team['task']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(team['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      team['status'].toUpperCase(),
                      style: TextStyle(
                          color: _statusColor(team['status']),
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('নতুন resource যোগের form আসছে...')),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('নতুন যোগ করুন',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _resourceChip(String label, String status) {
    Color color = status == 'পর্যাপ্ত'
        ? Colors.green
        : status == 'সীমিত'
            ? Colors.orange
            : Colors.red;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
