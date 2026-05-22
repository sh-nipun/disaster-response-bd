import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../utils/constants.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const String _apiKey = '227e40724982d951d8097716d45243a0';

  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _forecast;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _error = ''; });

    try {
      double lat = 23.8103;
      double lng = 90.4125;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) { /* Default Dhaka */ }

      final weatherRes = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=en',
      ));
      final forecastRes = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=en&cnt=5',
      ));

      if (weatherRes.statusCode == 200 && forecastRes.statusCode == 200) {
        setState(() {
          _weather = json.decode(weatherRes.body);
          _forecast = json.decode(forecastRes.body);
          _locationName = _weather!['name'] ?? 'আপনার এলাকা';
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Weather data পাওয়া যায়নি'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Internet connection check করুন'; _isLoading = false; });
    }
  }

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.cloud;
      case 'rain': return Icons.water_drop;
      case 'drizzle': return Icons.grain;
      case 'thunderstorm': return Icons.thunderstorm;
      case 'snow': return Icons.ac_unit;
      case 'mist': case 'fog': case 'haze': return Icons.foggy;
      default: return Icons.wb_cloudy;
    }
  }

  Color _weatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Colors.orange;
      case 'clouds': return Colors.blueGrey;
      case 'rain': return Colors.blue;
      case 'drizzle': return Colors.lightBlue;
      case 'thunderstorm': return Colors.deepPurple;
      case 'snow': return Colors.lightBlue;
      default: return Colors.blueGrey;
    }
  }

  List<Map<String, dynamic>> _getWarnings() {
    if (_weather == null) return [];
    final warnings = <Map<String, dynamic>>[];
    final condition = _weather!['weather'][0]['main'];
    final windSpeed = (_weather!['wind']['speed'] as num).toDouble();
    final temp = (_weather!['main']['temp'] as num).toDouble();
    final humidity = (_weather!['main']['humidity'] as num).toInt();

    if (condition == 'Thunderstorm') {
      warnings.add({'title': '⚡ বজ্রঝড় সতর্কতা', 'desc': 'বজ্রপাতের সম্ভাবনা। খোলা জায়গায় থাকবেন না।', 'color': Colors.deepPurple});
    }
    if (condition == 'Rain' || condition == 'Drizzle') {
      warnings.add({'title': '🌧️ বৃষ্টির সতর্কতা', 'desc': 'ভারী বৃষ্টির কারণে বন্যার সম্ভাবনা থাকতে পারে।', 'color': Colors.blue});
    }
    if (windSpeed > 10) {
      warnings.add({'title': '💨 ঝড়ো হাওয়া', 'desc': 'বাতাসের গতি ${windSpeed.toStringAsFixed(1)} m/s। সাবধান থাকুন।', 'color': Colors.orange});
    }
    if (temp > 38) {
      warnings.add({'title': '🌡️ তাপপ্রবাহ', 'desc': 'তাপমাত্রা ${temp.toStringAsFixed(0)}°C। বেশি পানি পান করুন।', 'color': Colors.red});
    }
    if (humidity > 90) {
      warnings.add({'title': '💧 উচ্চ আর্দ্রতা', 'desc': 'আর্দ্রতা $humidity%। স্বাস্থ্য সতর্কতা জরুরি।', 'color': Colors.teal});
    }
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আবহাওয়া সতর্কতা', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadWeather),
        ],
      ),
      body: _isLoading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('আবহাওয়া তথ্য লোড হচ্ছে...')]))
          : _error.isNotEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadWeather, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('আবার চেষ্টা করুন', style: TextStyle(color: Colors.white))),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main weather card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_weatherColor(_weather!['weather'][0]['main']), _weatherColor(_weather!['weather'][0]['main']).withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📍 $_locationName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                    Text('${(_weather!['main']['temp'] as num).toStringAsFixed(0)}°C', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                                    Text(_weather!['weather'][0]['description'], style: const TextStyle(color: Colors.white, fontSize: 18)),
                                  ],
                                ),
                                Icon(_weatherIcon(_weather!['weather'][0]['main']), size: 80, color: Colors.white),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _infoChip(Icons.water_drop, '${_weather!['main']['humidity']}%', 'আর্দ্রতা'),
                                _infoChip(Icons.air, '${(_weather!['wind']['speed'] as num).toStringAsFixed(1)} m/s', 'বায়ু'),
                                _infoChip(Icons.thermostat, '${(_weather!['main']['feels_like'] as num).toStringAsFixed(0)}°C', 'অনুভূতি'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Warnings
                      if (_getWarnings().isNotEmpty) ...[
                        const Text('⚠️ দুর্যোগ সতর্কতা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._getWarnings().map((w) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (w['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: (w['color'] as Color).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: w['color'] as Color),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w['title'], style: TextStyle(fontWeight: FontWeight.bold, color: w['color'] as Color)),
                                  Text(w['desc'], style: const TextStyle(fontSize: 12)),
                                ],
                              )),
                            ],
                          ),
                        )),
                        const SizedBox(height: 8),
                      ],

                      if (_getWarnings().isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.4))),
                          child: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 12), Text('✅ কোনো দুর্যোগ সতর্কতা নেই', style: TextStyle(fontWeight: FontWeight.w500))]),
                        ),
                      const SizedBox(height: 16),

                      // Forecast
                      const Text('আগামী কয়েক ঘণ্টা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _forecast!['list'].length,
                          itemBuilder: (_, i) {
                            final item = _forecast!['list'][i];
                            final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
                            final temp = (item['main']['temp'] as num).toStringAsFixed(0);
                            final condition = item['weather'][0]['main'];
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${time.hour}:00', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Icon(_weatherIcon(condition), color: _weatherColor(condition), size: 28),
                                  const SizedBox(height: 4),
                                  Text('$temp°C', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('বিস্তারিত তথ্য', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _detailRow('সর্বোচ্চ তাপমাত্রা', '${(_weather!['main']['temp_max'] as num).toStringAsFixed(0)}°C'),
                            _detailRow('সর্বনিম্ন তাপমাত্রা', '${(_weather!['main']['temp_min'] as num).toStringAsFixed(0)}°C'),
                            _detailRow('বায়ুচাপ', '${_weather!['main']['pressure']} hPa'),
                            _detailRow('দৃশ্যমানতা', '${((_weather!['visibility'] as num) / 1000).toStringAsFixed(1)} km'),
                            _detailRow('মেঘাচ্ছন্নতা', '${_weather!['clouds']['all']}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
