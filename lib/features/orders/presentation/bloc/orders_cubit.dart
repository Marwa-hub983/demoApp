import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/mock_database_service.dart';
import '../../../cart/presentation/bloc/cart_cubit.dart';


class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      selectedColor: json['selectedColor'] as String?,
      selectedSize: json['selectedSize'] as String?,
    );
  }

  @override
  List<Object?> get props => [productId, productName, price, quantity, selectedColor, selectedSize];
}

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final Map<String, double> summary;
  final Map<String, String> address;
  final String paymentMethod;
  final String status;
  final List<Map<String, String>> statusTimeline;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.summary,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.statusTimeline,
    required this.createdAt,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'] as Map;
    final Map<String, double> summary = {};
    summaryRaw.forEach((key, value) {
      summary[key.toString()] = (value as num).toDouble();
    });

    final addressRaw = json['address'] as Map;
    final Map<String, String> address = {};
    addressRaw.forEach((key, value) {
      address[key.toString()] = value.toString();
    });

    final timelineRaw = json['statusTimeline'] as List;
    final statusTimeline = timelineRaw.map((e) {
      final map = e as Map;
      return {
        'status': map['status'].toString(),
        'date': map['date'].toString(),
      };
    }).toList();

    return OrderEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List).map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      summary: summary,
      address: address,
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      statusTimeline: statusTimeline,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, items, summary, address, paymentMethod, status, statusTimeline, createdAt];
}

class OrdersState extends Equatable {
  final List<OrderEntity> orders;
  final bool isLoading;
  final bool orderSuccess;
  final String? errorMessage;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.orderSuccess = false,
    this.errorMessage,
  });

  OrdersState copyWith({
    List<OrderEntity>? orders,
    bool? isLoading,
    bool? orderSuccess,
    String? errorMessage,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      orderSuccess: orderSuccess ?? this.orderSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [orders, isLoading, orderSuccess, errorMessage];
}

@lazySingleton
class OrdersCubit extends Cubit<OrdersState> {
  final MockDatabaseService _mockDb;

  OrdersCubit(this._mockDb) : super(const OrdersState());

  Future<void> loadOrders(String userId) async {
    emit(state.copyWith(isLoading: true, orderSuccess: false, errorMessage: null));
    try {
      final list = await _mockDb.query(
        _mockDb.orders,
        where: (e) => e['userId'] == userId,
      );

      final orders = list.map((e) => OrderEntity.fromJson(e)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort newest first

      emit(state.copyWith(isLoading: false, orders: orders));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> placeOrder({
    required String userId,
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double shipping,
    required double total,
    required Map<String, String> address,
    required String paymentMethod,
  }) async {
    emit(state.copyWith(isLoading: true, orderSuccess: false, errorMessage: null));
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate gateway

      final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Map to Order items
      final itemsJson = cartItems.map((e) => {
        'productId': e.productId,
        'productName': e.productName,
        'price': e.itemPrice,
        'quantity': e.quantity,
        'selectedColor': e.selectedColor,
        'selectedSize': e.selectedSize,
      }).toList();

      final orderJson = {
        'id': orderId,
        'userId': userId,
        'items': itemsJson,
        'summary': {
          'subtotal': subtotal,
          'tax': tax,
          'shipping': shipping,
          'total': total,
        },
        'address': address,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'statusTimeline': [
          {'status': 'pending', 'date': DateTime.now().toIso8601String()},
        ],
        'createdAt': DateTime.now().toIso8601String(),
      };

      // 2. Decrement stock levels & add log history in mock database
      for (var item in cartItems) {
        final pIdx = _mockDb.products.indexWhere((p) => p['id'] == item.productId);
        if (pIdx != -1) {
          final prod = _mockDb.products[pIdx];
          final currentStock = prod['stock'] as int;
          final newStock = currentStock - item.quantity;
          prod['stock'] = newStock < 0 ? 0 : newStock;

          // Sync product stock level back to Firestore
          _mockDb.products.syncDocument(item.productId);

          // Add history logs
          _mockDb.stockHistory.add({
            'id': 'stock_log_${DateTime.now().millisecondsSinceEpoch}_${item.productId}',
            'productId': item.productId,
            'sku': prod['sku'],
            'change': -item.quantity,
            'type': 'sale',
            'notes': 'Sale transaction from Order $orderId',
            'date': DateTime.now().toIso8601String(),
          });
        }
      }

      // 3. Add to orders database
      _mockDb.orders.add(orderJson);

      emit(state.copyWith(isLoading: false, orderSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void resetOrderState() {
    emit(state.copyWith(
      isLoading: false,
      orderSuccess: false,
      errorMessage: null,
    ));
  }
}
