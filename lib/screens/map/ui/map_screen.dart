import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // UNT Frisco co-ordinates
  final LatLng _center = const LatLng(33.1857, -96.8054);

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
        target: _center,
        zoom: 12.0,
      ),
      markers: {
        const Marker(
            markerId: MarkerId("UNT Frisco"),
            position: LatLng(33.1857, -96.8054),
            infoWindow: InfoWindow(title: "UNT Frisco")),
      },
    ));
  }
}
