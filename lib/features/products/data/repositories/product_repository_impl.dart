import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/mock_database_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final MockDatabaseService _mockDb;

  ProductRepositoryImpl(this._mockDb);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final list = await _mockDb.query(_mockDb.categories);
    return list.map((e) => CategoryEntity(
          id: e['id'] as String,
          name: e['name'] as String,
          icon: e['icon'] as String,
          parentId: e['parentId'] as String?,
        )).toList();
  }

  @override
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int offset = 0,
  }) async {
    final list = await _mockDb.query(
      _mockDb.products,
      where: (item) {
        if (!(item['isEnabled'] as bool)) return false;
        if (categoryId != null && item['categoryId'] != categoryId) return false;
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.trim().toLowerCase();
          final name = (item['name'] as String).toLowerCase();
          final desc = (item['description'] as String).toLowerCase();
          final sku = ((item['sku'] ?? '') as String).toLowerCase();
          final barcode = ((item['barcode'] ?? '') as String).toLowerCase();
          
          if (!name.contains(query) &&
              !desc.contains(query) &&
              !sku.contains(query) &&
              !barcode.contains(query)) {
            return false;
          }
        }
        return true;
      },
      limit: limit,
      offset: offset,
    );

    return list.map((e) => _mapToProductEntity(e)).toList();
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    final doc = await _mockDb.getDocument(_mockDb.products, id);
    if (doc == null) {
      throw const ServerException('Product not found');
    }
    return _mapToProductEntity(doc);
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts() async {
    final list = await _mockDb.query(_mockDb.products, limit: 3);
    return list.map((e) => _mapToProductEntity(e)).toList();
  }

  @override
  Future<List<ProductEntity>> getFlashSaleProducts() async {
    final list = await _mockDb.query(_mockDb.products, where: (item) => ((item['discount'] as num).toDouble()) > 0.0);
    return list.map((e) => _mapToProductEntity(e)).toList();
  }

  @override
  Future<void> addProductReview(
    String productId,
    String userName,
    double rating,
    String comment,
  ) async {
    final index = _mockDb.products.indexWhere((element) => element['id'] == productId);
    if (index == -1) {
      throw const ServerException('Product not found');
    }
    
    final product = _mockDb.products[index];
    final reviews = List<Map<String, dynamic>>.from(product['reviews'] as List);
    
    reviews.add({
      'userName': userName,
      'rating': rating.toInt(),
      'comment': comment,
      'date': DateTime.now().toIso8601String(),
    });

    double sum = 0;
    for (var r in reviews) {
      sum += (r['rating'] as num).toDouble();
    }
    final avgRating = reviews.isEmpty ? 0.0 : sum / reviews.length;

    product['reviews'] = reviews;
    product['ratings'] = double.parse(avgRating.toStringAsFixed(1));

    // Sync review data to Firestore
    _mockDb.products.syncDocument(productId);
  }

  ProductEntity _mapToProductEntity(Map<String, dynamic> e) {
    final reviews = (e['reviews'] as List)
        .map((r) => ReviewEntity(
              userName: r['userName'] as String,
              rating: (r['rating'] as num).toDouble(),
              comment: r['comment'] as String,
              date: DateTime.parse(r['date'] as String),
            ))
        .toList();

    final rawVariants = e['variants'] as Map;
    final Map<String, List<String>> variants = {};
    rawVariants.forEach((key, value) {
      variants[key.toString()] = List<String>.from(value as List);
    });

    return ProductEntity(
      id: e['id'] as String,
      name: e['name'] as String,
      description: e['description'] as String,
      price: (e['price'] as num).toDouble(),
      discount: (e['discount'] as num).toDouble(),
      categoryId: e['categoryId'] as String,
      stock: e['stock'] as int,
      sku: e['sku'] as String,
      barcode: e['barcode'] as String,
      images: List<String>.from(e['images'] as List),
      variants: variants,
      ratings: (e['ratings'] as num).toDouble(),
      reviews: reviews,
      isEnabled: (e['isEnabled'] as bool?) ?? true,
    );
  }
}
