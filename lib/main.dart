import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyMap(),
    );
  }
}

class MyMap extends StatefulWidget {
  const MyMap({super.key});

  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late LatLng userPosition;
  List<Marker> markers = [];
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () => findPlaces(),
          )
        ],
      ),
      body: FutureBuilder(
          future: findUserLocation(),
          builder: (context, snapshot) {
            return GoogleMap(
              mapType: MapType.hybrid,
              markers: Set<Marker>.of(markers),
              // initialCameraPosition: _kGooglePlex,
              initialCameraPosition: CameraPosition(
                  target: snapshot.data ??
                      const LatLng(37.42796133580664, -122.085749655962),
                  zoom: 15),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            );
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<LatLng> findUserLocation() async {
    Location location = Location();
    LocationData userLocation;
    PermissionStatus hasPermission = await location.hasPermission();
    bool active = await location.serviceEnabled();
    if (hasPermission == PermissionStatus.granted && active) {
      userLocation = await location.getLocation();
      userPosition =
          LatLng(userLocation.latitude ?? 37, userLocation.longitude ?? -122);
    } else {
      userPosition = const LatLng(37.42796133580664, -122.085749655962);
    }
    return userPosition;
  }

  findPlaces() async {
    const String key = 'AIzaSyA0eFTKRrVIjWCP_xuSJFM8GZBuLT28cg4';
    const String placesUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?';
    String url = '${placesUrl}key=$key&type=restaurant&location=${userPosition.latitude},${userPosition.longitude}&radius=1000';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      showMarkers(data);
    } else {
      throw Exception('Unable to retrieve places');
    }
  }
  showMarkers(data) {
    List places = data['results'];
    markers.clear();
    places.forEach((place) {
      markers.add(Marker(
          markerId: MarkerId(place['reference']),
          position: LatLng(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']),
          infoWindow:
          InfoWindow(title: place['name'], snippet:
          place['vicinity'])));
    });
    setState(() {
      markers = markers;
    });
  }

}

