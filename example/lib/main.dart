import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'examples/game.dart';
import 'examples/animation_controll.dart';
import 'examples/float.dart';
import 'examples/keyboard_input.dart';
import 'examples/mouse_input.dart';
import 'examples/multi_pass.dart';
import 'examples/text_render.dart';
import 'examples/widget_input.dart';
import 'examples/wrap.dart';

double narrowWidthThreshold = 600;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: Scaffold(body: MyApp())));
  ui.ImageFilter.isShaderFilterSupported;
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
  int currentIndex = 4;

  @override
  Widget build(BuildContext context) {
    final tabTitles = [
      'Game',
      'Widget Input',
      'Keyboard Input',
      'Mouse Input',
      'Wrap & Filter',
      'Text Render',
      'Animation Controller',
      'Multi-Pass',
      'Float Support',
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
              for (var i = 0; i < tabTitles.length; i++) i: Text(tabTitles[i]),
            },
          ),
        ),
      ),
      child: SafeArea(
        child: [
          GameExample(),
          WidgetInputExample(),
          KeyboardExample(),
          MouseExample(),
          WrapExample(),
          TextRenderExample(),
          AnimationControlExample(),
          MultiPassExample(),
          FloatExample(),
        ][currentIndex],
      ),
    );
  }
}
