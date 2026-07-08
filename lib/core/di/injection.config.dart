// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/admin/presentation/bloc/admin_cubit.dart' as _i459;
import '../../features/authentication/data/repositories/auth_repository_impl.dart'
    as _i317;
import '../../features/authentication/domain/repositories/auth_repository.dart'
    as _i742;
import '../../features/authentication/presentation/bloc/auth_cubit.dart'
    as _i302;
import '../../features/cart/presentation/bloc/cart_cubit.dart' as _i793;
import '../../features/orders/presentation/bloc/orders_cubit.dart' as _i169;
import '../../features/products/data/repositories/product_repository_impl.dart'
    as _i764;
import '../../features/products/domain/repositories/product_repository.dart'
    as _i963;
import '../../features/products/presentation/bloc/product_details_cubit.dart'
    as _i484;
import '../../features/products/presentation/bloc/shop_cubit.dart' as _i197;
import '../../features/wishlist/presentation/bloc/wishlist_cubit.dart' as _i332;
import '../network/dio_client.dart' as _i667;
import '../services/cache_service.dart' as _i717;
import '../services/mock_database_service.dart' as _i811;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i811.MockDatabaseService>(
      () => _i811.MockDatabaseService(),
    );
    gh.lazySingleton<_i459.AdminCubit>(
      () => _i459.AdminCubit(gh<_i811.MockDatabaseService>()),
    );
    gh.lazySingleton<_i169.OrdersCubit>(
      () => _i169.OrdersCubit(gh<_i811.MockDatabaseService>()),
    );
    gh.lazySingleton<_i963.ProductRepository>(
      () => _i764.ProductRepositoryImpl(gh<_i811.MockDatabaseService>()),
    );
    gh.lazySingleton<_i197.ShopCubit>(
      () => _i197.ShopCubit(gh<_i963.ProductRepository>()),
    );
    gh.factory<_i484.ProductDetailsCubit>(
      () => _i484.ProductDetailsCubit(gh<_i963.ProductRepository>()),
    );
    gh.lazySingleton<_i717.CacheService>(
      () => _i717.CacheService(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i332.WishlistCubit>(
      () => _i332.WishlistCubit(
        gh<_i717.CacheService>(),
        gh<_i963.ProductRepository>(),
      ),
    );
    gh.lazySingleton<_i667.DioClient>(
      () => _i667.DioClient(
        gh<_i361.Dio>(),
        gh<_i895.Connectivity>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i793.CartCubit>(
      () => _i793.CartCubit(gh<_i717.CacheService>()),
    );
    gh.lazySingleton<_i742.AuthRepository>(
      () => _i317.AuthRepositoryImpl(
        gh<_i811.MockDatabaseService>(),
        gh<_i717.CacheService>(),
      ),
    );
    gh.lazySingleton<_i302.AuthCubit>(
      () => _i302.AuthCubit(gh<_i742.AuthRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
