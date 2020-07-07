import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsView extends StatefulWidget {
  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends State<GoogleMapsView> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(47.823995, 13.023349),
          zoom: 19
        ),
        onMapCreated: (map) {},
        markers: _createMarker(),
      ),
    );;
  }

  Set<Marker> _createMarker() {
    return <Marker> [
      Marker(
        markerId: MarkerId("01"),
        position: LatLng(47.823995, 13.023349),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
      )
    ].toSet();
  }
}