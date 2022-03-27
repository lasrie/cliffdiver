import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventWidget extends StatelessWidget {
  final Color color;

  EventWidget(this.color);

  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireEvents = firestore.collection('Events');
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Events"),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: fireEvents.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return new Text('Loading...');
                default:
                  return new ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: snapshot.data.docs.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
                            height: 2,
                            thickness: 1,
                          ),
                      itemBuilder: (context, index) {
                        var document = snapshot.data.docs[index];
                        Timestamp eventTime = document.get('date');
                        DateTime eventDate = eventTime.toDate();
                        return new ListTile(
                          leading: Text(DateFormat.yMMMd().format(eventDate)),
                          title: new Text(document.get('title')),
                          subtitle: new Text(document.get('place')),
                        );
                      });
              }
            }));
  }
}
