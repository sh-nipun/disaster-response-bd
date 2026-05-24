import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/constants.dart';

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({super.key});

  @override
  State<AdminStatistics> createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AdminStatistics> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  // Stats data
  int _totalUsers = 0;
  int _totalAlerts = 0;
  int _resolvedAlerts = 0;
  int _activeAlerts = 0;

  // Disaster type counts
  Map<String, int> _typeCounts = {};

  // Severity counts
  Map<String, int> _severityCounts = {};

  // User role counts
  Map<String, int> _roleCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      // Users
      final usersSnap = await _firestore.collection('users').get();
      _totalUsers = usersSnap.docs.length;

      // Role counts
      _roleCounts = {'victim': 0, 'volunteer': 0, 'responder': 0, 'admin': 0};
      for (final doc in usersSnap.docs) {
        final role = (doc.data()['role'] ?? 'victim') as String;
        _roleCounts[role] = (_roleCounts[role] ?? 0) + 1;
      }

      // Alerts
      final alertsSnap = await _firestore.collection('alerts').get();
      _totalAlerts = alertsSnap.docs.length;
      _resolvedAlerts = alertsSnap.docs
          .where((d) => d.data()['isResolved'] == true)
          .length;
      _activeAlerts = _totalAlerts - _resolvedAlerts;

      // Type counts
      _typeCounts = {};
      for (final doc in alertsSnap.docs) {
        final type = (doc.data()['type'] ?? 'other') as String;
        _typeCounts[type] = (_typeCounts[type] ?? 0) + 1;
      }

      // Severity counts
      _severityCounts = {'critical': 0, 'high': 0, 'medium': 0, 'low': 0};
      for (final doc in alertsSnap.docs) {
        final severity = (doc.data()['severity'] ?? 'low') as String;
        _severityCounts[severity] = (_severityCounts[severity] ?? 0) + 1;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistics & Reports',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _statCard('মোট Users', '$_totalUsers', Icons.people, Colors.blue),
                      _statCard('মোট Alerts', '$_totalAlerts', Icons.warning_amber, Colors.orange),
                      _statCard('Active', '$_activeAlerts', Icons.crisis_alert, Colors.red),
                      _statCard('Resolved', '$_resolvedAlerts', Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Alert type pie chart
                  const Text('Disaster Type Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _typeCounts.isEmpty
                      ? _emptyCard('কোনো alert নেই')
                      : _buildTypeChart(),
                  const SizedBox(height: 20),

                  // Severity bar chart
                  const Text('Severity অনুযায়ী Alerts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSeverityChart(),
                  const SizedBox(height: 20),

                  // User role chart
                  const Text('User Role Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRoleChart(),
                  const SizedBox(height: 20),

                  // Resolution rate
                  const Text('Resolution Rate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildResolutionRate(),
                ],
              ),
            ),
    );
  }

  // ===== Disaster Type Pie Chart =====
  Widget _buildTypeChart() {
    final colors = [
      Colors.blue, Colors.orange, Colors.red, Colors.green,
      Colors.purple, Colors.brown, Colors.teal,
    ];
    final entries = _typeCounts.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final i = e.key;
                  final entry = e.value;
                  final total = _typeCounts.values.fold(0, (a, b) => a + b);
                  final pct = total > 0 ? (entry.value / total * 100) : 0;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${pct.toStringAsFixed(0)}%',
                    color: colors[i % colors.length],
                    radius: 70,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${_typeEmoji(e.value.key)} ${e.value.key} (${e.value.value})',
                      style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== Severity Bar Chart =====
  Widget _buildSeverityChart() {
    final severities = ['critical', 'high', 'medium', 'low'];
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green];
    final maxVal = _severityCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxVal + 2).toDouble(),
            barGroups: severities.asMap().entries.map((e) {
              final val = (_severityCounts[e.value] ?? 0).toDouble();
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: val,
                    color: colors[e.key],
                    width: 32,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (val, _) => Text(
                    val.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    final labels = ['Critical', 'High', 'Medium', 'Low'];
                    return Text(
                      labels[val.toInt()],
                      style: TextStyle(
                          fontSize: 10, color: colors[val.toInt()]),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  // ===== User Role Chart =====
  Widget _buildRoleChart() {
    final roles = ['victim', 'volunteer', 'responder', 'admin'];
    final colors = [Colors.orange, Colors.green, Colors.blue, Colors.red];
    final labels = ['Victim', 'Volunteer', 'Responder', 'Admin'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: roles.asMap().entries.map((e) {
          final count = _roleCounts[e.value] ?? 0;
          final total = _totalUsers > 0 ? _totalUsers : 1;
          final pct = count / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(labels[e.key],
                        style: const TextStyle(fontSize: 13)),
                    Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors[e.key],
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(colors[e.key]),
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

  // ===== Resolution Rate =====
  Widget _buildResolutionRate() {
    final rate = _totalAlerts > 0 ? _resolvedAlerts / _totalAlerts : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rateItem('Resolution Rate',
                  '${(rate * 100).toStringAsFixed(0)}%', Colors.green),
              _rateItem('Active Alerts', '$_activeAlerts', Colors.red),
              _rateItem('Resolved', '$_resolvedAlerts', Colors.teal),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.red.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.green),
              minHeight: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('${(rate * 100).toStringAsFixed(0)}% resolved',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12))),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _rateItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Center(
          child: Text(msg, style: const TextStyle(color: Colors.grey))),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
      ],
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'flood': return '🌊';
      case 'fire': return '🔥';
      case 'injury': return '🏥';
      case 'sos': return '🆘';
      case 'food': return '🍚';
      case 'landslide': return '⛰️';
      case 'cyclone': return '🌀';
      default: return '⚠️';
    }
  }
}
