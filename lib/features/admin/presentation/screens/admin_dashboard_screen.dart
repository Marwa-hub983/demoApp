import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/admin_cubit.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminCubit>().loadDashboard(),
          ),
        ],
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingView(message: 'Compiling sales analytics...');
          }
          if (state.errorMessage != null) {
            return ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AdminCubit>().loadDashboard(),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(metrics.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. KPI Stats Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Revenue',
                      value: '\$${state.totalRevenue.toStringAsFixed(2)}',
                      icon: Icons.monetization_on,
                      color: Colors.green,
                      metrics: metrics,
                    ),
                    _StatCard(
                      title: 'Pending Orders',
                      value: state.pendingOrdersCount.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.blue,
                      metrics: metrics,
                    ),
                    _StatCard(
                      title: 'Low Stock Alerts',
                      value: state.lowStockProductsCount.toString(),
                      icon: Icons.warning_amber,
                      color: Colors.amber[800]!,
                      metrics: metrics,
                    ),
                    _StatCard(
                      title: 'Catalog Size',
                      value: state.products.length.toString(),
                      icon: Icons.grid_view,
                      color: theme.colorScheme.primary,
                      metrics: metrics,
                    ),
                  ],
                ),

                SizedBox(height: metrics.space24),

                // 2. Sales Custom Chart
                Text(
                  'Sales Performance (Weekly)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: metrics.space12),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(metrics.space16),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Text('Revenue (${state.productName})', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(
                              'Week 27, 2026',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: metrics.space24),
                        // Mock Chart representation using Custom Paint bars
                        SizedBox(
                          height: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _ChartBar(
                                label: 'Mon',
                                value: 120.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.primary,
                              ),
                              _ChartBar(
                                label: 'Tue',
                                value: 240.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.primary,
                              ),
                              _ChartBar(
                                label: 'Wed',
                                value: 410.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.tertiary,
                              ),
                              _ChartBar(
                                label: 'Thu',
                                value: 180.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.primary,
                              ),
                              _ChartBar(
                                label: 'Fri',
                                value: 320.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.primary,
                              ),
                              _ChartBar(
                                label: 'Sat',
                                value: 490.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.tertiary,
                              ),
                              _ChartBar(
                                label: 'Sun',
                                value: 390.0,
                                maxValue: 500.0,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: metrics.space24),

                // 3. Quick Action Buttons Grid
                Text(
                  'Console Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: metrics.space12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        title: 'Products CRUD',
                        icon: Icons.edit_note,
                        onPressed: () => context.push(AppRoutes.adminProducts),
                        metrics: metrics,
                      ),
                    ),
                    SizedBox(width: metrics.space12),
                    Expanded(
                      child: _ActionTile(
                        title: 'Orders Stepper',
                        icon: Icons.local_shipping,
                        onPressed: () => context.push(AppRoutes.adminOrders),
                        metrics: metrics,
                      ),
                    ),
                    SizedBox(width: metrics.space12),
                    Expanded(
                      child: _ActionTile(
                        title: 'Inventory Scan',
                        icon: Icons.qr_code_scanner,
                        onPressed: () => context.push(AppRoutes.adminInventory),
                        metrics: metrics,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: metrics.space24),

                // 4. Low stock reminder list
                if (state.lowStockProducts.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Critical Inventory Alerts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => context.push(AppRoutes.adminInventory),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.space8),
                  Card(
                    color: theme.colorScheme.error.withOpacity(0.02),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.lowStockProducts.take(3).length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prod = state.lowStockProducts[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.amber,
                          ),
                          title: Text(
                            prod.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text('SKU: ${prod.sku}'),
                          trailing: Text(
                            '${prod.stock} left',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppMetrics metrics;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(metrics.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _ChartBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / maxValue).clamp(0.05, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '\$${value.toInt()}',
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 14,
          height: 80 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final AppMetrics metrics;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onPressed,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: metrics.space16,
            horizontal: metrics.space8,
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              SizedBox(height: metrics.space8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
