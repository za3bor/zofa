import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zofa_client/widgets/easter/eater_egg_particle.dart';

class EasterLayer extends StatefulWidget {
  const EasterLayer({super.key});

  @override
  State<EasterLayer> createState() => _EasterLayerState();
}

class _EasterLayerState extends State<EasterLayer> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Offset> _eggOffsets;
  late List<double> _eggSpeeds;
  late List<double> _eggSizes;
  late List<double> _eggOpacities;
  late List<Color> _eggBaseColors;
  late List<List<Color>> _eggDecorationColors;

  @override
  void initState() {
    super.initState();

    _eggOffsets = [];
    _eggSpeeds = [];
    _eggSizes = [];
    _eggOpacities = [];
    _eggBaseColors = [];
    _eggDecorationColors = [];

    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        for (int i = 0; i < 30; i++) {
          _eggOffsets.add(Offset(
            Random().nextDouble() * MediaQuery.of(context).size.width,
            Random().nextDouble() * MediaQuery.of(context).size.height,
          ));

          _eggSpeeds.add(Random().nextDouble() * 2.0 + 1.0);
          _eggSizes.add(Random().nextDouble() * 20.0 + 30.0);
          _eggOpacities.add(Random().nextDouble() * 0.5 + 0.5);

          _eggBaseColors.add(_getRandomPastelColor());
          _eggDecorationColors.add([
            _getRandomPastelColor(),
            _getRandomPastelColor(),
          ]);
        }
      });
    });
  }

  Color _getRandomPastelColor() {
    List<Color> pastelColors = [
      Colors.pink.shade200,
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.yellow.shade200,
      Colors.purple.shade200,
      Colors.orange.shade200,
    ];
    return pastelColors[Random().nextInt(pastelColors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_eggOffsets.isEmpty) return Container();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (int i = 0; i < _eggOffsets.length; i++) {
          double newOffsetY = _eggOffsets[i].dy + _eggSpeeds[i];
          double waveOffsetX = sin(_controller.value * 2 * pi) * 2.0;

          if (newOffsetY > MediaQuery.of(context).size.height) {
            newOffsetY = 0.0;
            _eggOffsets[i] = Offset(
              Random().nextDouble() * MediaQuery.of(context).size.width,
              newOffsetY,
            );
          } else {
            _eggOffsets[i] = Offset(_eggOffsets[i].dx + waveOffsetX, newOffsetY);
          }
        }

        return Stack(
          children: List.generate(
            _eggOffsets.length,
            (index) => EasterEggParticle(
              size: _eggSizes[index],
              opacity: _eggOpacities[index],
              offset: _eggOffsets[index],
              baseColor: _eggBaseColors[index],
              decorationColors: _eggDecorationColors[index],
            ),
          ),
        );
      },
    );
  }
}
