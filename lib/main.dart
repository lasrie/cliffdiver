import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'bottom_bar_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  var firebaseConfig = {
    'apiKey': dotenv.env['FB_APIKEY'],
    'authDomain': dotenv.env['FB_AUTHDOMAIN'],
    'databaseURL': dotenv.env['FB_DBDOMAIN'],
    'projectId': dotenv.env['FB_PROJECTID'],
    'storageBucket': dotenv.env['FB_STORAGEBUCKET'],
    'messagingSenderId': dotenv.env['FB_SENDERID'],
    'appId': dotenv.env['FB_APPID'],
    'measurementId': dotenv.env['FB_MEASUREMENTID']
  };
  final app = await Firebase.initializeApp(
    options: FirebaseOptions.fromMap(firebaseConfig),
  );
  final firestore = FirebaseFirestore.instanceFor(app: app);

  runApp(CliffDiver(firestore));
}

/**
 * Sets up main context of the app: set color theme, create bottom bar
 */
class CliffDiver extends StatelessWidget {
  CliffDiver(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cliff Diver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BottomBar(firestore),
    );
  }
}
