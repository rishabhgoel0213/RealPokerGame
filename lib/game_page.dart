import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loading_page.dart';
import 'main.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key, required this.userId, required this.matchId}) : super(key: key);

  final String userId;
  final String matchId;

  @override
  _GamePageState createState() => _GamePageState(userId: userId, matchId: matchId);
}

class _GamePageState extends State<GamePage> {
  _GamePageState({required this.userId, required this.matchId});
  final String userId;
  final String matchId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DocumentSnapshot<Map<String, dynamic>> matchSnapshot;
  late Map<String, dynamic> playerData;
  late Map<String, dynamic> opponentData;
  late List<String> playerCards = [];
  late List<String> generatedCards = [];
  late int round;
  late bool hasAction = false;

  final Map<num, String> cardMapping = {
    16787479: 'assets/cards/spade_ten.png',
    73730: 'assets/cards/heart_two.png',
    2102541: 'assets/cards/spade_seven.png',
    8423187: 'assets/cards/club_nine.png',
    134253349: 'assets/cards/club_king.png',
    533255: 'assets/cards/heart_five.png',
    8394515: 'assets/cards/heart_nine.png',
    268442665: 'assets/cards/spade_ace.png',
    139523: 'assets/cards/heart_three.png',
    268454953: 'assets/cards/diamond_ace.png',
    134236965: 'assets/cards/diamond_king.png',
    134224677: 'assets/cards/spade_king.png',
    4199953: 'assets/cards/spade_eight.png',
    279045: 'assets/cards/diamond_four.png',
    4212241: 'assets/cards/diamond_eight.png',
    16783383: 'assets/cards/spade_ten.png',
    4204049: 'assets/cards/heart_eight.png',
    8398611: 'assets/cards/heart_nine.png',
    2106637: 'assets/cards/heart_seven.png',
    33573149: 'assets/cards/diamond_jack.png',
    1053707: 'assets/cards/spade_six.png',
    81922: 'assets/cards/diamond_two.png',
    8406803: 'assets/cards/diamond_nine.png',
    69634: 'assets/cards/spade_two.png',
    147715: 'assets/cards/diamond_three.png',
    33560861: 'assets/cards/spade_jack.png',
    541447: 'assets/cards/diamond_five.png',
    67119647: 'assets/cards/heart_queen.png',
    1057803: 'assets/cards/heart_six.png',
    33564957: 'assets/cards/heart_jack.png',
    529159: 'assets/cards/spade_five.png',
    557831: 'assets/cards/club_five.png',
    67115551: 'assets/cards/spade_queen.png',
    16812055: 'assets/cards/club_ten.png',
    16795671: 'assets/cards/diamond_ten.png',
    2131213: 'assets/cards/club_seven.png',
    1082379: 'assets/cards/club_six.png',
    33589533: 'assets/cards/club_jack.png',
    98306: 'assets/cards/club_two.png',
    135427: 'assets/cards/spade_three.png',
    2114829: 'assets/cards/diamond_seven.png',
    134228773: 'assets/cards/heart_king.png',
    67127839: 'assets/cards/diamond_queen.png',
    67144223: 'assets/cards/club_queen.png',
    268471337: 'assets/cards/club_ace.png',
    164099: 'assets/cards/club_three.png',
    295429: 'assets/cards/club_four.png',
    266757: 'assets/cards/spade_four.png',
    268446761: 'assets/cards/heart_ace.png',
    270853: 'assets/cards/heart_four.png',
    4228625: 'assets/cards/club_eight.png',
    1065995: 'assets/cards/diamond_six.png'
  };

  final TextEditingController raiseController = TextEditingController();
  late Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _initGame();
    _stream = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .snapshots();

    _stream.listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        matchSnapshot = snapshot as DocumentSnapshot<Map<String, dynamic>>;
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _updateGameState(data);
        });
      }
    });
  }


  void _showGameOverDialog(String winner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('$winner won the game!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToGamePage(context); // Navigate to a new game
              },
              child: const Text('New Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToMainPage(context); // Navigate to main page
              },
              child: const Text('Quit'),
            ),
          ],
        );
      },
    );
  }

void _redirectToGamePage(BuildContext context) async {
  await _firestore.collection('users').doc(userId).set({
    'inMatch': false,
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

  void _redirectToMainPage(BuildContext context) async {
    await _firestore.collection('users').doc(userId).set({
      'inMatch': false,
      'newMatch': false,
    }, SetOptions(merge: true));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: "This Is Poker", userId: userId),
      ),
    );
  }


  Future<void> _initGame() async {
    matchSnapshot = await _firestore.collection('matches').doc(matchId).get();
    final data = matchSnapshot.data();
    if (data != null) {
      final player1 = data['player1'];
      final player2 = data['player2'];
      if (player1['id'] == userId) {
        playerData = player1;
        opponentData = player2;
      } else {
        playerData = player2;
        opponentData = player1;
      }

      List<dynamic> playerCardNums = playerData['cards'];
      playerCards = [
        cardMapping[playerCardNums[0]]!,
        cardMapping[playerCardNums[1]]!
      ];

      generatedCards = [];
      round = data['round'];
      hasAction = playerData['has_action'];

      setState(() {});
    }
  }

  void _updateGameState(Map<String, dynamic> data) {
    final player1 = data['player1'];
    final player2 = data['player2'];
    if (player1['id'] == userId) {
      playerData = player1;
      opponentData = player2;
    } else {
      playerData = player2;
      opponentData = player1;
    }

    round = data['round'];
    hasAction = playerData['has_action'];

    if (round == 1) {
      generatedCards = (data['flop'] as List).map((card) => cardMapping[card]!).toList();
    } else if (round == 2) {
      generatedCards = (data['flop'] as List).map((card) => cardMapping[card]!).toList();
      generatedCards.add(cardMapping[data['turn'][0]]!);
    } else if (round == 3) {
      generatedCards = (data['flop'] as List).map((card) => cardMapping[card]!).toList();
      generatedCards.add(cardMapping[data['turn'][0]]!);
      generatedCards.add(cardMapping[data['river'][0]]!);
    } if (round == 4) {
      _showGameOverDialog(data['winner']);
    }

    setState(() {});
  }

  void _userAction(String action, {int? raiseAmount}) async {
    if (!hasAction) return;

    final batch = _firestore.batch();
    final playerDocRef = _firestore.collection('matches').doc(matchId);
    final data = matchSnapshot.data();
    final playerField = data!['player1']['id'] == userId ? 'player1' : 'player2';
    final playerDataUpdated = Map<String, dynamic>.from(playerData);
    playerDataUpdated['action'] = [action, if (raiseAmount != null) raiseAmount];
    batch.update(playerDocRef, {playerField: playerDataUpdated});

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return false;
        }, 
        child : Scaffold(
        appBar: AppBar(
          title: const Text('Poker Game'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text(
                'Player Cards:',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: playerCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.asset(
                      card,
                      width: 60,
                      height: 90,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Generated Cards:',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: generatedCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.asset(
                      card,
                      width: 60,
                      height: 90,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Player Actions:',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: hasAction ? () => _userAction('call') : null,
                    child: const Text('Call'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: hasAction ? () => _userAction('raise', raiseAmount: int.parse(raiseController.text)) : null,
                    child: const Text('Raise'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: hasAction ? () => _userAction('fold') : null,
                    child: const Text('Fold'),
                  ),
                ],
              ),
              TextField(
                controller: raiseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Raise Amount'),
              ),
            ],
          ),
        ),
      )
    );
  }
}
