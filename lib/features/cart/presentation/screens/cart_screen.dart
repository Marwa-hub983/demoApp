import 'package:demo_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Shopping Cart'),
      ),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            return EmptyView(
              title: 'Your Cart is Empty',
              message:
                  'Looks like you haven\'t added any items to your cart yet.',
              icon: Icons.shopping_cart_outlined,
              buttonText: 'Start Shopping',
              onButtonPressed: () => context.go(AppRoutes.home),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(metrics.space16),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              metrics.radius8,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(item.image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: metrics.space16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: metrics.space4),
                              Row(
                                children: [
                                  if (item.selectedColor != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.selectedColor!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: metrics.space8),
                                  ],
                                  if (item.selectedSize != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.selectedSize!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: metrics.space12),
                              // Quantity Picker
                              Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () => context
                                        .read<CartCubit>()
                                        .updateQuantity(
                                          item.productId,
                                          item.selectedColor,
                                          item.selectedSize,
                                          item.quantity - 1,
                                        ),
                                  ),
                                  Text(
                                    item.quantity.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () => context
                                        .read<CartCubit>()
                                        .updateQuantity(
                                          item.productId,
                                          item.selectedColor,
                                          item.selectedSize,
                                          item.quantity + 1,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Price & Delete
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              onPressed: () =>
                                  context.read<CartCubit>().removeFromCart(
                                    item.productId,
                                    item.selectedColor,
                                    item.selectedSize,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom checkout Summary drawer
              Container(
                padding: EdgeInsets.all(metrics.space24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(metrics.radius24),
                    topRight: Radius.circular(metrics.radius24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Promo Input
                    if (state?.couponCode == null)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: CustomTextField(
                                controller: _promoController,
                                hintText: 'Enter promo code (e.g. FLUTTER25)',
                              ),
                            ),
                          ),
                          SizedBox(width: metrics.space12),
                          CustomButton(
                            text: 'Apply',
                            onPressed: () {
                              if (_promoController.text.isNotEmpty) {
                                context.read<CartCubit>().applyCoupon(
                                  _promoController.text.trim(),
                                );
                                _promoController.clear();
                              }
                            },
                            width: 100,
                            height: 48,
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(metrics.radius12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  color: theme.colorScheme.tertiary,
                                  size: 20,
                                ),
                                SizedBox(width: metrics.space8),
                                Text(
                                  'Promo ${state.couponCode} applied (-${state.couponDiscountPercent.toInt()}%)',
                                  style: TextStyle(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.read<CartCubit>().removeCoupon(),
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: metrics.space16),
                    // Summary values
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                        Text(
                          '\$${state.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (state.couponDiscountPercent > 0) ...[
                      SizedBox(height: metrics.space8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Promo Discount',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          Text(
                            '-\$${state.discountAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: metrics.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Tax (8%)',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                        Text(
                          '\$${state.tax.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipping',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                        Text(
                          state.shippingFee == 0.0
                              ? 'FREE'
                              : '\$${state.shippingFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: state.shippingFee == 0.0
                                ? Colors.green
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Estimated',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${state.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.space16),
                    CustomButton(
                      text: 'Proceed to Checkout',
                      onPressed: () => context.push(AppRoutes.checkout),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
