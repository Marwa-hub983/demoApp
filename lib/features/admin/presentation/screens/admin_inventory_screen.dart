import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../bloc/admin_cubit.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _skuSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdminCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _skuSearchController.dispose();
    super.dispose();
  }

  void _showRestockDialog(BuildContext context, ProductEntity product) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController(
      text: 'Manual shelf inventory restock',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Restock: ${product.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current stock level: ${product.stock} units'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: amountCtrl,
                  labelText: 'Restock Quantity',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter quantity';
                    if (int.tryParse(val) == null || int.parse(val) <= 0) {
                      return 'Enter positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: notesCtrl,
                  labelText: 'Restock Notes',
                  validator: (val) => val!.isEmpty ? 'Notes required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Save Restock',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<AdminCubit>().restockProduct(
                    product.id,
                    int.parse(amountCtrl.text),
                    notesCtrl.text.trim(),
                  );
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restocked ${product.name} successfully!'),
                    ),
                  );
                }
              },
              width: 130,
              height: 40,
            ),
          ],
        );
      },
    );
  }

  void _simulateBarcodeScan(BuildContext context, String barcode) {
    final state = context.read<AdminCubit>().state;
    final matches = state.products
        .where((p) => p.barcode == barcode || p.sku == barcode)
        .toList();

    if (matches.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Scan Error'),
          content: Text(
            'No product catalog matches found for scan input: "$barcode"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    } else {
      final product = matches.first;
      // Show Restock sheet immediately
      _showRestockDialog(context, product);
    }
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
        title: const Text('Inventory Console'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stock Logs'),
            Tab(text: 'Low Stock Alerts'),
            Tab(text: 'QR Scanner'),
          ],
        ),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Stock Logs
              _buildStockLogsTab(state, metrics, theme),

              // Tab 2: Low Stock Alerts
              _buildLowStockTab(state, metrics, theme),

              // Tab 3: QR Scanner Simulator
              _buildScannerSimulatorTab(state, metrics, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockLogsTab(
    AdminState state,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    if (state.stockLogs.isEmpty) {
      return const Center(child: Text('No inventory transactions logged.'));
    }

    return ListView.separated(
      padding: EdgeInsets.all(metrics.space16),
      itemCount: state.stockLogs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = state.stockLogs[index];
        final isDeduction = (log['change'] as int) < 0;
        final changeColor = isDeduction ? Colors.red : Colors.green;
        final prefix = isDeduction ? '' : '+';
        final date = DateTime.parse(log['date'].toString());

        return ListTile(
          leading: Icon(
            isDeduction ? Icons.arrow_outward : Icons.call_received,
            color: changeColor,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SKU: ${log['sku']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '$prefix${log['change']}',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${log['notes']}', style: const TextStyle(fontSize: 12)),
              Text(
                '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockTab(
    AdminState state,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    if (state.lowStockProducts.isEmpty) {
      return const EmptyView(
        title: 'All Inventory Healthy',
        message: 'No catalog products have fallen below critical stock limits.',
        icon: Icons.done_all,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(metrics.space16),
      itemCount: state.lowStockProducts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final prod = state.lowStockProducts[index];
        return ListTile(
          leading: const Icon(Icons.warning, color: Colors.amber),
          title: Text(
            prod.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Text('SKU: ${prod.sku} • Current: ${prod.stock} left'),
          trailing: CustomButton(
            text: 'Restock',
            onPressed: () => _showRestockDialog(context, prod),
            width: 80,
            height: 36,
          ),
        );
      },
    );
  }

  Widget _buildScannerSimulatorTab(
    AdminState state,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(metrics.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual scanning guide card representation
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(metrics.radius16),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.tertiary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: 20,
                  right: 20,
                  child: Container(height: 2, color: Colors.red),
                ),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white38, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'CAMERA VIEWPORT INITIALIZED',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: metrics.space24),

          Text(
            'Scan Product Barcode:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: metrics.space12),

          // Search manual SKU input
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _skuSearchController,
                  hintText: 'Enter SKU or Barcode (e.g. 190199223344)',
                ),
              ),
              SizedBox(width: metrics.space12),
              CustomButton(
                text: 'Scan',
                onPressed: () {
                  if (_skuSearchController.text.isNotEmpty) {
                    _simulateBarcodeScan(
                      context,
                      _skuSearchController.text.trim(),
                    );
                    _skuSearchController.clear();
                  }
                },
                width: 100,
                height: 48,
              ),
            ],
          ),

          SizedBox(height: metrics.space24),

          const Text(
            'Select Product SKU to Scan:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: metrics.space12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final prod = state.products[index];
              return ListTile(
                leading: const Icon(Icons.qr_code),
                title: Text(prod.name, style: const TextStyle(fontSize: 13)),
                subtitle: Text('Barcode: ${prod.barcode}'),
                onTap: () => _simulateBarcodeScan(context, prod.barcode),
              );
            },
          ),
        ],
      ),
    );
  }
}
