import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ProductDetailsState extends Equatable {
  final bool isLoading;
  final ProductEntity? product;
  final List<ProductEntity> related;
  final bool isReviewSubmitting;
  final bool reviewSuccess;
  final String? errorMessage;

  const ProductDetailsState({
    this.isLoading = false,
    this.product,
    this.related = const [],
    this.isReviewSubmitting = false,
    this.reviewSuccess = false,
    this.errorMessage,
  });

  ProductDetailsState copyWith({
    bool? isLoading,
    ProductEntity? product,
    List<ProductEntity>? related,
    bool? isReviewSubmitting,
    bool? reviewSuccess,
    String? errorMessage,
  }) {
    return ProductDetailsState(
      isLoading: isLoading ?? this.isLoading,
      product: product ?? this.product,
      related: related ?? this.related,
      isReviewSubmitting: isReviewSubmitting ?? this.isReviewSubmitting,
      reviewSuccess: reviewSuccess ?? this.reviewSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        product,
        related,
        isReviewSubmitting,
        reviewSuccess,
        errorMessage,
      ];
}

@injectable
class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final ProductRepository _productRepository;

  ProductDetailsCubit(this._productRepository) : super(const ProductDetailsState());

  Future<void> loadProductDetails(String id) async {
    emit(state.copyWith(isLoading: true, reviewSuccess: false, errorMessage: null));
    try {
      final product = await _productRepository.getProductById(id);
      final related = await _productRepository.getProducts(
        categoryId: product.categoryId,
        limit: 4,
      );
      // Filter out current product from related list
      final filteredRelated = related.where((p) => p.id != id).toList();

      emit(state.copyWith(
        isLoading: false,
        product: product,
        related: filteredRelated,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> submitReview({
    required String productId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    emit(state.copyWith(isReviewSubmitting: true, reviewSuccess: false));
    try {
      await _productRepository.addProductReview(productId, userName, rating, comment);
      // Reload product details to update reviews
      final updatedProduct = await _productRepository.getProductById(productId);
      
      emit(state.copyWith(
        isReviewSubmitting: false,
        reviewSuccess: true,
        product: updatedProduct,
      ));
    } catch (e) {
      emit(state.copyWith(isReviewSubmitting: false, errorMessage: e.toString()));
    }
  }
}
