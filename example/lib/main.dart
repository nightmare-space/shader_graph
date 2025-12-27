import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

import 'game/bricks_game.dart';
import 'float_support.dart';
import 'iframe_view.dart';
import 'mouse_view.dart';
import 'multi_pass.dart';
import 'game/pacman_game.dart';
import 'text_render.dart';
import 'wrap_view.dart';

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
  int currentIndex = 5;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Text('Bricks Game'),
      Text('Pacman Game'),
      Text('Text Render'),
      Text('iFrame'),
      Text('Multi-Pass'),
      Text('Float Support'),
      Text('Mouse'),
      Text('Wrap'),
      Text('Keyboard'),
    ];
    return CupertinoPageScaffold(
      backgroundColor: Color(0xfff3f5f9),
      navigationBar: CupertinoNavigationBar(
        middle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CupertinoSlidingSegmentedControl(
            // isMomentary: true,
            // proportionalWidth: true,
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
      child: LayoutBuilder(builder: (context, constraints) {
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
            TextRender(),
            IframeView(),
            MacWallpaperView(),
            FloatTest(),
            MouseView(),
            WrapView(),
            ShaderSurface.builder(
              () {
                final mainBuffer = 'shaders/keyboard/keyboard Test.frag'.shaderBuffer;
                // iChannel0: keyboard texture, iChannel1: font atlas
                mainBuffer.feedKeyboard();
                mainBuffer.feedImageFromAsset('assets/codepage12.png');
                return [mainBuffer];
              },
            ),
          ][currentIndex],
        );
      }),
    );
  }
}
