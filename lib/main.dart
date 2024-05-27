import 'dart:async';

import 'package:flutter/material.dart';
import 'game_page.dart';  // Import the GamePage
import 'game_page_temp.dart';  // Import the Temp GamePage
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.userId}) : super(key: key);

  final String title;
  final String userId;

  @override
  State<MyHomePage> createState() => _MyHomePageState(userId);
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final String userId;

  _MyHomePageState(this.userId);


  void _redirectToGamePage(BuildContext context) async {
    // Update the searchingForMatch value in the database to true
    await _firestore.collection('users').doc(userId).update({
      'searchingForMatch': true,
    });

    // Create a timer to periodically check if searchingForMatch becomes false
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      // Fetch the document
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(userId).get();

      // Check if the document exists and if searchingForMatch is false
      if (snapshot.exists && !(snapshot.data()!['searchingForMatch'] ?? true)) {
        // If searchingForMatch is false, cancel the timer and navigate to the GamePage
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GamePage(matchId: snapshot.data()!['matchId'],)),
        );
      }
    });
  }

  void _redirectToTempGamePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamePageTemp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'Stats':
                  // Navigate to Stats Page
                  break;
                case 'Friends':
                  // Navigate to Friends Page
                  break;
                case 'Learn':
                  // Navigate to Learn Page
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Stats', 'Friends', 'Learn'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _redirectToGamePage(context),
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: () => _redirectToTempGamePage(context),
              child: const Text('Temp Play'),
            ),
          ],
        ),
      ),
    );
  }
}
