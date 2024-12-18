import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/loading_page.dart';
import 'game_page.dart';  
import 'game_page_temp.dart';  
import 'friends.dart';  
import 'learn.dart';  // Import the Learn page
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html';

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

  final String userId;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(userId);
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  final String userId;

  _MyHomePageState(this.userId);

  void _redirectToGamePage(BuildContext context) async {
    await _firestore.collection('users').doc(userId).set({
      'newMatch': true,
    }, SetOptions(merge: true));

    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(userId).get();

      if (snapshot.exists && !(snapshot.data()!['newMatch'] ?? false)) {
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoadingPage(userId: userId)),
        );
      }
    });
  }

  void _redirectToTempGamePage(BuildContext context) async {
    await _firestore.collection('users').doc(userId).update({
      'newMatch': true,
    });

    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(userId).get();

      if (snapshot.exists && !(snapshot.data()!['newMatch'] ?? true)) {
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GamePageTemp(userId: userId, matchId: snapshot.data()!['match_id'],)),
        );
      }
    });
  }

  void _redirectToFriendsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FriendsPage(userId: userId)), 
    );
  }

  void _redirectToLearnPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LearnPage(userId: userId)), // Redirect to Learn Page
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
                  _redirectToFriendsPage(context); // Redirect to Friends Page
                  break;
                case 'Learn':
                  _redirectToLearnPage(context); // Redirect to Learn Page
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
