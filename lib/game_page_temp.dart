import 'package:flutter/material.dart';
import 'dart:math';

// Define a tuple class
class Tuple<X, Y> {
  final X item1;
  final Y item2;
  Tuple(this.item1, this.item2);
}

class GamePageTemp extends StatefulWidget {
  const GamePageTemp({Key? key}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePageTemp> {
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

  void _evaluateHand() {
  // Scraping GUI titles and converting them into tuples
  List<String> userCardTitles = playerCards.map((card) => card.split('/').last.split('.').first).toList();
  List<Tuple<String, String>> userHand = userCardTitles.map((title) {
    List<String> parts = title.split('_');
    return Tuple(parts.first, parts.last);
  }).toList();

  List<String> opponentCardTitles = opponentCards.map((card) => card.split('/').last.split('.').first).toList();
  List<Tuple<String, String>> opponentHand = opponentCardTitles.map((title) {
    List<String> parts = title.split('_');
    return Tuple(parts.first, parts.last);
  }).toList();

  var userPokerHand = PokerHand(userHand);
  var opponentPokerHand = PokerHand(opponentHand);

  String userHandType = userPokerHand.evaluateHand();
  String opponentHandType = opponentPokerHand.evaluateHand();

  // Compare hands
  if (userHandType == opponentHandType) {
    // Hands are of the same type, compare highest cards
    // You may implement tie-breaking logic here if needed
    // For simplicity, let's assume the player with the highest card wins in case of a tie
    String userHighestCard = userHand.map((card) => card.item2).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    String opponentHighestCard = opponentHand.map((card) => card.item2).reduce((a, b) => a.compareTo(b) > 0 ? a : b);

    if (userHighestCard == opponentHighestCard) {
      // It's a tie
      setState(() {
        winner = 'It\'s a tie!';
      });
    } else {
      setState(() {
        winner = 'Player';
      });
    }
  } else {
    // Hands are of different types, compare based on the hierarchy
    List<String> handHierarchy = [
      "Royal Flush",
      "Straight Flush",
      "Four of a Kind",
      "Full House",
      "Flush",
      "Straight",
      "Three of a Kind",
      "Two Pair",
      "One Pair",
      "High Card"
    ];

    int userHandIndex = handHierarchy.indexOf(userHandType);
    int opponentHandIndex = handHierarchy.indexOf(opponentHandType);

    if (userHandIndex < opponentHandIndex) {
      // Player's hand type is higher in the hierarchy
      setState(() {
        winner = 'Player';
      });
    } else {
      // Opponent's hand type is higher in the hierarchy
      setState(() {
        winner = 'Opponent';
      });
    }
  }
  setState(() {
    gameEnded = true;
    });
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
    if (userCalled && opponentCalled && generatedCards.length == 5) {
      _evaluateHand();
    }
    else {
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
                    onPressed: generatedCards.length <= 5 && !userCalled && !opponentCalled ? _userCall : null,
                    child: Text('Call'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: generatedCards.length == 5 && userCalled && opponentCalled ? null : _userFold,
                    child: Text('Fold'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: generatedCards.length == 5 && userCalled && opponentCalled ? null: () => _userRaise(50),
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
                color: Colors.black,
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

// Define a class to represent a poker hand
class PokerHand {
  final List<Tuple<String, String>> cards;

  PokerHand(this.cards);

  // Function to evaluate the hand
  String evaluateHand() {
    if (_isRoyalFlush()) return "Royal Flush";
    if (_isStraightFlush()) return "Straight Flush";
    if (_isFourOfAKind()) return "Four of a Kind";
    if (_isFullHouse()) return "Full House";
    if (_isFlush()) return "Flush";
    if (_isStraight()) return "Straight";
    if (_isThreeOfAKind()) return "Three of a Kind";
    if (_isTwoPair()) return "Two Pair";
    if (_isOnePair()) return "One Pair";
    return "High Card";
  }

  // Helper functions to check different hand types
  bool _isRoyalFlush() {
    return _isStraightFlush() && cards[0].item2 == '10';
  }

  bool _isStraightFlush() {
    return _isStraight() && _isFlush();
  }

  bool _isFourOfAKind() {
    var valueCount = _getValueCount();
    return valueCount.containsValue(4);
  }

  bool _isFullHouse() {
    var valueCount = _getValueCount();
    return valueCount.containsValue(3) && valueCount.containsValue(2);
  }

  bool _isFlush() {
    var suit = cards[0].item1;
    return cards.every((card) => card.item1 == suit);
  }

  bool _isStraight() {
    var values = cards.map((card) => card.item2).toList()..sort();
    for (var i = 0; i < values.length - 1; i++) {
      if (int.parse(values[i + 1]) - int.parse(values[i]) != 1) {
        return false;
      }
    }
    return true;
  }

  bool _isThreeOfAKind() {
    var valueCount = _getValueCount();
    return valueCount.containsValue(3);
  }

  bool _isTwoPair() {
    var valueCount = _getValueCount();
    var pairs = valueCount.values.where((value) => value == 2).length;
    return pairs == 2;
  }

  bool _isOnePair() {
    var valueCount = _getValueCount();
    var pairs = valueCount.values.where((value) => value == 2).length;
    return pairs == 1;
  }

  // Helper function to count the occurrences of each card value
  Map<String, int> _getValueCount() {
    var countMap = <String, int>{};
    for (var card in cards) {
      var value = card.item2;
      countMap[value] = (countMap[value] ?? 0) + 1;
    }
    return countMap;
  }
}
