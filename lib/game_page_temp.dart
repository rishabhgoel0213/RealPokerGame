import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'loading_page.dart';
import 'main.dart';

class GamePageTemp extends StatefulWidget {
  const GamePageTemp({Key? key, required this.userId, required this.matchId}) : super(key: key);

  final String userId;
  final String matchId;

  @override
  _GamePageTempState createState() => _GamePageTempState(userId: userId, matchId: matchId);
}

class _GamePageTempState extends State<GamePageTemp> {
  _GamePageTempState({required this.userId, required this.matchId});
  final String userId;
  final String matchId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late DocumentSnapshot<Map<String, dynamic>> matchSnapshot;
  late DocumentSnapshot<Map<String, dynamic>> userSnapshot;
  late DocumentSnapshot<Map<String, dynamic>> opponentSnapshot;
  late Map<String, dynamic> playerData;
  late Map<String, dynamic> opponentData;
  late List<String> playerCards = [];
  late List<String> generatedCards = [];
  late int round;
  late Map<String, dynamic> userData;
  late Map<String, dynamic> oppData;
  late bool hasAction = false;
  late bool hadInitalAction = false;
  T? cast<T>(x) => x is T ? x : null;

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
          title: Text('Game Over'),
          content: Text('$winner won the game!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToGamePage(context); // Navigate to a new game
              },
              child: Text('New Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToMainPage(context); // Navigate to main page
              },
              child: Text('Quit'),
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingPage(userId: userId),
      ),
    );
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
    matchSnapshot = await _firestore.collection('matches').doc(matchId).get() as DocumentSnapshot<Map<String, dynamic>>;
    userSnapshot = await _firestore.collection('users').doc(userId).get() as DocumentSnapshot<Map<String, dynamic>>;
    final data = matchSnapshot.data();
    setState(() {
      userData = userSnapshot.data()!;
    });
    if (data != null) {
      final player1 = data['player1'];
      final player2 = data['player2'];
      if (player1['id'] == userId) {
        playerData = player1;
        opponentData = player2;
        if(data['inital_action'] == 'player1')
        {
          hadInitalAction = true;
        }
      } else {
        playerData = player2;
        opponentData = player1;
        if(data['inital_action'] == 'player2')
        {
          hadInitalAction = true;
        }
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
    opponentSnapshot = await _firestore.collection('users').doc(opponentData['id']).get() as DocumentSnapshot<Map<String, dynamic>>;
    setState(() {
      oppData = opponentSnapshot.data()!;
    });
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

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.setAsset('assets/$fileName');
      _audioPlayer.play();
    } catch (e) {
      print("Error playing sound: $e");
    }
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

    // Play sound based on action
    if (action == 'call' || action == 'raise') {
      await _playSound('handfull-of-poker-chips-95810.mp3');
    } else if (action == 'all_in') {
      await _playSound('allinpushchips-96121.mp3');
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Game'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: hasAction ? () => _userAction('all_in', raiseAmount: playerData['pot']) : null,
                      child: const Text('All In'),
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
          // Display opponent's pot, rating, at the top right
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Opponent Rating:',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '${oppData['rating']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Opponent Pot:',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '${opponentData['pot']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Display player's pot, rating, at the bottom left
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rating:',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '${userData['rating']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Pot:',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '${playerData['pot']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
