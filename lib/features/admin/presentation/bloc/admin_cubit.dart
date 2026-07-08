import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/mock_database_service.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../orders/presentation/bloc/orders_cubit.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final List<OrderEntity> orders;
  final List<Map<String, dynamic>> stockLogs;
  final String? errorMessage;

  const AdminState({
    this.isLoading = false,
    this.products = const [],
    this.categories = const [],
    this.orders = const [],
    this.stockLogs = const [],
    this.errorMessage,
  });

  // KPI Calculations
  double get totalRevenue => orders
      .where((o) => o.status != 'cancelled')
      .fold(0.0, (sum, o) => sum + (o.summary['total'] ?? 0.0));

  int get pendingOrdersCount => orders.where((o) => o.status == 'pending').length;

  int get lowStockProductsCount => products.where((p) => p.isLowStock).length;

  List<ProductEntity> get lowStockProducts => products.where((p) => p.isLowStock).toList();

  Map<String, double> get categorySalesData {
    final Map<String, double> data = {};
    for (var o in orders) {
      if (o.status == 'cancelled') continue;
      for (var item in o.items) {
        final prod = products.where((p) => p.id == item.productId).toList();
        if (prod.isNotEmpty) {
          final catId = prod.first.categoryId;
          data[catId] = (data[catId] ?? 0.0) + (item.price * item.quantity);
        }
      }
    }
    return data;
  }

  AdminState copyWith({
    bool? isLoading,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    List<OrderEntity>? orders,
    List<Map<String, dynamic>>? stockLogs,
    String? errorMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      orders: orders ?? this.orders,
      stockLogs: stockLogs ?? this.stockLogs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, products, categories, orders, stockLogs, errorMessage];
}

@lazySingleton
class AdminCubit extends Cubit<AdminState> {
  final MockDatabaseService _mockDb;

  AdminCubit(this._mockDb) : super(const AdminState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Load products
      final pList = _mockDb.products.map((e) => _mapToProductEntity(e)).toList();
      
      // Load categories
      final cList = _mockDb.categories.map((e) => CategoryEntity(
            id: e['id'] as String,
            name: e['name'] as String,
            icon: e['icon'] as String,
            parentId: e['parentId'] as String?,
          )).toList();

      // Load orders
      final oList = _mockDb.orders.map((e) => OrderEntity.fromJson(e)).toList();
      
      // Load stock logs
      final sLogs = List<Map<String, dynamic>>.from(_mockDb.stockHistory);

      emit(state.copyWith(
        isLoading: false,
        products: pList,
        categories: cList,
        orders: oList,
        stockLogs: sLogs..sort((a, b) => b['date'].toString().compareTo(a['date'].toString())),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // --- Product Catalog Management ---
  
  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required double discount,
    required String categoryId,
    required int initialStock,
    required String sku,
    required String barcode,
    required List<String> images,
    required Map<String, List<String>> variants,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final newId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
      final newProdJson = {
        'id': newId,
        'name': name,
        'description': description,
        'price': price,
        'discount': discount,
        'categoryId': categoryId,
        'stock': initialStock,
        'sku': sku,
        'barcode': barcode,
        'images': images.isEmpty ? ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80'] : images,
        'variants': variants,
        'ratings': 0.0,
        'reviews': [],
        'isEnabled': true,
      };

      _mockDb.products.add(newProdJson);

      // Create Stock Log
      _mockDb.stockHistory.add({
        'id': 'stock_log_${DateTime.now().millisecondsSinceEpoch}',
        'productId': newId,
        'sku': sku,
        'change': initialStock,
        'type': 'create',
        'notes': 'Product created catalog load',
        'date': DateTime.now().toIso8601String(),
      });

      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> editProduct(ProductEntity product) async {
    emit(state.copyWith(isLoading: true));
    try {
      final index = _mockDb.products.indexWhere((p) => p['id'] == product.id);
      if (index == -1) throw Exception('Product catalog missing');

      final existing = _mockDb.products[index];
      
      // Update values
      existing['name'] = product.name;
      existing['description'] = product.description;
      existing['price'] = product.price;
      existing['discount'] = product.discount;
      existing['categoryId'] = product.categoryId;
      existing['sku'] = product.sku;
      existing['barcode'] = product.barcode;
      existing['images'] = product.images;
      existing['variants'] = product.variants;
      existing['isEnabled'] = product.isEnabled;

      // Note: Stock remains managed by restock triggers

      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    emit(state.copyWith(isLoading: true));
    try {
      _mockDb.products.removeWhere((p) => p['id'] == id);
      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> restockProduct(String productId, int amount, String notes) async {
    emit(state.copyWith(isLoading: true));
    try {
      final index = _mockDb.products.indexWhere((p) => p['id'] == productId);
      if (index == -1) throw Exception('Product missing');

      final prod = _mockDb.products[index];
      final currentStock = prod['stock'] as int;
      prod['stock'] = currentStock + amount;

      _mockDb.stockHistory.add({
        'id': 'stock_log_${DateTime.now().millisecondsSinceEpoch}',
        'productId': productId,
        'sku': prod['sku'],
        'change': amount,
        'type': 'restock',
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });

      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // --- Order Management ---

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    emit(state.copyWith(isLoading: true));
    try {
      final index = _mockDb.orders.indexWhere((o) => o['id'] == orderId);
      if (index == -1) throw Exception('Order not found');

      final order = _mockDb.orders[index];
      order['status'] = newStatus;
      
      final timeline = List<Map<String, String>>.from((order['statusTimeline'] as List).map((e) => Map<String, String>.from(e as Map)));
      timeline.add({
        'status': newStatus,
        'date': DateTime.now().toIso8601String(),
      });
      order['statusTimeline'] = timeline;

      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // --- Category CRUD ---
  
  Future<void> createCategory(String name, String icon, String? parentId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final newId = 'cat_${name.toLowerCase().replaceAll(' ', '_')}';
      _mockDb.categories.add({
        'id': newId,
        'name': name,
        'icon': icon,
        'parentId': parentId,
      });
      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
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
