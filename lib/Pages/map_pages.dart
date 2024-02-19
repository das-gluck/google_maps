import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:maps/const.dart';



class MapPages extends StatefulWidget {
  const MapPages({Key? key}) : super(key: key);

  @override
  State<MapPages> createState() => _MapPagesState();
}

class _MapPagesState extends State<MapPages> {

  Location _locationController = Location();
  Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static const LatLng _pGooglePlex = LatLng(28.694951979616192, 77.21169639034271);
  static const LatLng _destinationPlex = LatLng(28.84550518403348, 77.57535109654474);
  LatLng? _currentPosition = null;

  Map<PolylineId, Polyline> polyline = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) => {
      getPolylinePoints().then((coordinates) => {
        generatePolylineFromPoint(coordinates),
      }),
    }) ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: Text("Loading ..."),)
          : GoogleMap(
          onMapCreated: (
              (GoogleMapController controller) => _mapController.complete(controller)
          ),
          initialCameraPosition: const CameraPosition(
            target: _pGooglePlex,
            zoom: 13,
          ),
        markers: {
           Marker(
            markerId: MarkerId("_currentLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _currentPosition!,
          ),
          Marker(
              markerId: MarkerId("_sourceLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: _pGooglePlex,
            ),
          Marker(
            markerId: MarkerId("_destinationLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _destinationPlex,
          ),
        },
        polylines: Set<Polyline>.of(polyline.values),
      )
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos,zoom: 13);
    
    await controller.animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));

  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if(_serviceEnabled){
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if(_permissionGranted == PermissionStatus.denied){
      _permissionGranted = await _locationController.requestPermission();
      if(_permissionGranted != PermissionStatus.granted){
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if(currentLocation.latitude != null && currentLocation.longitude != null){
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentPosition!);
        });
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylinesCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAPS_API_KEYS,
        PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
        PointLatLng(_destinationPlex.latitude, _destinationPlex.longitude),
      );

    if(result.points.isNotEmpty){
      result.points.forEach((PointLatLng point) {
        polylinesCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylinesCoordinates;
  }

  void generatePolylineFromPoint (List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polylines = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 8,
    );
    setState(() {
      polyline[id] = polylines;
    });

  }

}
