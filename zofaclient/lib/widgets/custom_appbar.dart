import 'package:flutter/material.dart';
import 'package:zofa_client/widgets/christmas/snow_layer.dart';
import 'package:zofa_client/widgets/easter/easter_layer.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0.0;
  final double _imageWidth = 40.0; // Width of each image

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    bool isEaster = currentDate.month == 3;
    bool isChristmas = currentDate.month == 12;
    bool canPop = Navigator.of(context).canPop();

    return AppBar(
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      flexibleSpace: isEaster
          ? const EasterLayer()
          : isChristmas
              ? const SnowLayer()
              : null,
      title: LayoutBuilder(
        builder: (context, constraints) {
          double availableWidth = constraints.maxWidth - (canPop ? 56 : 0); // Account for back button

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox =
                _textKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              setState(() {
                _textWidth = renderBox.size.width;
              });
            }
          });

          // Check if images fit
          bool showImages = _textWidth + (_imageWidth * 2) < availableWidth - 32;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left image (only if there's space)
              if (showImages && isEaster)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(
                    'assets/easter/easter-day.png',
                    width: _imageWidth,
                    height: _imageWidth,
                  ),
                ),
              if (showImages && isChristmas)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(
                    'assets/christmas/candy-cane.png',
                    width: _imageWidth,
                    height: _imageWidth,
                  ),
                ),

              // Title (always centered)
              Flexible(
                child: Text(
                  widget.title,
                  key: _textKey,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              // Right image (only if there's space)
              if (showImages && isEaster)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset(
                    'assets/easter/rabbit.png',
                    width: _imageWidth,
                    height: _imageWidth,
                  ),
                ),
              if (showImages && isChristmas)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset(
                    'assets/christmas/christmas-tree.png',
                    width: _imageWidth,
                    height: _imageWidth,
                  ),
                ),
            ],
          );
        },
      ),
      centerTitle: true,
    );
  }
}
