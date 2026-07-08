import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ShopState extends Equatable {
  final bool isLoading;
  final bool isMoreLoading;
  final List<CategoryEntity> categories;
  final List<ProductEntity> featured;
  final List<ProductEntity> flashSale;
  final List<ProductEntity> products;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool hasReachedMax;
  final String? errorMessage;

  const ShopState({
    this.isLoading = false,
    this.isMoreLoading = false,
    this.categories = const [],
    this.featured = const [],
    this.flashSale = const [],
    this.products = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.hasReachedMax = false,
    this.errorMessage,
  });

  ShopState copyWith({
    bool? isLoading,
    bool? isMoreLoading,
    List<CategoryEntity>? categories,
    List<ProductEntity>? featured,
    List<ProductEntity>? flashSale,
    List<ProductEntity>? products,
    String? selectedCategoryId,
    String? searchQuery,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return ShopState(
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      categories: categories ?? this.categories,
      featured: featured ?? this.featured,
      flashSale: flashSale ?? this.flashSale,
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId != null 
          ? (selectedCategoryId == 'all' ? null : selectedCategoryId)
          : this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
    );
  }

  // Helper to force clean selected category
  ShopState clearCategory() {
    return ShopState(
      isLoading: isLoading,
      isMoreLoading: isMoreLoading,
      categories: categories,
      featured: featured,
      flashSale: flashSale,
      products: products,
      selectedCategoryId: null,
      searchQuery: searchQuery,
      hasReachedMax: hasReachedMax,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isMoreLoading,
        categories,
        featured,
        flashSale,
        products,
        selectedCategoryId,
        searchQuery,
        hasReachedMax,
        errorMessage,
      ];
}

@lazySingleton
class ShopCubit extends Cubit<ShopState> {
  final ProductRepository _productRepository;
  static const int _pageSize = 6;

  ShopCubit(this._productRepository) : super(const ShopState());

  Future<void> loadHomeData({bool refresh = false}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final categories = await _productRepository.getCategories();
      final featured = await _productRepository.getFeaturedProducts();
      final flashSale = await _productRepository.getFlashSaleProducts();
      final products = await _productRepository.getProducts(
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
        limit: _pageSize,
        offset: 0,
      );

      emit(state.copyWith(
        isLoading: false,
        categories: categories,
        featured: featured,
        flashSale: flashSale,
        products: products,
        hasReachedMax: products.length < _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> fetchNextPage() async {
    if (state.hasReachedMax || state.isMoreLoading || state.isLoading) return;

    emit(state.copyWith(isMoreLoading: true));
    try {
      final nextProducts = await _productRepository.getProducts(
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
        limit: _pageSize,
        offset: state.products.length,
      );

      emit(state.copyWith(
        isMoreLoading: false,
        products: List.of(state.products)..addAll(nextProducts),
        hasReachedMax: nextProducts.length < _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(isMoreLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> selectCategory(String? categoryId) async {
    if (categoryId == state.selectedCategoryId) return;
    
    final newState = categoryId == null 
        ? state.clearCategory() 
        : state.copyWith(selectedCategoryId: categoryId);
        
    emit(newState.copyWith(isLoading: true, products: const []));
    
    try {
      final products = await _productRepository.getProducts(
        categoryId: newState.selectedCategoryId,
        searchQuery: state.searchQuery,
        limit: _pageSize,
        offset: 0,
      );
      emit(newState.copyWith(
        isLoading: false,
        products: products,
        hasReachedMax: products.length < _pageSize,
      ));
    } catch (e) {
      emit(newState.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(searchQuery: query, isLoading: true, products: const []));
    try {
      final products = await _productRepository.getProducts(
        categoryId: state.selectedCategoryId,
        searchQuery: query,
        limit: _pageSize,
        offset: 0,
      );
      emit(state.copyWith(
        isLoading: false,
        products: products,
        hasReachedMax: products.length < _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
