import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:cliffdiver/address_search_widget.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:cliffdiver/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:uuid/uuid.dart';

class NewSpot extends StatefulWidget {
  @override
  _NewSpotState createState() {
    return _NewSpotState();
  }
}

class _NewSpotState extends State<NewSpot> {
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  LocationResult _lr;
  bool locResReceived = false;

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  var _fileBytes;
  Image _imageWidget;

  bool _loading = false;
  bool _disableButton = false;

  bool _disableSubmit = false;

  Future<dynamic> getMultipleImageInfos() async {
    var mediaData = await ImagePickerWeb.getImageInfo;

    setState(() {
      _fileBytes = mediaData.data;
      _imageWidget = Image.memory(mediaData.data);
    });

    setState(() {
      _loading = false;
      _disableButton = false;
    });
    return _fileBytes;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireSpots = firestore.collection('Spots');
    return Scaffold(
        appBar: new AppBar(
          title: new Text("Add"),
        ),
        body: FormBuilder(
          key: _fbKey,
          initialValue: {
            'date': DateTime.now(),
            'accept_terms': false,
          },
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              FormBuilderField(
                name: "picture",
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Select a picture",
                      contentPadding: EdgeInsets.only(top: 10.0, bottom: 0.0),
                      border: InputBorder.none,
                      errorText: field.errorText,
                    ),
                    child: Container(
                        height: 200,
                        child: Center(
                            child: _imageWidget ??
                                ElevatedButton(
                                  onPressed: _disableButton
                                      ? null
                                      : () async {
                                          setState(() {
                                            _disableButton = true;
                                            _loading = true;
                                          });

                                          var result =
                                              await getMultipleImageInfos();
                                          field.didChange(result);
                                        },
                                  child: _loading
                                      ? Text("Uploading Image...")
                                      : Text("Select a Picture"),
                                ))),
                  );
                },
              ),
              Container(
                width: 50.0,
                child: FormBuilderSegmentedControl(
                    decoration:
                        InputDecoration(labelText: "Type of Diving Spot"),
                    name: "diving_type",
                    // validators: [
                    //   FormBuilderValidators.required()
                    // ],
                    options: [
                      FormBuilderFieldOption(value: true, child: Text("Cliff")),
                      FormBuilderFieldOption(value: false, child: Text("Tower"))
                    ]),
              ),
              Container(
                width: 50.0,
                child: FormBuilderSegmentedControl(
                    decoration: InputDecoration(labelText: "Difficulty"),
                    name: "diving_difficulty",
                    // validators: [
                    //   FormBuilderValidators.required()
                    // ],
                    options: [
                      FormBuilderFieldOption(value: "Beginner"),
                      FormBuilderFieldOption(value: "Intermediate"),
                      FormBuilderFieldOption(value: "Advanced")
                    ]),
              ),
              Container(
                width: 50.0,
                child: FormBuilderTextField(
                  name: "name",
                  decoration: InputDecoration(labelText: "Name of the Spot"),
                  // validators: [
                  //   FormBuilderValidators.max(70),
                  //   FormBuilderValidators.required()
                  // ],
                ),
              ),
              Container(
                width: 50.0,
                child: FormBuilderTextField(
                  name: "Description",
                  minLines: 3,
                  maxLines: 5,
                  decoration:
                      InputDecoration(labelText: "Description of the Spot"),
                  // validators: [FormBuilderValidators.required()],
                ),
              ),
              FormBuilderField(
                name: "location",
                // validators: [
                //   FormBuilderValidators.required(),
                // ],
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Select an address",
                      contentPadding: EdgeInsets.only(top: 10.0, bottom: 0.0),
                      border: InputBorder.none,
                      errorText: field.errorText,
                    ),
                    child: Container(
                      child: ListTile(
                        title: locResReceived
                            ? Text(_lr.label)
                            : Text("Select an address"),
                        subtitle: locResReceived
                            ? Text("Latitude: " +
                                _lr.latitude.toString() +
                                ", Longitude: " +
                                _lr.longitude.toString())
                            : Text("No address selected"),
                        trailing: IconButton(
                          icon: Icon(Icons.search),
                          tooltip: 'Search for an address',
                          onPressed: () async {
                            final LocationResult locRes =
                                await Navigator.of(context).push(
                                    new MaterialPageRoute(builder: (context) {
                              return new AddressSearch();
                            }));
                            if (locRes == null) {
                            } else {
                              setState(() {
                                _lr = locRes;
                                locResReceived = true;
                              });
                              field.didChange(locRes);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10.0),
              Container(
                child: ElevatedButton(
                  onPressed: _disableSubmit
                      ? null
                      : () {
                          if (_fbKey.currentState.saveAndValidate()) {
                            var uuid = Uuid();
                            String imageTitle = uuid.v4();

                            firebase_storage.Reference ref = firebase_storage
                                .FirebaseStorage.instance
                                .ref('$imageTitle');

                            ref.putData(_fileBytes).then((res) {
                              ref.getDownloadURL().then((res) {
                                fireSpots.add(<String, dynamic>{
                                  'address': _lr.label,
                                  'coordinates':
                                      GeoPoint(_lr.latitude, _lr.longitude),
                                  'imageUrl': res.toString(),
                                  'title': _fbKey.currentState.value["name"],
                                  'level': _fbKey
                                      .currentState.value["diving_difficulty"],
                                  'cliff':
                                      _fbKey.currentState.value["diving_type"],
                                  'rating': 5,
                                  'description':
                                      _fbKey.currentState.value["Description"]
                                }).then((DocumentReference doc) {
                                  setState(() {
                                    _disableSubmit = false;
                                  });
                                  Navigator.of(context).pop(doc);
                                }).catchError((err) {
                                  setState(() {
                                    _disableSubmit = false;
                                  });
                                  print(err);
                                });
                              });
                            });

                            setState(() {
                              _disableSubmit = true;
                            });
                          }
                        },
                  child: Text('Add Spot'),
                ),
              ),
              SizedBox(height: 10.0),
            ],
          ),
        ));
  }
}
