import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../../core/services/cache_service.dart';
import '../../../products/domain/repositories/product_repository.dart';

class WishlistState extends Equatable {
  final List<ProductEntity> items;
  final bool isLoading;

  const WishlistState({this.items = const [], this.isLoading = false});

  @override
  List<Object?> get props => [items, isLoading];
}

@lazySingleton
class WishlistCubit extends Cubit<WishlistState> {
  final CacheService _cache;
  final ProductRepository _productRepository;
  static const String _wishlistKey = 'user_favorites_list';

  WishlistCubit(this._cache, this._productRepository) : super(const WishlistState()) {
    _loadWishlist();
  }

  void _loadWishlist() async {
    final ids = _cache.read(_wishlistKey) as List<dynamic>?;
    if (ids == null || ids.isEmpty) return;

    emit(const WishlistState(isLoading: true));
    try {
      final List<ProductEntity> list = [];
      for (var id in ids) {
        try {
          final prod = await _productRepository.getProductById(id.toString());
          list.add(prod);
        } catch (_) {}
      }
      emit(WishlistState(items: list, isLoading: false));
    } catch (_) {
      emit(const WishlistState(isLoading: false));
    }
  }

  Future<void> toggleWishlist(ProductEntity product) async {
    final currentList = List<ProductEntity>.from(state.items);
    final exists = currentList.any((e) => e.id == product.id);

    if (exists) {
      currentList.removeWhere((e) => e.id == product.id);
    } else {
      currentList.add(product);
    }

    emit(WishlistState(items: currentList));
    final ids = currentList.map((e) => e.id).toList();
    await _cache.save(_wishlistKey, ids);
  }

  bool isFavorite(String id) {
    return state.items.any((e) => e.id == id);
  }
}
