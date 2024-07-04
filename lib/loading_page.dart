import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key, required this.userId, required this.matchId}) : super(key: key);

  final String userId;
  final String matchId;

  @override
  _LoadingPageState createState() => _LoadingPageState(userId: userId, matchId: matchId);
}

class _LoadingPageState extends State<LoadingPage> {
  _LoadingPageState({required this.userId, required this.matchId});
  final String userId;
  final String matchId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkForNewGame();
  }

  Future<void> _checkForNewGame() async {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('matches').doc(matchId).get();

      if (snapshot.exists && (snapshot.data()!['full'] ?? false)) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GamePage(
              userId: userId,
              matchId: snapshot.data()!['match_id'],
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
