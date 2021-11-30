import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;


class MyMap extends StatefulWidget {
  final String userId;

  const MyMap({Key? key, required this.userId}) : super(key: key);

  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final loc.Location location = loc.Location();
  late GoogleMapController _controller;
  bool _added = false;

   late double currentLat = 0;
  late double currentLong = 0;
  @override
  void initState() {
    super.initState();
    _getLocation();
    _getPolyline();
  }
  Map<PolylineId, Polyline> polyLines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();


  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polyLines[id] = polyline;
    setState(() {});
  }



  _getPolyline () async {

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates('AIzaSyAJdr4In4V6QUmu3yJx4Xv5y1i9PCd1CfI',
        PointLatLng( _new.latitude, _new.longitude),
        PointLatLng(_news.latitude, _news.longitude),
      travelMode: TravelMode.driving,
  );
print('${result.errorMessage}');
    if (result.points.isNotEmpty) {
    for (var point in result.points) {
    polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    }
    _addPolyLine();
  }
  _getLocation()  async {
    _new= LatLng(currentLat,currentLong);
    try {
      setState(() async {
        final loc.LocationData _locationResult = await  location.getLocation();
        currentLat=_locationResult.latitude!;
        currentLong=_locationResult.longitude!;
      });
    } catch (e) {
      print(e);
    }
  }
  late List<LatLng> latAndLng = [_news,_new];
  late LatLng _new;
  final LatLng _news = const LatLng(33.567997728, 72.635997456);
@override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade400,
            ),
            child: IconButton(
              onPressed:
              _getPolyline,
              icon: const Icon(Icons.my_location),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('location').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (_added) {
                myMap(snapshot);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                polylines: Set<Polyline>.of(polyLines.values),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                markers: {
                  Marker(
                      position: LatLng(
                        snapshot.data!.docs.singleWhere((element) =>
                            element.id == widget.userId)['latitude'],
                        snapshot.data!.docs.singleWhere((element) =>
                            element.id == widget.userId)['longitude'],
                      ),
                      markerId: const MarkerId('id'),
                      // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta)
              ),
                   Marker(
                    markerId: const MarkerId('Current Location'),
                  position: LatLng(_news.latitude,_news.longitude),
                     icon: BitmapDescriptor.defaultMarkerWithHue(
                         BitmapDescriptor.hueRed)
                  )
                },
                initialCameraPosition: CameraPosition(
                    target: LatLng(
                      snapshot.data!.docs.singleWhere(
                          (element) => element.id == widget.userId)['latitude'],
                      snapshot.data!.docs.singleWhere(
                          (element) => element.id == widget.userId)['longitude'],
                    ),
                    zoom: 14.47),
                onMapCreated: (GoogleMapController controller) async {
                  setState(() {
                    _controller = controller;
                    _added = true;
                  });
                },
              );
            },
          )),
    );
  }

  Future<void> myMap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(
              snapshot.data!.docs.singleWhere(
                  (element) => element.id == widget.userId)['latitude'],
              snapshot.data!.docs.singleWhere(
                  (element) => element.id == widget.userId)['longitude'],
            ),
            zoom: 14.47)));
  }
}
