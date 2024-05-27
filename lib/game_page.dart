import 'package:flutter/material.dart';
import 'dart:math';

class GamePage extends StatefulWidget {
  const GamePage({Key? key, required this.matchId}) : super(key: key);

  final String matchId;

  @override
  _GamePageState createState() => _GamePageState(matchId: matchId);
}

class _GamePageState extends State<GamePage> {

  _GamePageState({required this.matchId});

  final List<String> cardAssets = [
    'assets/cards/club_ace.png',
    'assets/cards/club_two.png',
    'assets/cards/club_three.png',
    'assets/cards/club_four.png',
    'assets/cards/club_five.png',
    'assets/cards/club_six.png',
    'assets/cards/club_seven.png',
    'assets/cards/club_eight.png',
    'assets/cards/club_nine.png',
    'assets/cards/club_ten.png',
    'assets/cards/club_jack.png',
    'assets/cards/club_queen.png',
    'assets/cards/club_king.png',
    'assets/cards/diamond_ace.png',
    'assets/cards/diamond_two.png',
    'assets/cards/diamond_three.png',
    'assets/cards/diamond_four.png',
    'assets/cards/diamond_five.png',
    'assets/cards/diamond_six.png',
    'assets/cards/diamond_seven.png',
    'assets/cards/diamond_eight.png',
    'assets/cards/diamond_nine.png',
    'assets/cards/diamond_ten.png',
    'assets/cards/diamond_jack.png',
    'assets/cards/diamond_queen.png',
    'assets/cards/diamond_king.png',
    'assets/cards/heart_ace.png',
    'assets/cards/heart_two.png',
    'assets/cards/heart_three.png',
    'assets/cards/heart_four.png',
    'assets/cards/heart_five.png',
    'assets/cards/heart_six.png',
    'assets/cards/heart_seven.png',
    'assets/cards/heart_eight.png',
    'assets/cards/heart_nine.png',
    'assets/cards/heart_ten.png',
    'assets/cards/heart_jack.png',
    'assets/cards/heart_queen.png',
    'assets/cards/heart_king.png',
    'assets/cards/spade_ace.png',
    'assets/cards/spade_two.png',
    'assets/cards/spade_three.png',
    'assets/cards/spade_four.png',
    'assets/cards/spade_five.png',
    'assets/cards/spade_six.png',
    'assets/cards/spade_seven.png',
    'assets/cards/spade_eight.png',
    'assets/cards/spade_nine.png',
    'assets/cards/spade_ten.png',
    'assets/cards/spade_jack.png',
    'assets/cards/spade_queen.png',
    'assets/cards/spade_king.png'
  ];

  final String matchId;
  late List<String> commonBank;
  late List<String> playerCards;
  late List<String> opponentCards;
  late List<String> generatedCards;
  bool userCalled = false;
  bool opponentCalled = false;
  bool userRaised = false;
  bool opponentRaised = false;
  int userStackSize = 500;
  int opponentStackSize = 500;
  bool gameEnded = false;
  String winner = '';
  int currentBet = 0;
  int userBet = 0;
  int opponentBet = 0;
  int round = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    commonBank = List.from(cardAssets);
    generatedCards = [];
    userCalled = false;
    opponentCalled = false;
    userRaised = false;
    opponentRaised = false;
    gameEnded = false;
    winner = '';
    currentBet = 0;
    userBet = 0;
    opponentBet = 0;
    round = 0;
    _dealCards();
  }

  void _dealCards() {
    final random = Random();
    playerCards = [];
    opponentCards = [];

    // Deal two cards to each player
    for (int i = 0; i < 2; i++) {
      int playerCardIndex = random.nextInt(commonBank.length);
      playerCards.add(commonBank.removeAt(playerCardIndex));

      int opponentCardIndex = random.nextInt(commonBank.length);
      opponentCards.add(commonBank.removeAt(opponentCardIndex));
    }
  }

  void _generateCard() {
    if (generatedCards.length < 5) {
      final random = Random();
      int numCards = round == 0 ? 3 : 1;

      for (int i = 0; i < numCards; i++) {
        if (generatedCards.length >= 5) break;
        int randomCardIndex = random.nextInt(commonBank.length);
        generatedCards.add(commonBank.removeAt(randomCardIndex));
      }

      if (round < 3) round++;
    }
  }

  void _userCall() {
    setState(() {
      userCalled = true;
      userStackSize -= (currentBet - userBet);
      userBet = currentBet;
    });

    _opponentCall();

    if (opponentCalled) {
      _proceedToNextRound();
    }
  }

  void _opponentCall() {
    setState(() {
      opponentCalled = true;
      opponentStackSize -= (currentBet - opponentBet);
      opponentBet = currentBet;
    });

    if (userCalled) {
      _proceedToNextRound();
    }
  }

  void _userRaise(int amount) {
    setState(() {
      userCalled = true;
      userRaised = true;
      currentBet += amount;
      userStackSize -= (currentBet - userBet);
      userBet = currentBet;
      userCalled = true;
      opponentCalled = false;
    });

    _opponentCall();
  }

  void _proceedToNextRound() {
    setState(() {
      userCalled = false;
      opponentCalled = false;
      userRaised = false;
      opponentRaised = false;
      userBet = 0;
      opponentBet = 0;
      currentBet = 0;
    });
    _generateCard();
  }

  void _userFold() {
    setState(() {
      gameEnded = true;
      winner = 'Opponent';
      opponentStackSize += (userBet + opponentBet);
    });
  }

  void _opponentFold() {
    setState(() {
      gameEnded = true;
      winner = 'User';
      userStackSize += (userBet + opponentBet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Page'),
      ),
      body: Stack(
        children: [
          // Opponent
          Positioned(
            top: 50,
            left: 50,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('Opponent'),
                  Image.asset(opponentCards[0], width: 50), // Example opponent card
                  Image.asset(opponentCards[1], width: 50), // Example opponent card
                  SizedBox(height: 8),
                  Text('Stack Size: $opponentStackSize'),
                ],
              ),
            ),
          ),
          // Player's cards
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Row(
              children: [
                Image.asset(playerCards[0], width: 50), // Player card
                Image.asset(playerCards[1], width: 50), // Player card
              ],
            ),
          ),
          // Generated cards
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 25,
            left: MediaQuery.of(context).size.width / 2 - 75,
            child: Row(
              children: generatedCards.map((card) => Image.asset(card, width: 50)).toList(),
            ),
          ),
          // Call, Fold, and Raise buttons
          if (!gameEnded)
            Positioned(
              top: MediaQuery.of(context).size.height - 100,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: generatedCards.length < 5 ? _userCall : null,
                    child: Text('Call'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _userFold,
                    child: Text('Fold'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _userRaise(50),
                    child: Text('Raise 50'),
                  ),
                ],
              ),
            ),
          // User stack size
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Text('Stack Size: $userStackSize'),
            ),
          ),
          // Display winner if game ended
          if (gameEnded)
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '$winner wins!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
