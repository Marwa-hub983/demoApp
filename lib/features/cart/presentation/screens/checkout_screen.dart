import 'package:demo_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';
import '../../../orders/presentation/bloc/orders_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _orderPlaced = false;

  @override
  void initState() {
    super.initState();
    // Reset order state to start with clean flags
    context.read<OrdersCubit>().resetOrderState();

    // Pre-populate address if available
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated && auth.user.addresses.isNotEmpty) {
      final addr = auth.user.addresses.first;
      _streetController.text = addr.street;
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _zipController.text = addr.zipCode;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _onPlaceOrder(CartState cart, String userId) {
    if (_formKey.currentState!.validate()) {
      context.read<OrdersCubit>().placeOrder(
        userId: userId,
        cartItems: cart.items,
        subtotal: cart.subtotal,
        tax: cart.tax,
        shipping: cart.shippingFee,
        total: cart.total,
        address: {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zipCode': _zipController.text.trim(),
          'country': 'USA',
        },
        paymentMethod: _selectedPaymentMethod,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    final auth = context.read<AuthCubit>().state;

    if (auth is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Please authenticate first')),
      );
    }

    final cart = context.read<CartCubit>().state;
    final userId = auth.user.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout Details'),
      ),
      body: BlocConsumer<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state.orderSuccess) {
            setState(() {
              _orderPlaced = true;
            });
            // Clear cart upon ordering
            context.read<CartCubit>().clearCart();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_orderPlaced) {
            return Padding(
              padding: EdgeInsets.all(metrics.space24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(metrics.space24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: metrics.space24),
                    const Text(
                      'Order Placed Successfully!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: metrics.space8),
                    Text(
                      'Your order has been logged and stock values updated. You can review shipment details in your orders dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: metrics.space32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          text: 'View Orders',
                          onPressed: () {
                            context.read<OrdersCubit>().loadOrders(userId);
                            context.go(AppRoutes.orders);
                          },
                          width: 140,
                        ),
                        SizedBox(width: metrics.space16),
                        CustomButton(
                          text: 'Go Home',
                          isOutlined: true,
                          onPressed: () => context.go(AppRoutes.home),
                          width: 140,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.isLoading) {
            return const LoadingView(
              message: 'Securing transaction credentials...',
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(metrics.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Shipping Address Section
                  Text(
                    'Shipping Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: metrics.space16),
                  CustomTextField(
                    controller: _streetController,
                    labelText: 'Street Address',
                    prefixIcon: Icons.home_outlined,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter street address' : null,
                  ),
                  SizedBox(height: metrics.space12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _cityController,
                          labelText: 'City',
                          prefixIcon: Icons.location_city_outlined,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter city' : null,
                        ),
                      ),
                      SizedBox(width: metrics.space12),
                      Expanded(
                        child: CustomTextField(
                          controller: _stateController,
                          labelText: 'State',
                          validator: (value) =>
                              value!.isEmpty ? 'Enter state' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.space12),
                  CustomTextField(
                    controller: _zipController,
                    labelText: 'Zip / Postal Code',
                    prefixIcon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter zip code' : null,
                  ),

                  // const Divider(height: 32),

                  // 2. Payment Method
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: metrics.space12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'Cash on Delivery';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.space16,
                        vertical: metrics.space12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'Cash on Delivery'
                            ? theme.colorScheme.primary.withOpacity(0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(metrics.radius12),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'Cash on Delivery'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money_outlined,
                            color: _selectedPaymentMethod == 'Cash on Delivery'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                          SizedBox(width: metrics.space12),
                          const Text(
                            'Cash on Delivery',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Radio<String>(
                            value: 'Cash on Delivery',
                            groupValue: _selectedPaymentMethod,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentMethod = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.space12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'Card on Delivery';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.space16,
                        vertical: metrics.space12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'Card on Delivery'
                            ? theme.colorScheme.primary.withOpacity(0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(metrics.radius12),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'Card on Delivery'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.credit_card_outlined,
                            color: _selectedPaymentMethod == 'Card on Delivery'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                          SizedBox(width: metrics.space12),
                          const Text(
                            'Card on Delivery',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Radio<String>(
                            value: 'Card on Delivery',
                            groupValue: _selectedPaymentMethod,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentMethod = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  //  const Divider(height: 32),
                  SizedBox(height: metrics.space12),
                  // 4. Order Summary Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(metrics.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: metrics.space12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items subtotal',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              Text('\$${cart.subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (cart.couponDiscountPercent > 0) ...[
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
                                  '-\$${cart.discountAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
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
                                'Tax (8%)',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              Text('\$${cart.tax.toStringAsFixed(2)}'),
                            ],
                          ),
                          SizedBox(height: metrics.space8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shipping Fee',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              Text(
                                cart.shippingFee == 0.0
                                    ? 'FREE'
                                    : '\$${cart.shippingFee.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Payment',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${cart.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: metrics.space24),

                  CustomButton(
                    text: 'Confirm & Place Order',
                    onPressed: () => _onPlaceOrder(cart, userId),
                  ),
                  SizedBox(height: metrics.space32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
