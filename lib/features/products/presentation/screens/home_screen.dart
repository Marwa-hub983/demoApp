import 'package:demo_app/features/products/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';
import '../../../cart/presentation/bloc/cart_cubit.dart';
import '../../../wishlist/presentation/bloc/wishlist_cubit.dart';
import '../bloc/shop_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch
    context.read<ShopCubit>().loadHomeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ShopCubit>().fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<ShopCubit>().loadHomeData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            String name = 'Guest';
            if (state is AuthAuthenticated) {
              name = state.user.fullName.split(' ').first;
            }
            return Row(
              children: [
                Icon(Icons.local_mall, color: theme.colorScheme.primary),
                SizedBox(width: metrics.space8),
                Text(
                  'Hello, $name',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Wishlist Action Button
          IconButton(
            icon: BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, state) {
                final count = state.items.length;
                return Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.favorite_border),
                );
              },
            ),
            onPressed: () => context.push(AppRoutes.wishlist),
          ),
        ],
      ),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const LoadingView(message: 'Curating premium collection...');
          }
          if (state.errorMessage != null && state.products.isEmpty) {
            return ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<ShopCubit>().loadHomeData(),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Search Bar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.space16,
                      vertical: metrics.space8,
                    ),
                    child: Hero(
                      tag: 'search_bar_tag',
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _searchController,
                          readOnly: true,
                          onTap: () => context.push(AppRoutes.search),
                          decoration: InputDecoration(
                            hintText: 'Search exclusive products...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.tune),
                            fillColor: theme.colorScheme.surface,
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                metrics.radius12,
                              ),
                              borderSide: BorderSide(
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Promo Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(metrics.space16),
                    child: Container(
                      padding: EdgeInsets.all(metrics.space24),
                      decoration: BoxDecoration(
                        gradient:
                            theme.colorScheme.brightness == Brightness.light
                            ? const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF334155)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF475569)],
                              ),
                        borderRadius: BorderRadius.circular(metrics.radius16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(
                                metrics.radius4,
                              ),
                            ),
                            child: const Text(
                              'LIMITED PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.space12),
                          const Text(
                            'Get 25% Off Storewide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: metrics.space4),
                          Text(
                            'Use code FLUTTER25 at checkout.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Category Chip Selector
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.space16,
                      ),
                      itemCount: state.categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final CategoryEntity? cat = isAll
                            ? null
                            : state.categories[index - 1];
                        final isSelected = isAll
                            ? state.selectedCategoryId == null
                            : state.selectedCategoryId == cat?.id;

                        return Padding(
                          padding: EdgeInsets.only(right: metrics.space8),
                          child: ChoiceChip(
                            label: Text(isAll ? 'All Products' : cat!.name),
                            selected: isSelected,
                            onSelected: (_) {
                              context.read<ShopCubit>().selectCategory(
                                isAll ? null : cat!.id,
                              );
                            },
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 4. Flash Sale Headers
                if (state.flashSale.isNotEmpty &&
                    state.selectedCategoryId == null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: metrics.space16,
                        right: metrics.space16,
                        top: metrics.space24,
                        bottom: metrics.space12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Flash Sale',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                              SizedBox(width: metrics.space4),
                              Text(
                                '04:12:00',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Flash Sale Horizontal List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: metrics.space16,
                        ),
                        itemCount: state.flashSale.length,
                        itemBuilder: (context, index) {
                          final prod = state.flashSale[index];
                          return Container(
                            width: 160,
                            margin: EdgeInsets.only(right: metrics.space16),
                            child: _ProductItemCard(product: prod),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // 5. Recommended / All Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: metrics.space16,
                      top: metrics.space24,
                      bottom: metrics.space12,
                    ),
                    child: Text(
                      state.selectedCategoryId == null
                          ? 'Recommended For You'
                          : 'Catalog Products',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: metrics.space16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _ProductItemCard(product: state.products[index]);
                    }, childCount: state.products.length),
                  ),
                ),

                // Pagination Loading Shimmers
                if (state.isMoreLoading)
                  SliverPadding(
                    padding: EdgeInsets.all(metrics.space16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardSkeleton(),
                        childCount: 2,
                      ),
                    ),
                  ),

                // Space bottom
                SliverToBoxAdapter(child: SizedBox(height: metrics.space48)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    final heroTag = 'product_image_${product.id}';

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.productDetails.replaceAll(':id', product.id)}?heroTag=$heroTag',
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Hero Image
                  Hero(
                    tag: heroTag,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(product.images.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Discount Label Badge
                  if (product.discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Low Stock Badge
                  if (product.isLowStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(metrics.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: metrics.space4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      SizedBox(width: metrics.space4),
                      Text(
                        product.ratings.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.space4),
                  Row(
                    children: [
                      Text(
                        '\$${product.discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discount > 0) ...[
                        SizedBox(width: metrics.space4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
