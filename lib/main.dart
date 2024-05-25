import 'package:flutter/material.dart';
import 'game_page.dart';  // Import the GamePage
import 'game_page_temp.dart';  // Import the Temp GamePage
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

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
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _redirectToGamePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamePage()),
    );
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
