import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {}; // Pour stocker l'itinéraire
  LatLng? currentLocation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Méthode pour tracer l'itinéraire
  Future<void> _getDirections(LatLng destination) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${currentLocation!.latitude},${currentLocation!.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=AIzaSyC_o9DCqv45LBSrHjPHX0Py0-O0Wt4PuTc',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'].isNotEmpty) {
          // Décoder le polyline
          String encodedPoints =
              data['routes'][0]['overview_polyline']['points'];
          List<LatLng> decodedPoints = _decodePolyline(encodedPoints);

          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Colors.blue,
                width: 5,
              ),
            );
          });

          // Ajuster la caméra pour voir tout l'itinéraire
          LatLngBounds bounds = _boundsFromLatLngList(decodedPoints);
          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du calcul de l\'itinéraire')),
      );
    }

    setState(() => isLoading = false);
  }

  // Méthode pour décoder le polyline encodé retourné par l'API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Méthode pour calculer les limites de la carte pour afficher tout l'itinéraire
  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Future<void> _findNearestPlace(String placeType) async {
    if (currentLocation == null) return;

    setState(() => isLoading = true);
    markers.clear();
    polylines.clear(); // Effacer l'ancien itinéraire

    // Ajouter le marqueur de position actuelle
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLocation!,
        infoWindow: const InfoWindow(title: 'My Location'),
      ),
    );

    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${currentLocation!.latitude},${currentLocation!.longitude}'
        '&radius=5000&type=$placeType&key=AIzaSyC_o9DCqv45LBSrHjPHX0Py0-O0Wt4PuTc',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          for (var place in data['results']) {
            final location = LatLng(
              place['geometry']['location']['lat'],
              place['geometry']['location']['lng'],
            );

            markers.add(
              Marker(
                markerId: MarkerId(place['place_id']),
                position: location,
                infoWindow: InfoWindow(title: place['name']),
                onTap: () => _getDirections(location),
              ),
            );
          }

          final firstPlaceLocation = LatLng(
            data['results'][0]['geometry']['location']['lat'],
            data['results'][0]['geometry']['location']['lng'],
          );
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(firstPlaceLocation, 14),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la recherche.')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          currentLocation == null
              ? const Center(child: Text('Loading the map...'))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentLocation!,
                    zoom: 14,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => mapController = controller,
                ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              children: [
                _buildOptionCard(
                  'Find the nearest restaurant',
                  Icons.restaurant,
                  Colors.orange,
                  () => _findNearestPlace('restaurant'),
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  'Find the nearest dietitian',
                  Icons.local_hospital,
                  Colors.red,
                  () => _findNearestPlace('cabinet diététique'),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentLocation != null) {
            mapController.animateCamera(
              CameraUpdate.newLatLngZoom(currentLocation!, 14),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Permission.location.request();

    if (permission.isGranted) {
      setState(() => isLoading = true);
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
          markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: currentLocation!,
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de géolocalisation')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Widget _buildOptionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
