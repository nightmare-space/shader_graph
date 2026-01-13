import 'package:flutter/cupertino.dart';

import 'games/bricks_game.dart';
import 'games/pacman_game.dart';

class GameExample extends StatefulWidget {
  const GameExample({super.key});

  @override
  State<GameExample> createState() => _GameExampleState();
}

class _GameExampleState extends State<GameExample> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final tabTitles = [
      'Bricks Game',
      'Pacman Game',
    ];
    return Column(
      children: [
        CupertinoNavigationBar(
          middle: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CupertinoSlidingSegmentedControl(
              // isMomentary: true,
              proportionalWidth: true,
              groupValue: currentIndex,
              onValueChanged: (int? value) {
                if (value != null) {
                  currentIndex = value;
                  setState(() {});
                }
              },
              children: {
                for (var i = 0; i < tabTitles.length; i++) i: Text(tabTitles[i]),
              },
            ),
          ),
        ),
        Expanded(
          child: [
            BricksGame(),
            PacmanGame(),
          ][currentIndex],
        ),
      ],
    );
  }
}
