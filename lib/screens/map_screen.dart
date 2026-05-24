import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _firestore = FirebaseFirestore.instance;

  final LatLng _dhakaCenter = const LatLng(23.8103, 90.4125);
  LatLng? _myLocation;
  bool _locationLoading = false;
  bool _isSatellite = false;
  bool _isSearching = false;
  Map<String, dynamic>? _selectedAlert;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPlaces = [];

  final List<Map<String, dynamic>> _searchPlaces = [
    {'name': 'ঢাকা', 'lat': 23.8103, 'lng': 90.4125},
    {'name': 'চট্টগ্রাম', 'lat': 22.3569, 'lng': 91.7832},
    {'name': 'সিলেট', 'lat': 24.8949, 'lng': 91.8687},
    {'name': 'রাজশাহী', 'lat': 24.3636, 'lng': 88.6241},
    {'name': 'খুলনা', 'lat': 22.8456, 'lng': 89.5403},
    {'name': 'কক্সবাজার', 'lat': 21.4272, 'lng': 92.0058},
    {'name': 'গাজীপুর', 'lat': 23.9999, 'lng': 90.4203},
    {'name': 'নারায়ণগঞ্জ', 'lat': 23.6238, 'lng': 90.4990},
  ];

  @override
  void initState() {
    super.initState();
    _getMyLocation();
  }

  Future<void> _getMyLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locationLoading = false); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { setState(() => _locationLoading = false); return; }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });
      _mapController.move(_myLocation!, 12.0);
    } catch (e) {
      setState(() => _locationLoading = false);
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) { setState(() => _filteredPlaces = []); return; }
    setState(() {
      _filteredPlaces = _searchPlaces.where((p) => p['name'].toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _goToPlace(Map<String, dynamic> place) {
    _mapController.move(LatLng(place['lat'], place['lng']), 13.0);
    _searchController.clear();
    setState(() { _filteredPlaces = []; _isSearching = false; });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'sos': return Colors.red;
      case 'flood': return Colors.blue;
      case 'fire': return Colors.orange;
      case 'injury': return Colors.pink;
      case 'cyclone': return Colors.purple;
      case 'landslide': return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'sos': return Icons.sos;
      case 'flood': return Icons.water;
      case 'fire': return Icons.local_fire_department;
      case 'injury': return Icons.personal_injury;
      case 'cyclone': return Icons.cyclone;
      case 'landslide': return Icons.terrain;
      default: return Icons.warning;
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'sos': return '🆘';
      case 'flood': return '🌊';
      case 'fire': return '🔥';
      case 'injury': return '🏥';
      case 'cyclone': return '🌀';
      case 'landslide': return '⛰️';
      default: return '⚠️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'শহর বা এলাকা খুঁজুন...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('Disaster Map', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) { _searchController.clear(); _filteredPlaces = []; }
            }),
          ),
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: Colors.white),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ===== MAP with real Firebase data =====
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('alerts')
                .where('isResolved', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final alerts = snapshot.data?.docs ?? [];

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _dhakaCenter,
                  initialZoom: 7.0,
                  maxZoom: 18.0,
                  minZoom: 4.0,
                  onTap: (_, __) => setState(() => _selectedAlert = null),
                  onLongPress: (_, latLng) => _showAddAlertDialog(latLng),
                ),
                children: [
                  // Map tiles
                  TileLayer(
                    urlTemplate: _isSatellite
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.disaster.response.bd',
                  ),

                  // Firebase alerts markers
                  MarkerLayer(
                    markers: alerts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final lat = (data['latitude'] ?? 0.0).toDouble();
                      final lng = (data['longitude'] ?? 0.0).toDouble();
                      if (lat == 0.0 && lng == 0.0) return null;

                      final type = data['type'] ?? 'other';
                      final color = _typeColor(type);
                      final isSelected = _selectedAlert?['id'] == doc.id;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        child: GestureDetector(
                          onTap: () {
                            final alertData = Map<String, dynamic>.from(data);
                            alertData['id'] = doc.id;
                            setState(() => _selectedAlert = alertData);
                            _mapController.move(LatLng(lat, lng), 14.0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.yellow : Colors.white,
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: isSelected ? 14 : 8, spreadRadius: isSelected ? 4 : 2)],
                            ),
                            child: Icon(_typeIcon(type), color: Colors.white, size: isSelected ? 28 : 22),
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  ),

                  // My location marker
                  if (_myLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _myLocation!,
                        width: 60, height: 60,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.2))),
                          Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)])),
                        ]),
                      ),
                    ]),
                ],
              );
            },
          ),

          // Search results
          if (_filteredPlaces.isNotEmpty)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredPlaces.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(_filteredPlaces[i]['name']),
                    onTap: () => _goToPlace(_filteredPlaces[i]),
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  _legendItem(Colors.blue, '🔵', 'আমার Location'),
                  _legendItem(Colors.red, '🆘', 'SOS'),
                  _legendItem(Colors.blue, '🌊', 'বন্যা'),
                  _legendItem(Colors.pink, '🏥', 'আহত'),
                  _legendItem(Colors.orange, '🔥', 'আগুন'),
                  _legendItem(Colors.purple, '🌀', 'ঘূর্ণিঝড়'),
                  _legendItem(Colors.brown, '⛰️', 'ভূমিধস'),
                ],
              ),
            ),
          ),

          // Long press hint
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
              child: const Text('📌 Long press = Marker যোগ', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),

          // Location loading
          if (_locationLoading)
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Location খোঁজা হচ্ছে...', style: TextStyle(color: Colors.white)),
                ]),
              )),
            ),

          // Selected alert popup
          if (_selectedAlert != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: _typeColor(_selectedAlert!['type'] ?? 'other').withOpacity(0.15),
                        child: Text(_typeEmoji(_selectedAlert!['type'] ?? 'other'), style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_selectedAlert!['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if ((_selectedAlert!['location'] ?? '').isNotEmpty)
                          Text('📍 ${_selectedAlert!['location']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ])),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedAlert = null)),
                    ]),
                    if ((_selectedAlert!['description'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_selectedAlert!['description'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _mapController.move(
                          LatLng((_selectedAlert!['latitude'] ?? 0).toDouble(), (_selectedAlert!['longitude'] ?? 0).toDouble()), 16.0),
                        icon: const Icon(Icons.zoom_in, size: 16),
                        label: const Text('Zoom'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () async {
                          await _firestore.collection('alerts').doc(_selectedAlert!['id']).update({'isResolved': true, 'respondedAt': FieldValue.serverTimestamp()});
                          setState(() => _selectedAlert = null);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Resolved!'), backgroundColor: Colors.green));
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Respond', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
        ],
      ),

      // FAB buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'my_loc',
            onPressed: _getMyLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: _locationLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zin',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            backgroundColor: Colors.white, mini: true,
            child: const Icon(Icons.add, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zout',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            backgroundColor: Colors.white, mini: true,
            child: const Icon(Icons.remove, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showAddAlertDialog(LatLng point) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'flood';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('নতুন Alert যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'শিরোনাম *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'বিবরণ', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'ধরন', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'flood', child: Text('🌊 বন্যা')),
                  DropdownMenuItem(value: 'fire', child: Text('🔥 আগুন')),
                  DropdownMenuItem(value: 'injury', child: Text('🏥 আহত')),
                  DropdownMenuItem(value: 'cyclone', child: Text('🌀 ঘূর্ণিঝড়')),
                  DropdownMenuItem(value: 'landslide', child: Text('⛰️ ভূমিধস')),
                ],
                onChanged: (v) => setStateDialog(() => selectedType = v!),
              ),
              const SizedBox(height: 8),
              Text('📍 Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await _firestore.collection('alerts').add({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'type': selectedType,
                  'severity': 'high',
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                  'location': 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}',
                  'isResolved': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': 'map_user',
                });
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Alert যোগ হয়েছে!'), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('যোগ করুন', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]),
    );
  }
}