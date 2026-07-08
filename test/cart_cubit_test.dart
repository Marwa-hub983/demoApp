import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:demo_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:demo_app/core/services/cache_service.dart';

class MockCacheService extends Mock implements CacheService {}

void main() {
  late MockCacheService mockCache;
  late CartCubit cartCubit;

  setUp(() {
    mockCache = MockCacheService();
    when(() => mockCache.read(any())).thenReturn(null);
    when(() => mockCache.save(any(), any())).thenAnswer((_) async {});
    cartCubit = CartCubit(mockCache);
  });

  group('CartCubit Unit Tests', () {
    test('Initial state contains empty items list and zeroed metrics', () {
      expect(cartCubit.state.items, isEmpty);
      expect(cartCubit.state.subtotal, 0.0);
      expect(cartCubit.state.tax, 0.0);
    });

    test('Adding items calculates correct discounted price and quantity subtotal', () {
      const item = CartItem(
        productId: 'prod_test_1',
        productName: 'Test Premium Product',
        price: 100.0,
        discount: 10.0, // 10% discount = $90 itemPrice
        image: 'https://images.example.com/test.jpg',
        quantity: 2,
      );

      cartCubit.addToCart(item);

      expect(cartCubit.state.items.length, equals(1));
      expect(cartCubit.state.items.first.productId, equals('prod_test_1'));
      expect(cartCubit.state.items.first.quantity, equals(2));
      expect(cartCubit.state.subtotal, equals(180.0));
      expect(cartCubit.state.tax, equals(180.0 * 0.08)); // 8% tax
    });
  });
}
