import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductListCard extends StatelessWidget {
  final dynamic product;
  final String imageUrl;
  final Map<int, int> productQuantities;
  final void Function(int) onIncrement;
  final void Function(int) onDecrement;
  final void Function(int)? onAddToCart;
  final void Function(int, double)? onAddSeedsToCart;

  const ProductListCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.productQuantities,
    required this.onIncrement,
    required this.onDecrement,
    this.onAddToCart,
    this.onAddSeedsToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Fixed size
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
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
                    height: 80.w,
                    width: 80.w,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/noimage.jpg',
                      fit: BoxFit.cover,
                      height: 80.w,
                      width: 80.w,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Product Details - Flexible
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 6.h),
                  
                  Text(
                    '₪ ${product.price.toStringAsFixed(1)}'
                    '${product.isSeeds == true ? ' / ק״ג' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown[700],
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Quantity controls or weight button
                  if (product.isSeeds != true) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => onDecrement(product.id),
                          iconSize: 20.sp,
                          color: Colors.brown[600],
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.h,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.brown[200]!),
                          ),
                          child: Text(
                            '${productQuantities[product.id] ?? 0}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onIncrement(product.id),
                          iconSize: 20.sp,
                          color: Colors.brown[600],
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // Action Button - Fixed size
            SizedBox(
              width: 80.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product.isSeeds == true)
                    ElevatedButton(
                      onPressed: () => _showSeedPicker(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'בחר משקל',
                        style: TextStyle(fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: product.stock ? () => onAddToCart!(product.id) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.stock ? Colors.brown[600] : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        product.stock ? 'הוסף לסל' : 'אזל מהמלאי',
                        style: TextStyle(fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeedPicker(BuildContext context) {
    final weightController = TextEditingController(text: '100');
    final priceController = TextEditingController();
    String mode = 'grams';
    String? inputError;

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
                    Text(
                      'בחר לפי משקל או מחיר',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 24),

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

                    ElevatedButton.icon(
                      onPressed: inputError != null
                          ? null
                          : () {
                              final grams = double.tryParse(weightController.text) ?? 0;
                              Navigator.of(ctx).pop();
                              onAddSeedsToCart!(product.id, grams);
                            },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('אישור והוספה לסל'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inputError != null ? Colors.grey : Colors.brown[700],
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
          boxShadow: selected
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
    String? errorText,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.brown[700]),
            ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                icon: iconData != null ? Icon(iconData, color: Colors.brown) : iconWidget,
                prefixText: prefix,
                suffixText: suffix,
                errorText: errorText,
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
