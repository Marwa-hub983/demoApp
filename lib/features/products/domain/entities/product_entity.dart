import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  const ReviewEntity({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  List<Object?> get props => [userName, rating, comment, date];
}

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discount;
  final String categoryId;
  final int stock;
  final String sku;
  final String barcode;
  final List<String> images;
  final Map<String, List<String>> variants;
  final double ratings;
  final List<ReviewEntity> reviews;
  final bool isEnabled;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discount,
    required this.categoryId,
    required this.stock,
    required this.sku,
    required this.barcode,
    required this.images,
    required this.variants,
    required this.ratings,
    required this.reviews,
    this.isEnabled = true,
  });

  double get discountedPrice {
    if (discount > 0) {
      return price * (1 - discount / 100);
    }
    return price;
  }

  bool get isLowStock => stock <= 5;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        discount,
        categoryId,
        stock,
        sku,
        barcode,
        images,
        variants,
        ratings,
        reviews,
        isEnabled,
      ];
}

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String? parentId;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, icon, parentId];
}
