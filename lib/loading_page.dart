import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key, required this.userId}) : super(key: key);

  final String userId;

  @override
  _LoadingPageState createState() => _LoadingPageState(userId: userId);
}

class _LoadingPageState extends State<LoadingPage> {
  _LoadingPageState({required this.userId});
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkForNewGame();
  }

  Future<void> _checkForNewGame() async {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(userId).get();

      if (snapshot.exists && !(snapshot.data()!['searchingForMatch'] ?? true)) {
        timer.cancel();
        DocumentSnapshot<Map<String, dynamic>> matchSnapshot = await _firestore.collection('users').doc(userId).get();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GamePage(
              userId: userId,
              matchId: matchSnapshot.data()!['match_id'],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
