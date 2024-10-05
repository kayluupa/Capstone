import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/no_internet.dart';

class MapScreen extends StatefulWidget {
  final String name;
  final double latitude;
  final double longitude;

  const MapScreen(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.name});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  void _addMarkers() {
    setState(() {
      _markers.add(
        Marker(
            markerId: const MarkerId('Meeting Point'),
            position: LatLng(widget.latitude, widget.longitude),
            infoWindow: InfoWindow(title: widget.name)),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _addMarkers();
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
          List<ConnectivityResult> connectivity,
          Widget child,
        ) {
          final bool connected =
              connectivity.contains(ConnectivityResult.mobile) ||
                  connectivity.contains(ConnectivityResult.wifi);

          return connected ? _mapPage(context) : const BuildNoInternet();
        },
        child: _mapPage(context),
      ),
    );
  }

  SafeArea _mapPage(BuildContext context) {
    return SafeArea(
        child: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 12.0,
      ),
      markers: _markers,
    ));
  }
}
