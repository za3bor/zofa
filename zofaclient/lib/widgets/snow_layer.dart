// Snow layer containing multiple snowflakes
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zofa_client/widgets/star_painter.dart';

class SnowLayer extends StatefulWidget {
  const SnowLayer({super.key});
  @override
  State<SnowLayer> createState() {
    return _SnowLayerState();
  }
}

class _SnowLayerState extends State<SnowLayer> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Offset> _snowOffsets;
  late List<double> _snowSpeeds;
  late List<double> _snowSizes;
  late List<double> _snowOpacities;

  @override
  void initState() {
    super.initState();

    // Initialize the snowflakes' offsets, speeds, sizes, and opacities to empty lists.
    _snowOffsets = [];
    _snowSpeeds = [];
    _snowSizes = [];
    _snowOpacities = [];

    // Initialize the animation controller to control the snowflake movement.
    _controller = AnimationController(
      duration:
          const Duration(seconds: 30), // Slower animation for smoother snow
      vsync: this,
    )..repeat();

    // Wait until after the first frame to initialize the snowflakes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Initialize snowflakes with random values
        _snowOffsets = List.generate(50, (index) {
          return Offset(
            Random().nextDouble() *
                MediaQuery.of(context).size.width, // Random X position
            Random().nextDouble() *
                MediaQuery.of(context).size.height, // Random Y position
          );
        });

        _snowSpeeds = List.generate(50, (index) {
          return Random().nextDouble() * 2.0 +
              1.0; // Random speed between 1 and 3
        });

        _snowSizes = List.generate(50, (index) {
          return Random().nextDouble() * 6.0 +
              3.0; // Random size between 3 and 7
        });

        _snowOpacities = List.generate(50, (index) {
          return Random().nextDouble() * 0.5 +
              0.5; // Random opacity between 0.5 and 1
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure that the snowflakes are initialized before rendering.
    if (_snowOffsets.isEmpty || _snowSpeeds.isEmpty) {
      return Container(); // Return an empty container if snowflakes aren't initialized
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update the position of each snowflake based on the controller value.
        for (int i = 0; i < _snowOffsets.length; i++) {
          double newOffsetY = _snowOffsets[i].dy + _snowSpeeds[i];

          // If the snowflake moves off the screen, reset its position to the top.
          if (newOffsetY > MediaQuery.of(context).size.height) {
            newOffsetY = 0.0;
            _snowOffsets[i] = Offset(
              Random().nextDouble() *
                  MediaQuery.of(context)
                      .size
                      .width, // Random X position for the reset
              newOffsetY, // Reset Y position
            );
          } else {
            // Update the Y position of the snowflakes
            _snowOffsets[i] = Offset(_snowOffsets[i].dx, newOffsetY);
          }
        }

        return Stack(
          children: List.generate(
            _snowOffsets.length, // Use the correct length for snowflakes
            (index) {
              return SnowParticle(
                size: _snowSizes[index], // Size for the snowflake
                opacity: _snowOpacities[index], // Opacity for the snowflake
                offset: _snowOffsets[index], // Position of the snowflake
              );
            },
          ),
        );
      },
    );
  }
}
