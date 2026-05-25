import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph_example/assets.dart';
import 'package:shader_graph_example/main.dart';

class WrapExample extends StatefulWidget {
  const WrapExample({super.key});

  @override
  State<WrapExample> createState() => _WrapExampleState();
}

class _WrapExampleState extends State<WrapExample> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final tabTitles = [
      'Raw Image',
      'Transition Burning',
      'Tissue',
      'Black Hole ODE Geodesic Solver',
      'Broken Time Gate',
      'Goodbye Dream Clouds',
    ];

    return Column(
      mainAxisSize: MainAxisSize.max,
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
            buildRawImageWrap(),
            buildTransitionBurning(),
            buildTissue(),
            buildBlackHoleODEGeodesicSolver(),
            buildBrokenTime(),
            buildGoodbyeDreamClouds(),
          ][currentIndex],
        ),
      ],
    );
  }

  bool useWidgetInput = true;

  LayoutBuilder buildRawImageWrap() {
    String shader = Assets.wrapDebug;
    String texture = Assets.rockTiles;

    Widget assetImage = Image.asset(
      texture,
      fit: BoxFit.cover,
    );
    // final clamp = shader.feed(texture, wrap: .clamp);
    // final repeat = shader.feed(texture, wrap: .repeat);
    // final mirror = shader.feed(texture, wrap: .mirror);

    final clamp = shader.feed(
      assetImage,
      wrap: WrapMode.clamp,
    );
    final repeat = shader.feed(
      assetImage,
      wrap: WrapMode.repeat,
    );
    final mirror = shader.feed(
      assetImage,
      wrap: WrapMode.mirror,
    );
    Widget panel(String title, ShaderBuffer buffer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ShaderSurface.auto(buffer, upSideDown: true),
          ),
        ],
      );
    }

    final widgets = [
      panel('Clamp (default)', clamp),
      panel('Repeat', repeat),
      panel('Mirror', mirror),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < narrowWidthThreshold;
        if (isNarrow) {
          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: Column(
                spacing: 8,
                children: [
                  for (var w in widgets) SizedBox(height: constraints.maxWidth, child: w),
                ],
              ),
            ),
          );
        }
        return Row(
          spacing: 8,
          children: [
            for (var w in widgets) Expanded(child: w),
          ],
        );
      },
    );
  }

  Builder buildTransitionBurning() {
    return Builder(
      builder: (context) {
        final shaderPath = Assets.transitionBurning;
        final texture1 = Assets.rockTiles;
        final texture2 = Assets.pebbles;
        Widget buildShaderSurface(String title, WrapMode wrap) {
          final buffer = shaderPath.shaderBuffer;
          final assetsInputShader = shaderPath.feed(texture1, wrap: wrap).feed(texture2, wrap: wrap);

          dynamic input1, input2;
          if (useWidgetInput) {
            input1 = Image.asset(
              texture1,
              fit: BoxFit.cover,
            );
            input2 = Image.asset(
              texture2,
              fit: BoxFit.cover,
            );
          } else {
            input1 = texture1;
            input2 = texture2;
          }
          buffer.feed(input1, wrap: wrap);
          buffer.feed(input2, wrap: wrap);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ShaderSurface.auto(
                        assetsInputShader,
                        upSideDown: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final widgets = [
          buildShaderSurface('Clamp', WrapMode.clamp),
          buildShaderSurface('Repeat', WrapMode.repeat),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < narrowWidthThreshold;
            if (isNarrow) {
              return SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 8,
                    children: [
                      for (var w in widgets) SizedBox(height: constraints.maxWidth, child: w),
                    ],
                  ),
                ),
              );
            }
            return Row(
              spacing: 8,
              children: [
                for (var w in widgets) Expanded(child: w),
              ],
            );
          },
        );
      },
    );
  }

  Builder buildTissue() {
    return Builder(
      builder: (_) {
        final shaderPath = Assets.tissue;
        final texture = Assets.abstract1;
        Widget buildShaderSurface(String title, WrapMode wrap) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ShaderSurface.auto(
                        key: ValueKey('$title-$wrap'),
                        shaderPath.feed(
                          texture,
                          wrap: wrap,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final widgets = [
          buildShaderSurface('Clamp', WrapMode.clamp),
          buildShaderSurface('Repeat', WrapMode.repeat),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < narrowWidthThreshold;
            if (isNarrow) {
              return SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 8,
                    children: [
                      for (var w in widgets) SizedBox(height: constraints.maxWidth, child: w),
                    ],
                  ),
                ),
              );
            }
            return Row(
              spacing: 8,
              children: [
                for (var w in widgets) Expanded(child: w),
              ],
            );
          },
        );
      },
    );
  }

  Builder buildBlackHoleODEGeodesicSolver() {
    return Builder(
      builder: (context) {
        final main = Assets.blackHole;
        final texture = Assets.stars;
        Widget shaderSurface(String title, WrapMode wrap, FilterMode filter) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ShaderSurface.auto(
                  main.feed(
                    texture,
                    wrap: wrap,
                    filter: filter,
                  ),
                ),
              ),
            ],
          );
        }

        final widgets = [
          shaderSurface('Clamp', WrapMode.clamp, FilterMode.nearest),
          shaderSurface('Repeat', WrapMode.repeat, FilterMode.nearest),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < narrowWidthThreshold;
            if (isNarrow) {
              return SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 8,
                    children: [
                      for (var w in widgets) SizedBox(height: constraints.maxWidth / 2, child: w),
                    ],
                  ),
                ),
              );
            }
            return Row(
              spacing: 8,
              children: [
                for (var w in widgets)
                  Expanded(
                    child: SizedBox(
                      height: constraints.maxHeight / 2,
                      child: w,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Builder buildBrokenTime() {
    return Builder(
      builder: (context) {
        final main = Assets.brokenTimeGate;
        final texture = Assets.greyNoiseMedium;
        Widget buildShaderSurface(String title, WrapMode wrap, FilterMode filter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ShaderSurface.auto(
                        main.feed(
                          texture,
                          wrap: wrap,
                          filter: filter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final widgets = [
          buildShaderSurface('Clamp Nearest', WrapMode.clamp, FilterMode.nearest),
          buildShaderSurface('Repeat Nearest', WrapMode.repeat, FilterMode.nearest),
          buildShaderSurface('Clamp Linear', WrapMode.clamp, FilterMode.linear),
          buildShaderSurface('Repeat Linear', WrapMode.repeat, FilterMode.linear),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < narrowWidthThreshold;
            int crossAxisCount = isNarrow ? 1 : 2;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 16 / 9,
              ),
              itemCount: widgets.length,
              itemBuilder: (context, index) => widgets[index],
            );
          },
        );
      },
    );
  }

  Builder buildGoodbyeDreamClouds() {
    return Builder(
      builder: (_) {
        final shaderPath = Assets.goodbyeDreamClouds;
        final texture = Assets.rgbaNoiseMedium;
        Widget buildShaderSurface(String title, WrapMode wrap, FilterMode filter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ShaderSurface.auto(
                        key: UniqueKey(),
                        shaderPath.feed(
                          texture,
                          wrap: wrap,
                          filter: filter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final widgets = [
          buildShaderSurface('Clamp Nearest', WrapMode.clamp, FilterMode.nearest),
          buildShaderSurface('Repeat Nearest', WrapMode.repeat, FilterMode.nearest),
          buildShaderSurface('Clamp Linear', WrapMode.clamp, FilterMode.linear),
          buildShaderSurface('Repeat Linear', WrapMode.repeat, FilterMode.linear),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < narrowWidthThreshold;
            int crossAxisCount = isNarrow ? 1 : 2;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 16 / 9,
              ),
              itemCount: widgets.length,
              itemBuilder: (context, index) => widgets[index],
            );
          },
        );
      },
    );
  }
}
