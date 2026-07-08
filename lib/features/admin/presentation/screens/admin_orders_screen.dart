import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/admin_cubit.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Admin Order Steppers'),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.orders.isEmpty) {
            return const EmptyView(
              title: 'No Orders Logged',
              message: 'Orders placed by clients will show up here for processing.',
              icon: Icons.receipt_long_outlined,
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(metrics.space16),
            itemCount: state.orders.length,
            separatorBuilder: (context, index) => SizedBox(height: metrics.space12),
            itemBuilder: (context, index) {
              final order = state.orders[index];
              Color statusColor = theme.colorScheme.primary;
              if (order.status == 'delivered') statusColor = Colors.green;
              if (order.status == 'cancelled') statusColor = Colors.red;

              return Card(
                child: ExpansionTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: #${order.id.replaceAll('ord_', '')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Client: ID: ${order.userId}',
                        style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Total: \$${(order.summary['total'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(metrics.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          // Stepper details
                          const Text('Process Order Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: metrics.space12),
                          // Dropdown for updating status
                          DropdownButtonFormField<String>(
                            value: order.status,
                            decoration: const InputDecoration(labelText: 'Change Order Status'),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('PENDING')),
                              DropdownMenuItem(value: 'confirmed', child: Text('CONFIRMED')),
                              DropdownMenuItem(value: 'packed', child: Text('PACKED')),
                              DropdownMenuItem(value: 'shipped', child: Text('SHIPPED')),
                              DropdownMenuItem(value: 'delivered', child: Text('DELIVERED')),
                              DropdownMenuItem(value: 'cancelled', child: Text('CANCELLED')),
                            ],
                            onChanged: (val) {
                              if (val != null && val != order.status) {
                                context.read<AdminCubit>().updateOrderStatus(order.id, val);
                              }
                            },
                          ),
                          const Divider(height: 24),
                          const Text('Products Purchased:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: metrics.space8),
                          ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 12)),
                                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              )),
                          const Divider(height: 24),
                          // Address Details
                          const Text('Shipping Destination:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: metrics.space4),
                          Text(
                            '${order.address['street']}\n${order.address['city']}, ${order.address['state']} ${order.address['zipCode']}',
                            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
