import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int offset = 0,
  });
  Future<ProductEntity> getProductById(String id);
  Future<List<ProductEntity>> getFeaturedProducts();
  Future<List<ProductEntity>> getFlashSaleProducts();
  Future<void> addProductReview(String productId, String userName, double rating, String comment);
}
