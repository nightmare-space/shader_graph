import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph_example/assets.dart';

class MultiPassExample extends StatefulWidget {
  const MultiPassExample({super.key});

  @override
  State<MultiPassExample> createState() => _MultiPassExampleState();
}

class _MultiPassExampleState extends State<MultiPassExample> {
  int currentIndex = 0;
  final tabTitles = [
    'MacOS Monterey Wallpaper',
    'expansive reaction-diffusion',
  ];
  @override
  Widget build(BuildContext context) {
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
            buildMacWallpaper(),
            ReactionDiffusionView(),
          ][currentIndex],
        ),
      ],
    );
  }

  ShaderSurface buildMacWallpaper() {
    return ShaderSurface.builder(
      () {
        final mainBuffer = Assets.macWallpaper.shaderBuffer;
        final bufferA = Assets.macWallpaperBufferA.shaderBuffer;
        mainBuffer.feedShader(bufferA);
        return [mainBuffer, bufferA];
      },
      key: ValueKey('mac_wallpaper'),
    );
  }
}

class ReactionDiffusionView extends StatelessWidget {
  const ReactionDiffusionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final bufferA = Assets.reactionDiffusionBufferA.shaderBuffer;
        final bufferB = Assets.reactionDiffusionBufferB.shaderBuffer;
        final bufferC = Assets.reactionDiffusionBufferC.shaderBuffer;
        final bufferD = Assets.reactionDiffusionBufferD.shaderBuffer;
        final mainBuffer = Assets.reactionDiffusionMain.shaderBuffer;

        bufferA
            .feedback(filter: FilterMode.linear)
            .feed(bufferC, filter: FilterMode.linear)
            .feed(Assets.rgbaNoiseMedium, wrap: WrapMode.repeat, filter: FilterMode.linear);

        bufferB.feed(bufferA, filter: FilterMode.linear);
        bufferC.feed(bufferB, filter: FilterMode.linear);

        // Scheme B: keep Dart feed order; shader remaps channel slots.
        mainBuffer
            .feed(bufferA, filter: FilterMode.linear)
            .feed(bufferC, filter: FilterMode.linear)
            .feed(Assets.rgbaNoiseMedium, wrap: WrapMode.repeat, filter: FilterMode.linear);
        return [bufferA, bufferB, bufferC, bufferD, mainBuffer];
      },
      key: ValueKey('reaction_diffusion'),
    );
  }
}
