import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'game/bricks_game.dart';
import 'float_support.dart';
import 'iframe_view.dart';
import 'mouse_view.dart';
import 'multi_pass.dart';
import 'pacman_game.dart';
import 'text_render.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: Scaffold(body: MyApp())));
}

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Shader Graph Example',
      // theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xff006aff),
      ),
      home: CupertinoPageScaffold(
        child: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Text('Bricks Game'),
      Text('Pacman Game'),
      Text('Text Render'),
      Text('iFrame Test'),
      Text('Multi-Pass'),
      Text('Float Support'),
      Text('Mouse'),
    ];
    return CupertinoPageScaffold(
      backgroundColor: Color(0xfff3f5f9),
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSlidingSegmentedControl<int>(
          groupValue: currentIndex,
          onValueChanged: (int? value) {
            if (value != null) {
              currentIndex = value;
              setState(() {});
            }
          },
          children: {
            for (var i = 0; i < tabs.length; i++) i: tabs[i],
          },
        ),
      ),
      child: Center(
        child: const [
          BricksGame(),
          PacmanGame(),
          TextRender(),
          IframeView(),
          MacWallpaperView(),
          FloatTest(),
          MouseView(),
        ][currentIndex],
      ),
    );
  }
}
