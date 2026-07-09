import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:demo_app/core/routes/app_router.dart';
import 'package:demo_app/features/orders/presentation/bloc/orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Trigger load
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      context.read<OrdersCubit>().loadOrders(auth.user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportAndShareInvoice(
    BuildContext context,
    OrderEntity order,
  ) async {
    final theme = Theme.of(context);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ANTIGRAVITY RETAIL INVOICE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Order Identification: ${order.id}'),
              pw.Text(
                'Date Generated: ${order.createdAt.toLocal().toString()}',
              ),
              pw.Text('Payment Gateway: ${order.paymentMethod}'),
              pw.SizedBox(height: 10),
              pw.Text(
                'Shipping to: ${order.address['street']}, ${order.address['city']}, ${order.address['state']}',
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Purchased Items:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              ...order.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${item.productName} (Color: ${item.selectedColor ?? "N/A"}, Size: ${item.selectedSize ?? "N/A"}) x${item.quantity}',
                      ),
                      pw.Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '\$${(order.summary['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (8%):', style: pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '\$${(order.summary['tax'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Shipping:', style: pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    '\$${(order.summary['shipping'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${(order.summary['total'] ?? 0.0).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/invoice_${order.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice for Order #${order.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Purchases'),
          ],
        ),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.orders.isEmpty) {
            return EmptyView(
              title: 'No Orders Yet',
              message:
                  'You have not placed any orders. Start exploring items today!',
              icon: Icons.receipt_long_outlined,
              buttonText: 'Browse Shop',
              onButtonPressed: () => context.go(AppRoutes.home),
            );
          }

          final activeOrders = state.orders
              .where((o) => o.status != 'delivered' && o.status != 'cancelled')
              .toList();
          final pastOrders = state.orders
              .where((o) => o.status == 'delivered' || o.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersListTab(
                orders: activeOrders,
                metrics: metrics,
                onShare: (o) => _exportAndShareInvoice(context, o),
              ),
              _OrdersListTab(
                orders: pastOrders,
                metrics: metrics,
                onShare: (o) => _exportAndShareInvoice(context, o),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersListTab extends StatelessWidget {
  final List<OrderEntity> orders;
  final AppMetrics metrics;
  final Function(OrderEntity) onShare;

  const _OrdersListTab({
    required this.orders,
    required this.metrics,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found in this section.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(metrics.space16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => SizedBox(height: metrics.space12),
      itemBuilder: (context, index) {
        final order = orders[index];
        Color statusColor = theme.colorScheme.primary;
        if (order.status == 'delivered') statusColor = Colors.green;
        if (order.status == 'cancelled') statusColor = Colors.red;

        return Card(
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: #${order.id.replaceAll('ord_', '')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Total Payment: \$${(order.summary['total'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(metrics.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    // 1. Items list
                    const Text(
                      'Items Purchased:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: metrics.space8),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.productName} (x${item.quantity})',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    // 2. Stepper Timeline Status
                    const Text(
                      'Shipment Timeline:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: metrics.space12),
                    _OrderStatusStepper(currentStatus: order.status),

                    const Divider(height: 24),

                    // 3. Invoice & QR Code
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order QR Signature:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: metrics.space8),
                              BarcodeWidget(
                                barcode: Barcode.qrCode(),
                                data: 'antigravity-invoice-verify:${order.id}',
                                width: 100,
                                height: 100,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            CustomButton(
                              text: 'Share Invoice',
                              icon: Icons.share,
                              onPressed: () => onShare(order),
                              width: 140,
                              height: 44,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderStatusStepper extends StatelessWidget {
  final String currentStatus;
  const _OrderStatusStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> steps = [
      'pending',
      'confirmed',
      'packed',
      'shipped',
      'delivered',
    ];

    // If order was cancelled, show simple alert instead of stepper
    if (currentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This order was cancelled by the administrator.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary.withOpacity(0.4),
                  size: 18,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: index < currentIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text(
                step.toUpperCase(),
                style: TextStyle(
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.secondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
