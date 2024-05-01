import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:math';
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

double radians(double degrees) {
  return degrees * (pi / 180.0);
}

double degrees(double radians) {
  return radians * 180 / pi;
}

LatLng _calculateMidpoint(LatLng point1, LatLng point2) {
  double lat1 = radians(point1.latitude);
  double lng1 = radians(point1.longitude);
  double lat2 = radians(point2.latitude);
  double lng2 = radians(point2.longitude);

  double dLng = lng2 - lng1;
  double x = cos(lat2) * cos(dLng);
  double y = cos(lat2) * sin(dLng);
  double mLat = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y));
  double mLng = lng1 + atan2(y, cos(lat1) + x);

  return LatLng(degrees(mLat), degrees(mLng));
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  // UNT Frisco co-ordinates
  final LatLng _center = const LatLng(33.1857, -96.8054);
  //

  void _addMarkers() {
    LatLng midpoint = _calculateMidpoint(
        LatLng(double.parse(widget.latitude), double.parse(widget.longitude)),
        _center);
    setState(() {
      _markers.add(
        Marker(
            markerId: MarkerId(widget.title),
            position: LatLng(
                double.parse(widget.latitude), double.parse(widget.longitude)),
            infoWindow: InfoWindow(title: widget.description)),
      );
      _markers.add(
        Marker(
            markerId: const MarkerId("UNT Frisco"),
            position: _center,
            infoWindow: const InfoWindow(title: "Second Point")),
      );
      _markers.add(
        Marker(
            markerId: const MarkerId("Midpoint"),
            position: midpoint,
            infoWindow: const InfoWindow(title: "Midpoint")),
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
    LatLng midpoint = _calculateMidpoint(
        LatLng(double.parse(widget.latitude), double.parse(widget.longitude)),
        _center);
    return SafeArea(
        child: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: midpoint,
        zoom: 12.0,
      ),
      markers: _markers,
    ));
  }
}
