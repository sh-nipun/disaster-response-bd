import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final LatLng _dhakaCenter = const LatLng(23.8103, 90.4125);
  LatLng? _myLocation; // actual GPS location
  bool _locationLoading = false;
  bool _isSatellite = false;
  bool _isSearching = false;
  Map<String, dynamic>? _selectedPoint;

  List<Map<String, dynamic>> _disasterPoints = [
    {
      'title': 'বন্যা এলাকা — মিরপুর',
      'desc': '৫ জন আটকা পড়েছেন, উদ্ধার দরকার',
      'lat': 23.8223,
      'lng': 90.3654,
      'type': 'flood',
      'color': Colors.blue,
      'icon': Icons.water,
      'severity': 'high',
    },
    {
      'title': 'আহত ব্যক্তি — মোহাম্মদপুর',
      'desc': 'অ্যাম্বুলেন্স দরকার, ৩ জন আহত',
      'lat': 23.7636,
      'lng': 90.3567,
      'type': 'injury',
      'color': Colors.red,
      'icon': Icons.personal_injury,
      'severity': 'critical',
    },
    {
      'title': 'Relief Camp — ডেমরা',
      'desc': 'খাবার ও পানি পাওয়া যাচ্ছে',
      'lat': 23.7104,
      'lng': 90.4728,
      'type': 'camp',
      'color': Colors.green,
      'icon': Icons.home,
      'severity': 'low',
    },
    {
      'title': 'আগুন — যাত্রাবাড়ী',
      'desc': 'ফায়ার সার্ভিস ডাকা হয়েছে',
      'lat': 23.7193,
      'lng': 90.4423,
      'type': 'fire',
      'color': Colors.orange,
      'icon': Icons.local_fire_department,
      'severity': 'critical',
    },
    {
      'title': 'ভূমিধস — চট্টগ্রাম',
      'desc': 'পাহাড়ি এলাকায় ভূমিধস, রাস্তা বন্ধ',
      'lat': 22.3569,
      'lng': 91.7832,
      'type': 'landslide',
      'color': Colors.brown,
      'icon': Icons.terrain,
      'severity': 'high',
    },
    {
      'title': 'ঘূর্ণিঝড় সতর্কতা — কক্সবাজার',
      'desc': 'উপকূলীয় এলাকায় সতর্কতা জারি',
      'lat': 21.4272,
      'lng': 92.0058,
      'type': 'cyclone',
      'color': Colors.purple,
      'icon': Icons.cyclone,
      'severity': 'high',
    },
  ];

  final List<Map<String, dynamic>> _searchPlaces = [
    {'name': 'ঢাকা', 'lat': 23.8103, 'lng': 90.4125},
    {'name': 'চট্টগ্রাম', 'lat': 22.3569, 'lng': 91.7832},
    {'name': 'সিলেট', 'lat': 24.8949, 'lng': 91.8687},
    {'name': 'রাজশাহী', 'lat': 24.3636, 'lng': 88.6241},
    {'name': 'খুলনা', 'lat': 22.8456, 'lng': 89.5403},
    {'name': 'কক্সবাজার', 'lat': 21.4272, 'lng': 92.0058},
    {'name': 'মিরপুর, ঢাকা', 'lat': 23.8223, 'lng': 90.3654},
    {'name': 'মোহাম্মদপুর, ঢাকা', 'lat': 23.7636, 'lng': 90.3567},
  ];

  List<Map<String, dynamic>> _filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    _getMyLocation(); // App খুললেই location নেওয়া শুরু হবে
  }

  // ===== REAL GPS LOCATION =====
  Future<void> _getMyLocation() async {
    setState(() => _locationLoading = true);

    try {
      // Location service চালু আছে কিনা check করো
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('⚠️ Location service বন্ধ আছে। চালু করুন।');
        setState(() => _locationLoading = false);
        return;
      }

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('❌ Location permission দেওয়া হয়নি।');
          setState(() => _locationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('❌ Permission permanently denied। Settings থেকে চালু করুন।');
        setState(() => _locationLoading = false);
        return;
      }

      // Actual GPS location নাও
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });

      // Map এ আমার location এ zoom করো
      _mapController.move(_myLocation!, 15.0);
      _showSnack('✅ আপনার location পাওয়া গেছে!');
    } catch (e) {
      setState(() => _locationLoading = false);
      _showSnack('❌ Location পাওয়া যায়নি: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPlaces = []);
      return;
    }
    setState(() {
      _filteredPlaces = _searchPlaces
          .where((p) => p['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _goToPlace(Map<String, dynamic> place) {
    _mapController.move(LatLng(place['lat'], place['lng']), 13.0);
    _searchController.clear();
    setState(() {
      _filteredPlaces = [];
      _isSearching = false;
    });
  }

  void _addNewMarker(LatLng point) {
    showDialog(
      context: context,
      builder: (_) {
        String selectedType = 'flood';
        final titleController = TextEditingController();
        final descController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('নতুন Disaster Report'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'শিরোনাম',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'বিবরণ',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'ধরন',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'flood', child: Text('🌊 বন্যা')),
                      DropdownMenuItem(value: 'fire', child: Text('🔥 আগুন')),
                      DropdownMenuItem(value: 'injury', child: Text('🏥 আহত')),
                      DropdownMenuItem(value: 'camp', child: Text('🏠 Relief Camp')),
                      DropdownMenuItem(value: 'cyclone', child: Text('🌀 ঘূর্ণিঝড়')),
                      DropdownMenuItem(value: 'landslide', child: Text('⛰️ ভূমিধস')),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedType = val!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  if (titleController.text.isEmpty) return;
                  setState(() {
                    _disasterPoints.add({
                      'title': titleController.text,
                      'desc': descController.text,
                      'lat': point.latitude,
                      'lng': point.longitude,
                      'type': selectedType,
                      'color': _typeColor(selectedType),
                      'icon': _typeIcon(selectedType),
                      'severity': 'medium',
                    });
                  });
                  Navigator.pop(context);
                  _showSnack('✅ Marker যোগ হয়েছে!');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('যোগ করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'flood': return Colors.blue;
      case 'fire': return Colors.orange;
      case 'injury': return Colors.red;
      case 'camp': return Colors.green;
      case 'cyclone': return Colors.purple;
      case 'landslide': return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'flood': return Icons.water;
      case 'fire': return Icons.local_fire_department;
      case 'injury': return Icons.personal_injury;
      case 'camp': return Icons.home;
      case 'cyclone': return Icons.cyclone;
      case 'landslide': return Icons.terrain;
      default: return Icons.warning;
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
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredPlaces = [];
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: Colors.white),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ===== MAP =====
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dhakaCenter,
              initialZoom: 7.0,
              maxZoom: 18.0,
              minZoom: 4.0,
              onTap: (_, __) => setState(() => _selectedPoint = null),
              onLongPress: (_, latLng) => _addNewMarker(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.disaster.response.bd',
              ),

              // Disaster markers
              MarkerLayer(
                markers: _disasterPoints.map((point) {
                  return Marker(
                    point: LatLng(point['lat'], point['lng']),
                    width: 52,
                    height: 52,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPoint = point),
                      child: Container(
                        decoration: BoxDecoration(
                          color: point['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedPoint == point ? Colors.yellow : Colors.white,
                            width: _selectedPoint == point ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (point['color'] as Color).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(point['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ===== আমার ACTUAL location marker =====
              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulse ring
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          // Inner dot
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
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
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  _legendItem(Colors.blue, '🔵', 'আমার Location'),
                  _legendItem(Colors.blue, '🌊', 'বন্যা'),
                  _legendItem(Colors.red, '🏥', 'আহত'),
                  _legendItem(Colors.green, '🏠', 'Relief Camp'),
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
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📌 Long press = Marker যোগ',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

          // Location loading indicator
          if (_locationLoading)
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Location খোঁজা হচ্ছে...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // Selected point info card
          if (_selectedPoint != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _selectedPoint!['color'] as Color,
                          child: Icon(_selectedPoint!['icon'] as IconData, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedPoint!['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedPoint = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedPoint!['desc'],
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _mapController.move(
                              LatLng(_selectedPoint!['lat'], _selectedPoint!['lng']), 15.0),
                            icon: const Icon(Icons.zoom_in, size: 16),
                            label: const Text('Zoom'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showSnack('✅ Response পাঠানো হয়েছে!'),
                            icon: const Icon(Icons.volunteer_activism, size: 16, color: Colors.white),
                            label: const Text('Respond', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'my_loc',
            onPressed: _getMyLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: _locationLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zin',
            onPressed: () => _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom + 1),
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.add, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zout',
            onPressed: () => _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom - 1),
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.remove, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}