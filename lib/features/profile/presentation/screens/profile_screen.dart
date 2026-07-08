import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';

// Global ValueNotifier to easily trigger Theme changes across the app without complex boilerplate
final ValueNotifier<ThemeMode> appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Profile'),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(metrics.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80'),
                      ),
                      SizedBox(height: metrics.space16),
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: metrics.space4),
                      Text(
                        user.email,
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                      SizedBox(height: metrics.space8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isAdmin 
                              ? theme.colorScheme.tertiary.withOpacity(0.1) 
                              : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(metrics.radiusRound),
                        ),
                        child: Text(
                          user.isAdmin ? 'ADMINISTRATOR' : 'CLIENT PROFILE',
                          style: TextStyle(
                            color: user.isAdmin ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: metrics.space32),

                // 2. Settings Sections
                Text(
                  'Account Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: metrics.space12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('My Delivery Addresses'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // View address sheet
                          _showAddressBookSheet(context, user.addresses, metrics);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('My Purchase History'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.orders),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: metrics.space24),

                Text(
                  'Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: metrics.space12),
                Card(
                  child: Column(
                    children: [
                      // Dark Mode Switch
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: appThemeModeNotifier,
                        builder: (context, mode, child) {
                          final isDark = mode == ThemeMode.dark;
                          return SwitchListTile(
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Dark Theme Mode'),
                            value: isDark,
                            onChanged: (val) {
                              appThemeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.language_outlined),
                        title: Text('App Language'),
                        trailing: Text('English (US)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: metrics.space32),

                // 3. Admin dashboard access link (shown only to admin users!)
                if (user.isAdmin) ...[
                  CustomButton(
                    text: 'Admin Console Dashboard',
                    icon: Icons.admin_panel_settings,
                    onPressed: () => context.push(AppRoutes.adminDashboard),
                  ),
                  SizedBox(height: metrics.space16),
                ],

                // 4. Logout Button
                CustomButton(
                  text: 'Sign Out',
                  icon: Icons.logout_outlined,
                  isOutlined: true,
                  onPressed: () => context.read<AuthCubit>().logout(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddressBookSheet(BuildContext context, List<dynamic> addresses, AppMetrics metrics) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.all(metrics.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('My Address Book', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: metrics.space16),
              if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('No addresses logged. Add one during checkout.', style: TextStyle(fontStyle: FontStyle.italic)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      return ListTile(
                        leading: const Icon(Icons.home),
                        title: Text(addr.title),
                        subtitle: Text('${addr.street}, ${addr.city}, ${addr.state} ${addr.zipCode}'),
                        trailing: addr.isDefault
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('DEFAULT', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              CustomButton(
                text: 'Dismiss',
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      },
    );
  }
}
