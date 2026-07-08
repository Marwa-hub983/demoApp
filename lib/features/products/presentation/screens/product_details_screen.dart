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
  const ProductDetailsScreen({super.key, required this.id});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductDetailsCubit _cubit;
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  final _reviewFormKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _inputRating = 5;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ProductDetailsCubit>();
    _cubit.loadProductDetails(widget.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(prod.name),
              actions: [
                BlocBuilder<WishlistCubit, WishlistState>(
                  builder: (context, wishlistState) {
                    final isFav = context.read<WishlistCubit>().isFavorite(
                      prod.id,
                    );
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                      ),
                      onPressed: () =>
                          context.read<WishlistCubit>().toggleWishlist(prod),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Image Gallery
                  Hero(
                    tag: 'product_image_${prod.id}',
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: PageView.builder(
                        itemCount: prod.images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            prod.images[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(metrics.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Title & Pricing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: metrics.space4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      SizedBox(width: metrics.space4),
                                      Text(
                                        prod.ratings.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: metrics.space4),
                                      Text(
                                        '(${prod.reviews.length} reviews)',
                                        style: TextStyle(
                                          color: theme.colorScheme.secondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${prod.discountedPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (prod.discount > 0) ...[
                                  SizedBox(height: metrics.space4),
                                  Text(
                                    '\$${prod.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // 3. Description
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
                            color: theme.colorScheme.secondary,
                            height: 1.6,
                          ),
                        ),

                        const Divider(height: 32),

                        // 4. Color Pickers
                        if (colors.isNotEmpty) ...[
                          Text(
                            'Select Color',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: metrics.space12),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: colors.length,
                              itemBuilder: (context, index) {
                                final color = colors[index];
                                final isSelected = _selectedColor == color;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: metrics.space12,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(color),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _selectedColor = color;
                                        });
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: metrics.space16),
                        ],

                        // 5. Size Pickers
                        if (sizes.isNotEmpty) ...[
                          Text(
                            'Select Size',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: metrics.space12),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: sizes.length,
                              itemBuilder: (context, index) {
                                final size = sizes[index];
                                final isSelected = _selectedSize == size;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: metrics.space12,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(size),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _selectedSize = size;
                                        });
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: metrics.space16),
                        ],

                        // 6. Quantity Selector
                        Row(
                          children: [
                            Text(
                              'Quantity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  metrics.radius8,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  Text(
                                    _quantity.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () =>
                                        setState(() => _quantity++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // Specs
                        ExpansionTile(
                          title: const Text(
                            'Specifications',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            ListTile(
                              title: const Text('SKU'),
                              trailing: Text(prod.sku),
                            ),
                            ListTile(
                              title: const Text('Barcode'),
                              trailing: Text(prod.barcode),
                            ),
                            ListTile(
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

                        // 7. Add to Cart Button
                        CustomButton(
                          text: 'Add to Cart',
                          icon: Icons.shopping_cart_outlined,
                          onPressed: () => _onAddToCart(prod),
                        ),

                        const Divider(height: 32),

                        // 8. Reviews List & Review Form
                        Text(
                          'Customer Reviews',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: metrics.space16),

                        // Submission Form
                        Form(
                          key: _reviewFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                          _inputRating = star.toDouble();
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
                                  if (value == null || value.trim().isEmpty) {
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
                                  onPressed: () => _onSubmitReview(prod.id),
                                  isLoading: state.isReviewSubmitting,
                                  width: 150,
                                  height: 40,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: metrics.space24),

                        // Review List view
                        if (prod.reviews.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'No reviews for this product yet. Be the first to review!',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: prod.reviews.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final rev = prod.reviews[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: theme.colorScheme.secondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: metrics.space4),
                                  Row(
                                    children: List.generate(5, (starIdx) {
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

                        // 9. Related Products
                        if (state.related.isNotEmpty) ...[
                          Text(
                            'Related Products',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: metrics.space16),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.related.length,
                              itemBuilder: (context, index) {
                                final relatedProd = state.related[index];
                                return Container(
                                  width: 140,
                                  margin: EdgeInsets.only(
                                    right: metrics.space16,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Force reload details
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
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  relatedProd.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                Text(
                                                  '\$${relatedProd.discountedPrice.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
