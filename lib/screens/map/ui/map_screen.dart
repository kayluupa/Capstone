import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';

class MapScreen extends StatefulWidget {
  final String latitude, longitude, title, description;

  const MapScreen(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.title,
      required this.description});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // UNT Frisco co-ordinates
  late LatLng _center = const LatLng(33.1857, -96.8054);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
          textAlign: TextAlign.center,
        ),
      ),
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          return connected ? _mapPage(context) : const BuildNoInternet();
        },
        child: const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.mainBlue,
          ),
        ),
      ),
    );
  }

  SafeArea _mapPage(BuildContext context) {
    return SafeArea(
        child: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center = LatLng(
            double.parse(widget.latitude), double.parse(widget.longitude)),
        zoom: 12.0,
      ),
      markers: {
        Marker(
            markerId: MarkerId(widget.title),
            position: LatLng(
                double.parse(widget.latitude), double.parse(widget.longitude)),
            infoWindow: InfoWindow(title: widget.description)),
      },
    ));
  }
}
