import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final double discount;
  final String image;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.discount,
    required this.image,
    this.selectedColor,
    this.selectedSize,
    this.quantity = 1,
  });

  double get itemPrice => discount > 0 ? price * (1 - discount / 100) : price;
  double get totalPrice => itemPrice * quantity;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      price: price,
      discount: discount,
      image: image,
      selectedColor: selectedColor,
      selectedSize: selectedSize,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'discount': discount,
      'image': image,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      image: json['image'] as String,
      selectedColor: json['selectedColor'] as String?,
      selectedSize: json['selectedSize'] as String?,
      quantity: json['quantity'] as int,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        price,
        discount,
        image,
        selectedColor,
        selectedSize,
        quantity,
      ];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final String? couponCode;
  final double couponDiscountPercent;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.couponCode,
    this.couponDiscountPercent = 0.0,
    this.isLoading = false,
    this.errorMessage,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * (couponDiscountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get tax => taxableAmount * 0.08; // 8% sales tax
  double get shippingFee => (taxableAmount > 200 || items.isEmpty) ? 0.0 : 10.0;
  double get total => taxableAmount - discountAmount + tax + shippingFee;

  CartState copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? couponDiscountPercent,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      couponDiscountPercent: couponDiscountPercent ?? this.couponDiscountPercent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  CartState clearCoupon() {
    return CartState(
      items: items,
      couponCode: null,
      couponDiscountPercent: 0.0,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        couponCode,
        couponDiscountPercent,
        isLoading,
        errorMessage,
      ];
}

@lazySingleton
class CartCubit extends Cubit<CartState> {
  final CacheService _cache;
  static const String _cartCacheKey = 'shopping_cart_items';

  CartCubit(this._cache) : super(const CartState()) {
    _loadCartFromCache();
  }

  void _loadCartFromCache() {
    try {
      final jsonString = _cache.read(_cartCacheKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString as String);
        final items = decoded.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))).toList();
        emit(CartState(items: items));
      }
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> _saveCartToCache(List<CartItem> items) async {
    try {
      final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
      await _cache.save(_cartCacheKey, jsonString);
    } catch (_) {}
  }

  void addToCart(CartItem item) {
    final existingIndex = state.items.indexWhere(
      (e) =>
          e.productId == item.productId &&
          e.selectedColor == item.selectedColor &&
          e.selectedSize == item.selectedSize,
    );

    List<CartItem> updatedItems;
    if (existingIndex != -1) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      updatedItems = List.of(state.items)..[existingIndex] = updatedItem;
    } else {
      updatedItems = List.of(state.items)..add(item);
    }

    emit(state.copyWith(items: updatedItems));
    _saveCartToCache(updatedItems);
  }

  void updateQuantity(String productId, String? color, String? size, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId, color, size);
      return;
    }

    final index = state.items.indexWhere(
      (e) => e.productId == productId && e.selectedColor == color && e.selectedSize == size,
    );
    if (index == -1) return;

    final updatedItem = state.items[index].copyWith(quantity: quantity);
    final updatedItems = List.of(state.items)..[index] = updatedItem;

    emit(state.copyWith(items: updatedItems));
    _saveCartToCache(updatedItems);
  }

  void removeFromCart(String productId, String? color, String? size) {
    final updatedItems = List.of(state.items)
      ..removeWhere(
        (e) => e.productId == productId && e.selectedColor == color && e.selectedSize == size,
      );

    emit(state.copyWith(items: updatedItems));
    _saveCartToCache(updatedItems);
  }

  void applyCoupon(String code) {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    // Simulated coupon codes
    if (code.toUpperCase() == 'FLUTTER25') {
      emit(state.copyWith(
        isLoading: false,
        couponCode: 'FLUTTER25',
        couponDiscountPercent: 25.0,
      ));
    } else if (code.toUpperCase() == 'WELCOME10') {
      emit(state.copyWith(
        isLoading: false,
        couponCode: 'WELCOME10',
        couponDiscountPercent: 10.0,
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid promo code',
      ));
    }
  }

  void removeCoupon() {
    emit(state.clearCoupon());
  }

  void clearCart() {
    emit(const CartState());
    _saveCartToCache(const []);
  }
}
