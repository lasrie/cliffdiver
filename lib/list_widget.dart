import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cliffdiver/new_spot_widget.dart';
import 'package:cliffdiver/spot_detail.dart';

class ListWidget extends StatefulWidget {
  ListWidget(this.firestore);
  final FirebaseFirestore firestore;

  @override
  _ListState createState() {
    return _ListState(firestore);
  }
}

class _ListState extends State<ListWidget> {
  _ListState(this.firestore);

  final FirebaseFirestore firestore;

  List<SpotEntry> spots = List<SpotEntry>.empty(growable: true);
  List<SpotEntry> allSpots = List<SpotEntry>.empty(growable: true);

  TextEditingController _textEditingController = TextEditingController();

  void initState() {
    super.initState();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    _fetchSpots(firestore);
  }

  _fetchSpots(FirebaseFirestore firestore) {
    CollectionReference fireSpots = firestore.collection('Spots');
    spots = [];
    fireSpots.get().then((docList) {
      if (docList.docs.isNotEmpty) {
        for (int i = 0; i < docList.docs.length; i++) {
          allSpots.add(SpotEntry(
              spotData: docList.docs[i].data(),
              doc: docList.docs[i],
              documentID: docList.docs[i].id));
        }
        setState(() {
          spots = allSpots;
          allSpots = allSpots;
        });
      }
    });
  }

  _onItemChanged(String value) {
    var thisSpots = allSpots.where((item) {
      if (item.spotData["address"].contains(value)) {
        return true;
      } else if (item.spotData["title"].contains(value)) {
        return true;
      } else {
        return false;
      }
    });

    setState(() {
      spots = thisSpots.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: Padding(
            padding: const EdgeInsets.all(12.0),
            child: new TextField(
              controller: _textEditingController,
              onChanged: _onItemChanged,
              decoration: InputDecoration(hintText: 'Filter Spots'),
            ),
          ),
        ),
        body: Stack(children: [
          ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: spots.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
              height: 2,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              var document = spots[index].doc;
              return new ListTile(
                onTap: () => Navigator.of(context)
                    .push(new MaterialPageRoute(builder: (context) {
                  return new SpotDetail(
                      spot: document, spotID: spots[index].documentID);
                })),
                leading: Image.network(
                  document.get('imageUrl'),
                  width: 72,
                ),
                title: new Text(document.get('title')),
                subtitle: new Text(document.get('address')),
                trailing: Icon(Icons.more_vert),
                isThreeLine: true,
              );
            },
          ),
          Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton.extended(
                onPressed: () => {
                  Navigator.of(context)
                      .push(new MaterialPageRoute(builder: (context) {
                    return new NewSpot();
                  }))
                },
                tooltip: 'Add new Spot to Database',
                icon: Icon(Icons.add),
                label: Text('Add Spot'),
              ))
        ]));
  }
}

class SpotEntry {
  String documentID;
  DocumentSnapshot doc;
  var spotData;
  SpotEntry({this.spotData, this.documentID, this.doc});
}
