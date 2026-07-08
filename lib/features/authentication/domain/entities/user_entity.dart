import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  final String id;
  final String title;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  const AddressEntity({
    required this.id,
    required this.title,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  factory AddressEntity.fromJson(Map<String, dynamic> json) {
    return AddressEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, street, city, state, zipCode, country, isDefault];
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? profilePicture;
  final List<AddressEntity> addresses;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.profilePicture,
    required this.addresses,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, email, fullName, role, profilePicture, addresses];
}
