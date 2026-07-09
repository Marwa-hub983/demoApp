import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/bloc/auth_cubit.dart';
import '../../features/cart/presentation/bloc/cart_cubit.dart';
import '../routes/app_router.dart';
import '../theme/theme_extensions.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(String location, bool isAdmin) {
    if (location.startsWith(AppRoutes.cart)) {
      return 1;
    }
    if (isAdmin && location.startsWith(AppRoutes.adminDashboard)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.profile)) {
      return isAdmin ? 3 : 2;
    }
    return 0; // Default to Home
  }

  void _onTabTapped(BuildContext context, int index, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.cart);
          break;
        case 2:
          context.go(AppRoutes.adminDashboard);
          break;
        case 3:
          context.go(AppRoutes.profile);
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.cart);
          break;
        case 2:
          context.go(AppRoutes.profile);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    final location = GoRouterState.of(context).uri.path;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
        final selectedIndex = _getSelectedIndex(location, isAdmin);

        return Scaffold(
          body: child,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabItem(
                          context: context,
                          index: 0,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          isSelected: selectedIndex == 0,
                          theme: theme,
                          isAdmin: isAdmin,
                        ),
                        _buildTabItem(
                          context: context,
                          index: 1,
                          icon: Icons.shopping_cart_outlined,
                          activeIcon: Icons.shopping_cart_rounded,
                          isSelected: selectedIndex == 1,
                          theme: theme,
                          isCart: true,
                          isAdmin: isAdmin,
                        ),
                        if (isAdmin)
                          _buildTabItem(
                            context: context,
                            index: 2,
                            icon: Icons.admin_panel_settings_outlined,
                            activeIcon: Icons.admin_panel_settings,
                            isSelected: selectedIndex == 2,
                            theme: theme,
                            isAdmin: isAdmin,
                          ),
                        _buildTabItem(
                          context: context,
                          index: isAdmin ? 3 : 2,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          isSelected: selectedIndex == (isAdmin ? 3 : 2),
                          theme: theme,
                          isAdmin: isAdmin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required ThemeData theme,
    required bool isAdmin,
    bool isCart = false,
  }) {
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.secondary.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => _onTabTapped(context, index, isAdmin),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isCart
            ? BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  final count = state.items.fold(0, (sum, item) => sum + item.quantity);
                  return Badge(
                    label: Text(count.toString()),
                    isLabelVisible: count > 0,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 24,
                    ),
                  );
                },
              )
            : Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
      ),
    );
  }
}
