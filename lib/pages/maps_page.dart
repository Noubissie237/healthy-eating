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
  LatLng? currentLocation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
              infoWindow: const InfoWindow(title: 'Ma position'),
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

  Future<void> _findNearestPlace(String placeType) async {
    if (currentLocation == null) return;

    setState(() => isLoading = true);
    markers.clear();

    // Ajouter le marqueur de position actuelle
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLocation!,
        infoWindow: const InfoWindow(title: 'Ma position'),
      ),
    );

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${currentLocation!.latitude},${currentLocation!.longitude}'
          '&radius=5000&type=$placeType&key=AIzaSyC63KBS5ACnWB3BRRlS9-OWX1zLHti7BBg'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final place = data['results'][0];
          final location = LatLng(
            place['geometry']['location']['lat'],
            place['geometry']['location']['lng'],
          );

          markers.add(
            Marker(
              markerId: MarkerId(place['place_id']),
              position: location,
              infoWindow: InfoWindow(title: place['name']),
            ),
          );

          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(location, 14),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while searching')),
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
                  'Order from the nearest restaurant',
                  Icons.restaurant,
                  Colors.orange,
                  () => _findNearestPlace('restaurant'),
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  'Find the nearest dietitian',
                  Icons.local_hospital,
                  Colors.red,
                  () => _findNearestPlace('hospital'),
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
