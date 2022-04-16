import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_widget.dart';
import 'list_widget.dart';
import 'map_widget.dart';

class BottomBar extends StatefulWidget {
  BottomBar(this.firestore);
  final FirebaseFirestore firestore;

  @override
  State<StatefulWidget> createState() {
    return _BottomBarState(firestore);
  }
}

class _BottomBarState extends State<BottomBar> {
  _BottomBarState(this.firestore);
  final FirebaseFirestore firestore;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _children = [
      MapUI(),
      ListWidget(firestore),
      EventWidget(Colors.deepOrange),
    ];
    
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.room),
            label: 'Map View',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.list),
            label: 'List View',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events')
        ],
      ),
    );
  }

/**
 * Called when a bottom tab is clicked, with the 
 */
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
