import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'examples/custom_uniforms.dart';
import 'examples/game.dart';
import 'examples/animation_control.dart';
import 'examples/float.dart';
import 'examples/multi_pass.dart';
import 'examples/shader_input.dart' hide ReactionDiffusionView;
import 'examples/text_render.dart';
import 'examples/wrap.dart';

double narrowWidthThreshold = 600;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: Scaffold(body: MyApp())));
  // check if impeller is used
  // ui.ImageFilter.isShaderFilterSupported;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Shader Graph Example',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.deepPurple,
      ),
      onGenerateRoute: (settings) {
        String? shaderParam;
        if (kIsWeb) {
          final uri = Uri.base;
          shaderParam = uri.queryParameters['example'];
          debugPrint('URL query parameter "shader": $shaderParam');
        }
        if (shaderParam != null && shaderParam.isNotEmpty) {
          if (shaderParam == 'ReactionDiffusion') {
            return MaterialPageRoute(
              builder: (context) => ReactionDiffusionView(),
              settings: settings,
            );
          }
        }

        return CupertinoPageRoute(
          builder: (context) => const RootPage(),
          settings: settings,
        );
      },
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
    final tabTitles = [
      'Game',
      'Shader Input',
      'Wrap & Filter',
      'Text Render',
      'Animation Controller',
      'Multi-Pass',
      'Custom Uniforms',
      'Float Support',
    ];

    return ScreenshotExporter(
      // enableExportButton: true,
      child: CupertinoPageScaffold(
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
            ShaderInputExample(),
            WrapExample(),
            TextRenderExample(),
            AnimationControlExample(),
            MultiPassExample(),
            CustomUniformsExample(),
            FloatExample(),
          ][currentIndex],
        ),
      ),
    );
  }
}

class ScreenshotExporter extends StatefulWidget {
  const ScreenshotExporter({
    super.key,
    required this.child,
    this.defaultFileName = 'screenshot.png',
    this.pixelRatio,
    this.enableExportButton = false,
  });

  final Widget child;
  final String defaultFileName;
  final double? pixelRatio;
  final bool enableExportButton;

  @override
  State<ScreenshotExporter> createState() => ScreenshotExporterState();
}

class ScreenshotExporterState extends State<ScreenshotExporter> {
  final GlobalKey _repaintKey = GlobalKey();

  Future<Uint8List> capturePngBytes() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final dpr = widget.pixelRatio ?? View.of(context).devicePixelRatio;

    final ui.Image image = await boundary.toImage(pixelRatio: dpr);
    final ByteData? bd = await image.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<String> exportPng({String? fileName}) async {
    if (kIsWeb) {
      throw UnsupportedError('exportPng is not supported on Web');
    }

    final bytes = await capturePngBytes();
    final name = (fileName == null || fileName.isEmpty) ? widget.defaultFileName : fileName;
    final outPath = '${Directory.current.path}/$name';
    final file = File(outPath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: widget.child,
        ),
        if (widget.enableExportButton)
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              type: MaterialType.transparency,
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    final path = await exportPng(
                      fileName: 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
                    );
                    debugPrint('Screenshot saved: $path');
                  } catch (e, st) {
                    debugPrint('Screenshot export failed: $e\n$st');
                  }
                },
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
      ],
    );
  }
}
