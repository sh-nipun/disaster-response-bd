// pubspec.yaml e add korun: geolocator: ^12.0.0

class LocationService {
  /// User er current location newa
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Real implementation (geolocator package dorkar):
      // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      // if (!serviceEnabled) return null;
      //
      // LocationPermission permission = await Geolocator.checkPermission();
      // if (permission == LocationPermission.denied) {
      //   permission = await Geolocator.requestPermission();
      //   if (permission == LocationPermission.denied) return null;
      // }
      //
      // Position position = await Geolocator.getCurrentPosition();
      // return {'lat': position.latitude, 'lng': position.longitude};

      // Demo - Dhaka er location
      return {'lat': 23.8103, 'lng': 90.4125};
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  /// Continuous location tracking stream
  Stream<Map<String, double>> trackLocation() {
    // return Geolocator.getPositionStream().map((pos) =>
    //   {'lat': pos.latitude, 'lng': pos.longitude});
    return Stream.empty(); // Placeholder
  }

  /// Do binder modhye distance calculate kora (meters e)
  double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return 0.0; // Placeholder
  }
}
