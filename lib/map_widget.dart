import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cliffdiver/new_spot_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'shared/ratingbar.dart';
import 'package:cliffdiver/spot_detail.dart';

class MapUI extends StatefulWidget {
  @override
  _MapState createState() {
    return _MapState();
  }
}

class _MapState extends State<MapUI> {
  final String _cliffIconPath = 'assets/klippe-marker.png';
  final String _towerIconPath = 'assets/tower-marker.png';
  Completer<GoogleMapController> _controller = Completer();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var spots = [];
  GoogleMapController googleMapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  static final CameraPosition _kLake = CameraPosition(
      bearing: 0.0, target: LatLng(51.9482, 10.26517), tilt: 0.0, zoom: 5);

  void setCustomMapPin() async {
    //ByteData bytes = await rootBundle.load('assets/klippe-marker.png');

    Image.asset('assets/klippe-marker.png', width: 106, height: 106);
  }

  double _rating = 1.3;
  double pinPillPosition = -150;
  PinInformation currentlySelectedPin = PinInformation(
      docID: '',
      avatarPath: '',
      location: LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey,
      pinPath: 'assets/klippe-marker.png',
      rating: 0.0);

  void openDetails(pageId) {}

  void initState() {
    super.initState();
    _fetchMarkers();
  }

  success(pos) {
    try {} catch (ex) {}
  }

/**
 * Navigate to Create new Spot subpage, once the user has clicked the FAB to add
 * a new spot.
 */
  _addSpot() async {
    setCustomMapPin();
    final DocumentReference resultDoc = await Navigator.of(context)
        .push(new MaterialPageRoute(builder: (context) {
      return new NewSpot();
    }));
    final DocumentSnapshot spotSnap = await resultDoc.get();
    final spotData = spotSnap.data();
    initMarker(spotData, spotSnap.id, spotSnap);
  }

/**
 * Fetch all available markers from Firebase Database and call initMarker to
 * create a market for each of them.
 */
  _fetchMarkers() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireSpots = firestore.collection('Spots');
    spots = [];
    var spotdata;
    fireSpots.get().then((docList) {
      if (docList.docs.isNotEmpty) {
        for (int i = 0; i < docList.docs.length; i++) {
          spotdata = docList.docs[i].data();
          spots.add(spotdata);
          initMarker(spotdata, docList.docs[i].id, docList.docs[i]);
        }
      }
    });
  }

/**
 * Create a new marker in the Google Maps based on a single marker passed via parameters
 * The marker will be referenceable using a new created MarkerID based on the DocID
 * passed.
 * 
 * In order to create our map view, we are creating two different marker information.
 * The Marker object is used to place the pin on the google maps and is based on the 
 * google maps flutter api.
 * The PinInformation is used for the top information banner that is displayed when
 * clicking on a marker.
 */
  initMarker(spot, docID, DocumentSnapshot docSnap) async {
    var coord = spot['coordinates'];
    String iconPath;
    BitmapDescriptor icon;
    if (spot['cliff'] == true) {
      iconPath = _cliffIconPath;
      icon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, _cliffIconPath);
    } else {
      iconPath = _towerIconPath;
      icon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, _towerIconPath);
    }
    var position = LatLng(coord.latitude, coord.longitude);
    var spotmarker = new Marker(
        position: position,
        markerId: MarkerId(docID),
        icon: icon,
        onTap: () {
          var pinInfo = PinInformation(
            locationName: spot['title'],
            location: LatLng(
                spot['coordinates'].latitude, spot['coordinates'].longitude),
            docID: docID,
            avatarPath: spot['imageUrl'],
            address: spot['address'],
            rating: spot['rating'],
            labelColor: Colors.blueAccent,
            spot: docSnap,
            pinPath: iconPath,
          );
          setState(() {
            currentlySelectedPin = pinInfo;
            _rating = spot['rating'];
            pinPillPosition = 0;
          });
        });
    setState(() {
      markers.putIfAbsent(MarkerId(docID), () => spotmarker);
    });
  }

/**
 * Create the widget, which is displayed on the user screen.
 * Main components are a Google Map displaying all cliffdiving spots and
 * a button so the user can create a new spot.
 */
  @override
  Widget build(BuildContext context) => Scaffold(
      key: _scaffoldKey,
      body: Stack(children: <Widget>[
        Positioned.fill(
          child: GoogleMap(
            markers: Set<Marker>.of(markers.values),
            initialCameraPosition: _kLake,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              controller = controller;
            },
            onTap: (location) {
              setState(() {
                pinPillPosition = -100;
              });
            },
          ),
        ),
        Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _addSpot(),
              tooltip: 'Add new Spot to Database',
              icon: Icon(Icons.add),
              label: Text('Add Spot'),
            )),
        AnimatedPositioned(
            top: pinPillPosition,
            right: 0,
            left: 0,
            duration: Duration(milliseconds: 200),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(new MaterialPageRoute(builder: (context) {
                    return new SpotDetail(
                        spot: currentlySelectedPin.spot,
                        spotID: currentlySelectedPin.docID);
                  }));
                },
                child: Container(
                  margin: EdgeInsets.all(20),
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            blurRadius: 20,
                            offset: Offset.zero,
                            color: Colors.grey.withOpacity(0.5))
                      ]),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(left: 10),
                            width: 50,
                            height: 50,
                            child: ClipOval(
                                child: Image.asset(currentlySelectedPin.pinPath,
                                    fit: BoxFit.cover))),
                        Expanded(
                            child: Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(currentlySelectedPin.locationName,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            color:
                                                currentlySelectedPin.labelColor,
                                          )),
                                      StarRating(
                                        rating: _rating,
                                        color: Colors.amber,
                                      ),
                                      Text('${currentlySelectedPin.address}',
                                          maxLines: 1,
                                          style: TextStyle(color: Colors.grey)),
                                    ]))),
                        Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.chevron_right,
                              size: 50,
                            ))
                      ]),
                ),
              ),
            )),
      ]));
}

/**
 * This data model helps us create the top banner that appears when the user clicks
 * on a marker. Additionally we can use this information to navigate between the
 * detail page and the overview.
 */
class PinInformation {
  String docID;
  String avatarPath;
  LatLng location;
  String locationName;
  Color labelColor;
  String address;
  var rating;
  String pinPath;
  DocumentSnapshot spot;

  PinInformation(
      {this.docID,
      this.avatarPath,
      this.location,
      this.locationName,
      this.labelColor,
      this.address,
      this.rating,
      this.pinPath,
      this.spot});
}
