import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'game/bricks_game.dart';
import 'float_example.dart';
import 'iframe_example.dart';
import 'keyboard_example.dart';
import 'mouse_example.dart';
import 'multi_pass.dart';
import 'game/pacman_game.dart';
import 'text_render_example.dart';
import 'wrap_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: Scaffold(body: MyApp())));
}

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
  int currentIndex = 8;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Text('Bricks Game'),
      Text('Pacman Game'),
      Text('Keyboard'),
      Text('Mouse'),
      Text('Wrap & Filter'),
      Text('Text Render'),
      Text('iFrame'),
      Text('Multi-Pass'),
      Text('Float Support'),
    ];
    return CupertinoPageScaffold(
      backgroundColor: Color(0xfff3f5f9),
      navigationBar: CupertinoNavigationBar(
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
              for (var i = 0; i < tabs.length; i++) i: tabs[i],
            },
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          if (width < 400 && currentIndex != 0 && currentIndex != 1) {
            height = width * 0.75;
          }
          return SizedBox(
            width: width,
            height: height,
            child: [
              BricksGame(),
              PacmanGame(),
              KeyboardExample(),
              MouseExample(),
              WrapExample(),
              TextRenderExample(),
              IframeExample(),
              MultiPassExample(),
              FloatExample(),
            ][currentIndex],
          );
        },
      ),
    );
  }
}
