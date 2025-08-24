import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final String imageUrl;
  final Map<int, int> productQuantities;
  final void Function(int) onIncrement;
  final void Function(int) onDecrement;
  final void Function(int)? onAddToCart;
  final void Function(int, double)? onAddSeedsToCart; // NEW (nullable)

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.productQuantities,
    required this.onIncrement,
    required this.onDecrement,
    this.onAddToCart,
    this.onAddSeedsToCart, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.r),
              topRight: Radius.circular(15.r),
            ),
            child: Hero(
              tag: 'imageHero-${product.id}',
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 148, 105, 90).withAlpha(75),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  height: 150.w,
                  width: double.infinity,
                  placeholder:
                      (context, url) => const CircularProgressIndicator(),
                  errorWidget:
                      (context, url, error) => Image.asset(
                        'assets/noimage.jpg',
                        fit: BoxFit.cover,
                        height: 150.w,
                        width: double.infinity,
                      ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '₪ ${product.price.toStringAsFixed(1)}'
                        '${product.isSeeds == true ? ' / ק״ג' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Visibility(
                        visible:
                            product.isSeeds != true, // show only for non‐seeds
                        maintainSize: true, // ★ keep its layout slot
                        maintainAnimation: true,
                        maintainState: true,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => onIncrement(product.id),
                            ),
                            Text(
                              '${productQuantities[product.id] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => onDecrement(product.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (product.isSeeds == true)
                    // 1) Show a “By weight” button instead
                    ElevatedButton(
                      onPressed: () => _showSeedPicker(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                      ),
                      child: Text(
                        'בחר משקל',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed:
                          product.stock ? () => onAddToCart!(product.id) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            product.stock ? Colors.brown : Colors.grey,
                      ),
                      child: Text(
                        product.stock ? 'הוסף לסל' : 'אזל מהמלאי',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeedPicker(BuildContext context) {
    final weightController = TextEditingController(text: '100');
    final priceController = TextEditingController();
    String mode = 'grams';
    String? inputError; // NEW

    void updatePrice() {
      final grams = double.tryParse(weightController.text);
      if (grams == null || grams <= 0) {
        inputError = 'הכנס ערך גדול מ-0';
        priceController.text = '';
      } else {
        inputError = null;
        final kg = grams / 1000;
        priceController.text = (kg * product.price).toStringAsFixed(2);
      }
    }

    void updateGrams() {
      final price = double.tryParse(priceController.text);
      if (price == null || price <= 0) {
        inputError = 'הכנס ערך גדול מ-0';
        weightController.text = '';
      } else {
        inputError = null;
        final kg = price / product.price;
        weightController.text = (kg * 1000).toStringAsFixed(0);
      }
    }

    updatePrice();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 24.h,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'בחר לפי משקל או מחיר',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggleChip(
                          selected: mode == 'grams',
                          label: 'גרמים',
                          iconData: Icons.scale,
                          onTap: () {
                            setState(() {
                              mode = 'grams';
                              updatePrice();
                            });
                          },
                        ),

                        _buildToggleChip(
                          selected: mode == 'price',
                          label: 'מחיר',
                          iconWidget: _buildShekelIcon(),
                          onTap: () {
                            setState(() {
                              mode = 'price';
                              updateGrams();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Input + Calculated View
                    if (mode == 'grams') ...[
                      _buildInputCard(
                        context,
                        label: 'הזן כמות בגרמים',
                        controller: weightController,
                        suffix: 'גרם',
                        iconData: Icons.scale,
                        onChanged: (_) => setState(updatePrice),
                        errorText: inputError,
                      ),
                      _buildResultCard(
                        'מחיר משוער',
                        '₪ ${priceController.text}',
                      ),
                    ] else ...[
                      _buildInputCard(
                        context,
                        label: 'הזן מחיר',
                        controller: priceController,
                        iconWidget: _buildShekelIcon(),
                        onChanged: (_) => setState(updateGrams),
                        errorText: inputError,
                      ),
                      _buildResultCard(
                        'כמות משוערת',
                        '${weightController.text} גרם',
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Button
                    ElevatedButton.icon(
                      onPressed:
                          inputError != null
                              ? null
                              : () {
                                final grams =
                                    double.tryParse(weightController.text) ?? 0;
                                Navigator.of(ctx).pop();
                                onAddSeedsToCart!(product.id, grams);
                              },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('אישור והוספה לסל'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            inputError != null
                                ? Colors.grey
                                : Colors.brown[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleChip({
    required bool selected,
    required String label,
    IconData? iconData,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.brown[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            if (iconData != null)
              Icon(
                iconData,
                size: 20,
                color: selected ? Colors.brown[800] : Colors.grey,
              )
            else if (iconWidget != null)
              iconWidget,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.brown[800] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    IconData? iconData,
    Widget? iconWidget,
    String? prefix,
    String? suffix,
    required void Function(String) onChanged,
    String? errorText, // NEW
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.brown[700]),
            ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                icon:
                    iconData != null
                        ? Icon(iconData, color: Colors.brown)
                        : iconWidget,
                prefixText: prefix,
                suffixText: suffix,
                errorText: errorText, // NEW
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.brown,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShekelIcon() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Text(
        '₪',
        style: TextStyle(
          fontSize: 18,
          color: Colors.brown[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
