import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learn'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Learning Poker Ranges',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: 'qjqrayvDYMs', // YouTube video ID
                  flags: YoutubePlayerFlags(
                    autoPlay: true,
                    mute: false,
                  ),
                ),
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blueAccent,
              ),
              builder: (context, player) {
                return Column(
                  children: [
                    player,
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Perform any action here when the button is pressed
                      },
                      child: Text('Play Video'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
