import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/bloc/admin_cubit.dart';
import 'features/authentication/presentation/bloc/auth_cubit.dart';
import 'features/cart/presentation/bloc/cart_cubit.dart';
import 'features/orders/presentation/bloc/orders_cubit.dart';
import 'features/products/presentation/bloc/shop_cubit.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/wishlist/presentation/bloc/wishlist_cubit.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} onChange: $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('${bloc.runtimeType} onError: $error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await configureDependencies();
  await getIt<CacheService>().init();
  Bloc.observer = SimpleBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
        BlocProvider<ShopCubit>(create: (_) => getIt<ShopCubit>()),
        BlocProvider<CartCubit>(create: (_) => getIt<CartCubit>()),
        BlocProvider<WishlistCubit>(create: (_) => getIt<WishlistCubit>()),
        BlocProvider<OrdersCubit>(create: (_) => getIt<OrdersCubit>()),
        BlocProvider<AdminCubit>(create: (_) => getIt<AdminCubit>()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeModeNotifier,
        builder: (context, mode, child) {
          return MaterialApp.router(
            title: 'Antigravity Commerce',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
