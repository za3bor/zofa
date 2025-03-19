import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zofa_client/widgets/ramadan/ramadan_particle.dart';

class RamadanLayer extends StatefulWidget {
  const RamadanLayer({super.key});

  @override
  State<RamadanLayer> createState() => _RamadanLayerState();
}

class _RamadanLayerState extends State<RamadanLayer>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Offset> _objectOffsets;
  late List<double> _objectSpeeds;
  late List<double> _objectSizes;
  late List<double> _objectOpacities;
  late List<String> _objectTypes;

  @override
  void initState() {
    super.initState();

    _objectOffsets = [];
    _objectSpeeds = [];
    _objectSizes = [];
    _objectOpacities = [];
    _objectTypes = [];

    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        for (int i = 0; i < 25; i++) {
          _objectOffsets.add(Offset(
            Random().nextDouble() * MediaQuery.of(context).size.width,
            Random().nextDouble() * MediaQuery.of(context).size.height,
          ));

          _objectSpeeds.add(Random().nextDouble() * 1.5 + 0.5);
          _objectSizes.add(Random().nextDouble() * 25.0 + 25.0);
          _objectOpacities.add(Random().nextDouble() * 0.5 + 0.5);

          // Randomly assign a type: moon, star, or lantern
          _objectTypes.add(['moon', 'star', 'lantern'][Random().nextInt(3)]);
        }
      });
    });
  }

  String _getAssetPathForType(String type) {
    switch (type) {
      case 'moon':
        return 'assets/ramadan/crescent.png';
      case 'star':
        return 'assets/ramadan/star.png';
      case 'lantern':
        return 'assets/ramadan/lantern.png';
      default:
        return 'assets/ramadan/default.png'; // Fallback in case of an error
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_objectOffsets.isEmpty) return Container();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (int i = 0; i < _objectOffsets.length; i++) {
          double newOffsetY = _objectOffsets[i].dy + _objectSpeeds[i];
          if (newOffsetY > MediaQuery.of(context).size.height) {
            newOffsetY = 0.0;
            _objectOffsets[i] = Offset(
              Random().nextDouble() * MediaQuery.of(context).size.width,
              newOffsetY,
            );
          } else {
            _objectOffsets[i] = Offset(_objectOffsets[i].dx, newOffsetY);
          }
        }

        return Stack(
          children: List.generate(
            _objectOffsets.length,
            (index) => RamadanParticle(
              size: _objectSizes[index],
              opacity: _objectOpacities[index],
              offset: _objectOffsets[index],
              assetPath: _getAssetPathForType(_objectTypes[index]), // Fix
            ),
          ),
        );
      },
    );
  }
}
