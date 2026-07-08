import 'dart:async';
import 'package:demo_app/features/products/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/shop_cubit.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  final List<String> _recentSearches = ['Sony', 'Apple Watch', 'Nike'];

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<ShopCubit>().state.searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ShopCubit>().search(query.trim());

      final trimmed = query.trim();
      if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
        setState(() {
          _recentSearches.insert(0, trimmed);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ShopCubit>().search('');
  }

  void _applyRecentSearch(String term) {
    _searchController.text = term;
    context.read<ShopCubit>().search(term);
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
        title: Hero(
          tag: 'search_bar_tag',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search exclusive products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      )
                    : null,
                fillColor: theme.colorScheme.surface,
                filled: true,
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(metrics.radius12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(metrics.radius12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          final showRecent =
              _searchController.text.isEmpty && _recentSearches.isNotEmpty;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (showRecent) {
            return Padding(
              padding: EdgeInsets.all(metrics.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Searches',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: metrics.space12),
                  Wrap(
                    spacing: metrics.space8,
                    runSpacing: metrics.space8,
                    children: _recentSearches.map((term) {
                      return ActionChip(
                        label: Text(term),
                        avatar: const Icon(Icons.history, size: 14),
                        onPressed: () => _applyRecentSearch(term),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          if (state.products.isEmpty) {
            return const EmptyView(
              title: 'No Matches Found',
              message:
                  'Try checking your spelling or search for another keyword.',
              icon: Icons.search_off,
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(metrics.space16),
            itemCount: state.products.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: metrics.space12),
            itemBuilder: (context, index) {
              final prod = state.products[index];
              return _SearchListItem(product: prod);
            },
          );
        },
      ),
    );
  }
}

class _SearchListItem extends StatelessWidget {
  final ProductEntity product;
  const _SearchListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.productDetails.replaceAll(':id', product.id)}',
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(product.images.first, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(metrics.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                      SizedBox(height: metrics.space8),
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
                            SizedBox(width: metrics.space8),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
              SizedBox(width: metrics.space12),
            ],
          ),
        ),
      ),
    );
  }
}
