import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

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
  int buyIn = 500;
  final TextEditingController raiseController = TextEditingController();

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
    userStackSize = 500;
    opponentStackSize = 500;
    raiseController.clear();
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
    List<String> userCardTitles = playerCards.map((card) => card.split('/').last.split('.').first).toList();
    List<String> opponentCardTitles = opponentCards.map((card) => card.split('/').last.split('.').first).toList();
    List<String> communityCardTitles = generatedCards.map((card) => card.split('/').last.split('.').first).toList();

    List<Tuple<String, String>> userHand = userCardTitles.map((title) {
      List<String> parts = title.split('_');
      return Tuple(parts.first, parts.last);
    }).toList();

    List<Tuple<String, String>> opponentHand = opponentCardTitles.map((title) {
      List<String> parts = title.split('_');
      return Tuple(parts.first, parts.last);
    }).toList();

    List<Tuple<String, String>> communityHand = communityCardTitles.map((title) {
      List<String> parts = title.split('_');
      return Tuple(parts.first, parts.last);
    }).toList();

    PokerHand userPokerHand = PokerHand([...userHand, ...communityHand]);
    PokerHand opponentPokerHand = PokerHand([...opponentHand, ...communityHand]);

    String userBestHand = userPokerHand.evaluateHand();
    String opponentBestHand = opponentPokerHand.evaluateHand();

    if (userBestHand == opponentBestHand) {
      setState(() {
        winner = 'It\'s a tie!';
      });
    } else {
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

      int userHandIndex = handHierarchy.indexOf(userBestHand);
      int opponentHandIndex = handHierarchy.indexOf(opponentBestHand);

      if (userHandIndex < opponentHandIndex) {
        setState(() {
          winner = 'Player';
        });
      } else {
        setState(() {
          winner = 'Opponent';
        });
      }
    }

    setState(() {
      gameEnded = true;
    });
    _showGameEndDialog();
  }

  void _showGameEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$winner wins!'),
          content: const Text('Would you like to play again or quit?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const GamePageTemp()),
                );
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/');
              },
              child: const Text('Quit'),
            ),
          ],
        );
      },
    );
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

  void _userFold() {
    setState(() {
      winner = 'Opponent';
      gameEnded = true;
    });
    _showGameEndDialog();
  }

  void _proceedToNextRound() {
    if (generatedCards.length >= 5 && userCalled && opponentCalled) {
      _evaluateHand();
    }
    _generateCard();

    setState(() {
      userCalled = false;
      opponentCalled = false;
      userRaised = false;
      opponentRaised = false;
      userBet = 0;
      opponentBet = 0;
      currentBet = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Opponent Cards:',
              style: TextStyle(fontSize: 18),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: opponentCards.map((card) {
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
                  onPressed: userCalled || gameEnded ? null : _userCall,
                  child: const Text('Call'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: userRaised || gameEnded
                      ? null
                      : () async {
                          int raiseAmount = int.parse(raiseController.text);
                          if (raiseAmount >= 0 &&
                              raiseAmount <= userStackSize &&
                              raiseAmount <= opponentStackSize) {
                            _userRaise(raiseAmount);
                          }
                        },
                  child: const Text('Raise'),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  child: TextField(
                    controller: raiseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Amt'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: gameEnded ? null : _userFold,
                  child: const Text('Fold'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Current Bet: $currentBet'),
            const SizedBox(height: 20),
            Text('Player Stack: $userStackSize'),
            const SizedBox(height: 20),
            Text('Opponent Stack: $opponentStackSize'),
          ],
        ),
      ),
    );
  }
}

class PokerHand {
  final List<Tuple<String, String>> cards;

  PokerHand(this.cards);

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

  bool _isRoyalFlush() {
    return _isStraightFlush() && cards.any((card) => card.item2 == 'ace');
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
    var values = cards.map((card) => _cardValue(card.item2)).toList();
    values.sort();
    for (var i = 0; i < values.length - 1; i++) {
      if (values[i + 1] - values[i] != 1) {
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

  Map<String, int> _getValueCount() {
    var countMap = <String, int>{};
    for (var card in cards) {
      var value = card.item2;
      countMap[value] = (countMap[value] ?? 0) + 1;
    }
    return countMap;
  }

  int _cardValue(String value) {
    switch (value) {
      case 'two':
        return 2;
      case 'three':
        return 3;
      case 'four':
        return 4;
      case 'five':
        return 5;
      case 'six':
        return 6;
      case 'seven':
        return 7;
      case 'eight':
        return 8;
      case 'nine':
        return 9;
      case 'ten':
        return 10;
      case 'jack':
        return 11;
      case 'queen':
        return 12;
      case 'king':
        return 13;
      case 'ace':
        return 14;
      default:
        return 0;
    }
  }
}
