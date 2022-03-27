import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:cliffdiver/models/models.dart';
import 'package:mapbox_search/mapbox_search.dart';

class AddressSearch extends StatefulWidget {
  @override
  _AddressSearchState createState() => _AddressSearchState();
}

class _AddressSearchState extends State<AddressSearch> {
  static String placesApiKey = dotenv.env['PLACES_API_KEY'];
  var placesSearch = PlacesSearch(
    apiKey: placesApiKey,
    limit: 5,
  );

  bool typing = false;
  var _results = <LocationResult>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.centerLeft,
          color: Colors.white,
          child: TextField(
            onChanged: (query) {
              if (query.isNotEmpty) {
                if (query.length > 5) {
                  return placesSearch.getPlaces(query).then((places) {
                    var response = places;
                    // ignore: unused_local_variable
                    String label;
                    StringBuffer labelBuff;
                    List<LocationResult> locationResults = [];
                    for (int i = 0; i < response.length; i++) {
                      labelBuff = new StringBuffer();
                      labelBuff.write(response[i].text);
                      labelBuff.write(" (");
                      for (Context item in response[i].context) {
                        labelBuff.write(item.text);
                        labelBuff.write(" ");
                      }
                      labelBuff.write(")");
                      label = labelBuff.toString();
                      LocationResult locRes = new LocationResult(
                        label: response[i].placeName,
                        locationId: response[i].id,
                        longitude: response[i].center[0],
                        latitude: response[i].center[1],
                        address: response[i].placeName,
                      );
                      locationResults.add(locRes);
                      setState(() {
                        _results.clear();
                        _results.addAll(locationResults);
                      });
                    }
                  }).catchError((Error) {
                    log(Error.toString());
                  });
                }
              }
              return null;
            },
            decoration: InputDecoration(hintText: 'Search'),
          ),
        ),
      ),
      body: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: _results.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(
                height: 2,
                thickness: 1,
              ),
          itemBuilder: (context, index) {
            return new ListTile(
              title: new Text(_results[index].label),
              onTap: () {
                Navigator.pop(context, _results[index]);
              },
            );
          }),
    );
  }
}
