import 'dart:async';
import 'package:demo_app/features/products/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';
import '../../../cart/presentation/bloc/cart_cubit.dart';
import '../../../wishlist/presentation/bloc/wishlist_cubit.dart';
import '../bloc/product_details_cubit.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String id;
  final String heroTag;
  const ProductDetailsScreen({super.key, required this.id, this.heroTag = ''});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductDetailsCubit _cubit;
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;
  int _currentImageIndex = 0;

  late final PageController _pageController;
  Timer? _autoPlayTimer;

  final _reviewFormKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _inputRating = 5;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ProductDetailsCubit>();
    _cubit.loadProductDetails(widget.id);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay(int totalImages) {
    _autoPlayTimer?.cancel();
    if (totalImages <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      int nextPageIndex = _currentImageIndex + 1;
      if (nextPageIndex >= totalImages) {
        nextPageIndex = 0;
      }
      _pageController.animateToPage(
        nextPageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onAddToCart(ProductEntity product) {
    context.read<CartCubit>().addToCart(
      CartItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        discount: product.discount,
        image: product.images.first,
        selectedColor: _selectedColor,
        selectedSize: _selectedSize,
        quantity: _quantity,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ),
    );
  }

  void _onSubmitReview(String productId) {
    if (_reviewFormKey.currentState!.validate()) {
      final auth = context.read<AuthCubit>().state;
      String name = 'Anonymous User';
      if (auth is AuthAuthenticated) {
        name = auth.user.fullName;
      }

      _cubit.submitReview(
        productId: productId,
        userName: name,
        rating: _inputRating,
        comment: _commentController.text.trim(),
      );
      _commentController.clear();
    }
  }

  Color _parseColorName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('midnight')) return const Color(0xFF0F172A);
    if (lower.contains('starlight')) return const Color(0xFFF1F5F9);
    if (lower.contains('red')) return Colors.red[700]!;
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('silver')) return const Color(0xFFCBD5E1);
    if (lower.contains('charcoal')) return const Color(0xFF334155);
    if (lower.contains('ash')) return const Color(0xFF94A3B8);
    if (lower.contains('brown')) return Colors.brown[600]!;
    if (lower.contains('tan')) return const Color(0xFFD2B48C);
    if (lower.contains('white')) return Colors.white;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return BlocProvider(
      create: (context) => _cubit,
      child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingView(
              message: 'Retrieving product specification...',
            );
          }
          if (state.errorMessage != null || state.product == null) {
            return ErrorView(
              message: state.errorMessage ?? 'Product details not found',
              onRetry: () => _cubit.loadProductDetails(widget.id),
            );
          }

          final prod = state.product!;

          // Start auto-play for product images carousel
          if (_autoPlayTimer == null && prod.images.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startAutoPlay(prod.images.length);
            });
          }

          // Initialize variants
          final colors = prod.variants['colors'] ?? [];
          final sizes = prod.variants['sizes'] ?? [];
          if (_selectedColor == null && colors.isNotEmpty) {
            _selectedColor = colors.first;
          }
          if (_selectedSize == null && sizes.isNotEmpty) {
            _selectedSize = sizes.first;
          }

          return Scaffold(
            body: Stack(
              children: [
                // 1. Background image PageView (Height: 380)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380,
                  child: Hero(
                    tag: widget.heroTag.isEmpty ? 'product_image_${prod.id}' : widget.heroTag,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: prod.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          prod.images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),

                // 2. Dots indicators on top of image
                if (prod.images.length > 1)
                  Positioned(
                    top: 330,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        prod.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? theme.colorScheme.primary
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Scrollable content overlay sheet
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Space matching background image height minus rounded overlap
                        const SizedBox(height: 350),

                        // White details panel
                        Material(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.space24,
                              vertical: metrics.space24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // category tag
                                Text(
                                  (prod.categoryId
                                          .replaceAll('cat_', '')
                                          .toUpperCase()) +
                                      ' SERIES',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: metrics.space8),
                                Text(
                                  prod.name,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                ),
                                SizedBox(height: metrics.space16),

                                // Rating + Pricing Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 18,
                                          color: Colors.amber[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${prod.ratings}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${prod.reviews.length} reviews)',
                                          style: TextStyle(
                                            color: theme.colorScheme.secondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        if (prod.discount > 0) ...[
                                          Text(
                                            '\$${prod.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          '\$${prod.discountedPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Divider(height: 32),

                                // Description
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: metrics.space8),
                                Text(
                                  prod.description,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                    fontSize: 14,
                                  ),
                                ),

                                const Divider(height: 32),

                                // Color selection (circles)
                                if (colors.isNotEmpty) ...[
                                  Text(
                                    'Select Color',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: metrics.space12),
                                  SizedBox(
                                    height: 48,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: colors.length,
                                      itemBuilder: (context, index) {
                                        final colorName = colors[index];
                                        final colorHex = _parseColorName(
                                          colorName,
                                        );
                                        final isSelected =
                                            _selectedColor == colorName;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedColor = colorName;
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12.0,
                                            ),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: colorHex,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .primary
                                                      : theme
                                                            .colorScheme
                                                            .outlineVariant
                                                            .withOpacity(0.5),
                                                  width: isSelected ? 3 : 1,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: theme
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.2),
                                                          blurRadius: 6,
                                                          spreadRadius: 2,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: isSelected
                                                  ? Icon(
                                                      Icons.check,
                                                      color:
                                                          colorHex ==
                                                              Colors.white
                                                          ? Colors.black
                                                          : Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: metrics.space16),
                                ],

                                // Size Selection
                                if (sizes.isNotEmpty) ...[
                                  Text(
                                    'Select Size',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: metrics.space12),
                                  SizedBox(
                                    height: 42,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: sizes.length,
                                      itemBuilder: (context, index) {
                                        final size = sizes[index];
                                        final isSelected =
                                            _selectedSize == size;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedSize = size;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                          .colorScheme
                                                          .outlineVariant,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                size,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimary
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: metrics.space16),
                                ],

                                // Quantity
                                Row(
                                  children: [
                                    Text(
                                      'Quantity',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme
                                              .colorScheme
                                              .outlineVariant
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 18,
                                            ),
                                            onPressed: _quantity > 1
                                                ? () => setState(
                                                    () => _quantity--,
                                                  )
                                                : null,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                            ),
                                            child: Text(
                                              _quantity.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                setState(() => _quantity++),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 32),

                                // Specifications
                                ExpansionTile(
                                  title: const Text(
                                    'Specifications',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  tilePadding: EdgeInsets.zero,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('SKU'),
                                      trailing: Text(prod.sku),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Barcode'),
                                      trailing: Text(prod.barcode),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Stock Availability'),
                                      trailing: Text(
                                        '${prod.stock} units remaining',
                                        style: TextStyle(
                                          color: prod.isLowStock
                                              ? theme.colorScheme.error
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 32),

                                // Reviews
                                Text(
                                  'Customer Reviews',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: metrics.space16),

                                // Submit review form
                                Form(
                                  key: _reviewFormKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Your Rating: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ...List.generate(5, (index) {
                                            final star = index + 1;
                                            return IconButton(
                                              icon: Icon(
                                                _inputRating >= star
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber[700],
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _inputRating = star
                                                      .toDouble();
                                                });
                                              },
                                            );
                                          }),
                                        ],
                                      ),
                                      SizedBox(height: metrics.space8),
                                      CustomTextField(
                                        controller: _commentController,
                                        labelText: 'Write your review...',
                                        prefixIcon: Icons.rate_review_outlined,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter comment text';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: metrics.space8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: CustomButton(
                                          text: 'Submit Review',
                                          onPressed: () =>
                                              _onSubmitReview(prod.id),
                                          isLoading: state.isReviewSubmitting,
                                          width: 150,
                                          height: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: metrics.space24),

                                if (prod.reviews.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Text(
                                      'No reviews for this product yet. Be the first to review!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: prod.reviews.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 24),
                                    itemBuilder: (context, index) {
                                      final rev = prod.reviews[index];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                rev.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${rev.date.day}/${rev.date.month}/${rev.date.year}',
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: metrics.space4),
                                          Row(
                                            children: List.generate(5, (
                                              starIdx,
                                            ) {
                                              return Icon(
                                                rev.rating > starIdx
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                size: 14,
                                                color: Colors.amber[700],
                                              );
                                            }),
                                          ),
                                          SizedBox(height: metrics.space8),
                                          Text(
                                            rev.comment,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                const Divider(height: 32),

                                // Related products
                                if (state.related.isNotEmpty) ...[
                                  Text(
                                    'Related Products',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: metrics.space16),
                                  SizedBox(
                                    height: 220,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.related.length,
                                      itemBuilder: (context, index) {
                                        final relatedProd =
                                            state.related[index];
                                        return Container(
                                          width: 140,
                                          margin: EdgeInsets.only(
                                            right: metrics.space16,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              context.pushReplacement(
                                                '${AppRoutes.productDetails.replaceAll(':id', relatedProd.id)}',
                                              );
                                            },
                                            child: Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    child: Image.network(
                                                      relatedProd.images.first,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(
                                                      metrics.space8,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          relatedProd.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                        Text(
                                                          '\$${relatedProd.discountedPrice.toStringAsFixed(2)}',
                                                          style: TextStyle(
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Floating transparent AppBar overlay (Back + Share button)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipOval(
                            child: Material(
                              color: Colors.black38,
                              child: InkWell(
                                onTap: () => context.pop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ClipOval(
                            child: Material(
                              color: Colors.black38,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Shared Link for ${prod.name} copied!',
                                      ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  BlocBuilder<WishlistCubit, WishlistState>(
                    builder: (context, wishlistState) {
                      final isFav = context.read<WishlistCubit>().isFavorite(
                        prod.id,
                      );
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () =>
                            context.read<WishlistCubit>().toggleWishlist(prod),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      color: const Color(0xFF059669),
                      text: 'Add to Cart',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () => _onAddToCart(prod),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
