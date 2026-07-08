import 'package:demo_app/core/di/injection.dart';
import 'package:demo_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/presentation/bloc/admin_cubit.dart';
import 'features/authentication/presentation/bloc/auth_cubit.dart';
import 'features/cart/presentation/bloc/cart_cubit.dart';
import 'features/orders/presentation/bloc/orders_cubit.dart';
import 'features/products/presentation/bloc/shop_cubit.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/wishlist/presentation/bloc/wishlist_cubit.dart';

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
            title: 'Demo App',
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
