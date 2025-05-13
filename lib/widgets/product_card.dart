import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final String imageUrl;
  final Map<int, int> productQuantities;
  final void Function(int) onIncrement;
  final void Function(int) onDecrement;
  final void Function(int) onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.productQuantities,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
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
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
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
                        '₪ ${product.price.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Row(
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
                    ],
                  ),
                  ElevatedButton(
                    onPressed: product.stock ? () => onAddToCart(product.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.stock ? Colors.brown : Colors.grey,
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
}
