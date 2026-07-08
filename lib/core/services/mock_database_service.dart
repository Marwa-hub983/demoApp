import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class MockDatabaseService {
  final _uuid = const Uuid();

  // Mock Tables
  final List<Map<String, dynamic>> users = [];
  final List<Map<String, dynamic>> products = [];
  final List<Map<String, dynamic>> categories = [];
  final List<Map<String, dynamic>> orders = [];
  final List<Map<String, dynamic>> cartItems = [];
  final List<Map<String, dynamic>> wishlistItems = [];
  final List<Map<String, dynamic>> stockHistory = [];
  final List<Map<String, dynamic>> notifications = [];

  MockDatabaseService() {
    _seedData();
  }

  void _seedData() {
    // 1. Seed Users
    users.addAll([
      {
        'id': 'user_client_1',
        'email': 'user@example.com',
        'fullName': 'John Doe',
        'role': 'client',
        'profilePicture': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        'addresses': [
          {
            'id': 'addr_1',
            'title': 'Home',
            'street': '123 Flutter Way',
            'city': 'San Francisco',
            'state': 'CA',
            'zipCode': '94103',
            'country': 'USA',
            'isDefault': true,
          }
        ],
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'user_admin_1',
        'email': 'admin@example.com',
        'fullName': 'Sarah Jenkins (Admin)',
        'role': 'admin',
        'profilePicture': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
        'addresses': [],
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      }
    ]);

    // 2. Seed Categories
    categories.addAll([
      {'id': 'cat_electronics', 'name': 'Electronics', 'icon': 'devices', 'parentId': null},
      {'id': 'cat_fashion', 'name': 'Fashion', 'icon': 'checkroom', 'parentId': null},
      {'id': 'cat_footwear', 'name': 'Footwear', 'icon': 'roller_skating', 'parentId': 'cat_fashion'},
      {'id': 'cat_accessories', 'name': 'Accessories', 'icon': 'watch', 'parentId': null},
      {'id': 'cat_home', 'name': 'Home & Living', 'icon': 'home', 'parentId': null},
    ]);

    // 3. Seed Products
    products.addAll([
      {
        'id': 'prod_1',
        'name': 'Apple Watch Series 9',
        'description': 'The ultimate device for a healthy life is now even more powerful. Introducing the new S9 SiP chip, a magical new way to use your watch without touching the screen, and a double-bright display.',
        'price': 399.99,
        'discount': 10.0, // 10% discount
        'categoryId': 'cat_accessories',
        'stock': 12,
        'sku': 'AAPL-W9-45-BLK',
        'barcode': '190199223344',
        'images': [
          'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?auto=format&fit=crop&w=600&q=80',
        ],
        'variants': {
          'colors': ['Midnight', 'Starlight', 'Red'],
          'sizes': ['41mm', '45mm']
        },
        'ratings': 4.8,
        'reviews': [
          {
            'userName': 'Alex Mercer',
            'rating': 5,
            'comment': 'Amazing battery life compared to my older watch. Double tap gesture is really helpful!',
            'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
          },
          {
            'userName': 'Emily Watson',
            'rating': 4,
            'comment': 'Starlight color looks elegant. Health tracking features are spot-on.',
            'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()
          }
        ],
        'isEnabled': true,
      },
      {
        'id': 'prod_2',
        'name': 'Sony WH-1000XM5 Headphones',
        'description': 'Industry-leading noise canceling overhead headphones with premium sound quality, exceptional call capabilities, and ultra-comfortable design.',
        'price': 348.00,
        'discount': 0.0,
        'categoryId': 'cat_electronics',
        'stock': 4, // Low Stock Alert Trigger
        'sku': 'SONY-XM5-OVR-BLK',
        'barcode': '490178001122',
        'images': [
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
        ],
        'variants': {
          'colors': ['Black', 'Silver'],
          'sizes': []
        },
        'ratings': 4.9,
        'reviews': [
          {
            'userName': 'David Miller',
            'rating': 5,
            'comment': 'Best active noise cancellation on the market. Lightweight and comfortable.',
            'date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()
          }
        ],
        'isEnabled': true,
      },
      {
        'id': 'prod_3',
        'name': 'Nike Air Max 270',
        'description': 'Nikes first lifestyle Air Max brings you style, comfort and big attitude. Inspired by Air Max icons, it showcases Nike\'s greatest innovation with its large window and fresh array of colors.',
        'price': 160.00,
        'discount': 15.0, // 15% discount
        'categoryId': 'cat_footwear',
        'stock': 25,
        'sku': 'NIKE-AM270-WHT-10',
        'barcode': '886059112233',
        'images': [
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?auto=format&fit=crop&w=600&q=80',
        ],
        'variants': {
          'colors': ['White/Red', 'Black/Green'],
          'sizes': ['8', '9', '10', '11']
        },
        'ratings': 4.6,
        'reviews': [],
        'isEnabled': true,
      },
      {
        'id': 'prod_4',
        'name': 'Peak Design Everyday Backpack 20L',
        'description': 'An iconic, award-winning pack for everyday and photo carry, the newly revamped Everyday Backpack is built around accessibility, organization, expansion, and protection.',
        'price': 279.95,
        'discount': 5.0,
        'categoryId': 'cat_accessories',
        'stock': 18,
        'sku': 'PD-ED-BP-20-GRY',
        'barcode': '855110007890',
        'images': [
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=600&q=80',
        ],
        'variants': {
          'colors': ['Charcoal', 'Ash', 'Midnight'],
          'sizes': ['20L', '30L']
        },
        'ratings': 4.7,
        'reviews': [],
        'isEnabled': true,
      },
      {
        'id': 'prod_5',
        'name': 'Minimalist Leather Wallet',
        'description': 'Handcrafted full-grain leather card holder designed to carry up to 8 cards and folded cash in a sleek front pocket profile.',
        'price': 45.00,
        'discount': 0.0,
        'categoryId': 'cat_accessories',
        'stock': 3, // Low Stock
        'sku': 'WAL-MIN-LTHR-BRN',
        'barcode': '742696112233',
        'images': [
          'https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=600&q=80',
        ],
        'variants': {
          'colors': ['Brown', 'Black', 'Tan'],
          'sizes': []
        },
        'ratings': 4.4,
        'reviews': [],
        'isEnabled': true,
      }
    ]);

    // 4. Seed Stock History
    for (var product in products) {
      stockHistory.add({
        'id': _uuid.v4(),
        'productId': product['id'],
        'sku': product['sku'],
        'change': product['stock'],
        'type': 'restock',
        'notes': 'Initial system seed stock loading',
        'date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      });
    }

    // 5. Seed Orders
    orders.add({
      'id': 'ord_seed_1',
      'userId': 'user_client_1',
      'items': [
        {
          'productId': 'prod_1',
          'productName': 'Apple Watch Series 9',
          'price': 359.99, // discounted price
          'quantity': 1,
          'selectedColor': 'Midnight',
          'selectedSize': '45mm',
        }
      ],
      'summary': {
        'subtotal': 359.99,
        'tax': 28.80,
        'shipping': 10.00,
        'total': 398.79,
      },
      'address': {
        'street': '123 Flutter Way',
        'city': 'San Francisco',
        'state': 'CA',
        'zipCode': '94103',
        'country': 'USA',
      },
      'paymentMethod': 'Mock Card',
      'status': 'delivered', // stepper state: pending, confirmed, packed, shipped, delivered, cancelled
      'statusTimeline': [
        {'status': 'pending', 'date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
        {'status': 'confirmed', 'date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
        {'status': 'packed', 'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'status': 'shipped', 'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'status': 'delivered', 'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    });
  }

  // Helper Database Queries (acting like Firestore Client APIs)
  Future<List<Map<String, dynamic>>> query(
    List<Map<String, dynamic>> list, {
    bool Function(Map<String, dynamic>)? where,
    int? limit,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate remote delay
    var results = list;
    if (where != null) {
      results = results.where(where).toList();
    }
    results = results.skip(offset).toList();
    if (limit != null) {
      results = results.take(limit).toList();
    }
    return results.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> getDocument(
    List<Map<String, dynamic>> list,
    String id,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      final doc = list.firstWhere((element) => element['id'] == id);
      return Map<String, dynamic>.from(doc);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> setDocument(
    List<Map<String, dynamic>> list,
    String id,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = list.indexWhere((element) => element['id'] == id);
    final finalDoc = Map<String, dynamic>.from(data)..['id'] = id;
    if (index != -1) {
      list[index] = finalDoc;
    } else {
      list.add(finalDoc);
    }
    return finalDoc;
  }

  Future<void> deleteDocument(List<Map<String, dynamic>> list, String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    list.removeWhere((element) => element['id'] == id);
  }
}
