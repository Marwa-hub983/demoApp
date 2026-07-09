import 'package:demo_app/features/admin/widgets/barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../authentication/presentation/bloc/auth_cubit.dart';
import '../bloc/admin_cubit.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductEntity? _scannedProduct;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdminCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Common Dialog for Restock and Reduce Stock
  void _showStockUpdateDialog(
    BuildContext context,
    ProductEntity product, {
    required bool isRestock,
  }) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController(
      text: isRestock
          ? 'Received new shipment'
          : 'Damaged / Expired stock write-off',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            isRestock
                ? 'Restock: ${product.name}'
                : 'Reduce Stock: ${product.name}',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current stock level: ${product.stock} units'),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: amountCtrl,
                  labelText: isRestock
                      ? 'Quantity to Add'
                      : 'Quantity to Reduce',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter quantity';
                    final qty = int.tryParse(val);
                    if (qty == null || qty <= 0) {
                      return 'Enter a positive integer';
                    }
                    if (!isRestock && qty > product.stock) {
                      return 'Cannot reduce stock below 0 (Max: ${product.stock})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: notesCtrl,
                  labelText: 'Transaction Notes',
                  validator: (val) =>
                      val!.trim().isEmpty ? 'Notes required' : null,
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
              text: isRestock ? 'Save Restock' : 'Save Deduction',
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final qty = int.parse(amountCtrl.text);
                  final notes = notesCtrl.text.trim();

                  // Get logged in user details
                  final authState = context.read<AuthCubit>().state;
                  String userStr = 'Admin';
                  if (authState is AuthAuthenticated) {
                    userStr =
                        '${authState.user.fullName} (${authState.user.email})';
                  }

                  try {
                    await context.read<AdminCubit>().updateStock(
                      productId: product.id,
                      amount: isRestock ? qty : -qty,
                      action: isRestock ? 'Restock' : 'Deduction',
                      userName: userStr,
                      notes: notes,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRestock
                              ? 'Restocked ${product.name} with $qty units!'
                              : 'Reduced stock of ${product.name} by $qty units!',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              width: 140,
              height: 40,
            ),
          ],
        );
      },
    );
  }

  // Dialog for Viewing Full Product Details
  void _showViewDetailsDialog(
    BuildContext context,
    ProductEntity product,
    String categoryName,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(product.name)),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(dialogCtx).size.width > 450
                ? 400
                : MediaQuery.of(dialogCtx).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.images.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.images.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDetailItem('SKU', product.sku, icon: Icons.qr_code_2),
                  _buildDetailItem(
                    'Barcode',
                    product.barcode,
                    icon: Icons.barcode_reader,
                  ),
                  _buildDetailItem(
                    'Category',
                    categoryName,
                    icon: Icons.category,
                  ),
                  _buildDetailItem(
                    'Price',
                    '\$${product.price.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                  ),
                  _buildDetailItem(
                    'Discount',
                    '${product.discount}%',
                    icon: Icons.percent,
                  ),
                  _buildDetailItem(
                    'Current Stock',
                    '${product.stock} units',
                    icon: Icons.warehouse,
                  ),
                  _buildDetailItem(
                    'Rating',
                    '${product.ratings} ★ (${product.reviews.length} reviews)',
                    icon: Icons.star_rate,
                  ),
                  const Divider(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Dialog for Editing Catalog Product (synced with admin_products_screen checks)
  void _showEditProductDialog(BuildContext context, ProductEntity product) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final discountCtrl = TextEditingController(
      text: product.discount.toString(),
    );
    final skuCtrl = TextEditingController(text: product.sku);
    final barcodeCtrl = TextEditingController(text: product.barcode);

    String? selectedCategoryId = product.categoryId;
    final state = context.read<AdminCubit>().state;
    if (selectedCategoryId == null && state.categories.isNotEmpty) {
      selectedCategoryId = state.categories.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Edit Product: ${product.name}'),
          content: SizedBox(
            width: MediaQuery.of(dialogCtx).size.width > 450
                ? 400
                : MediaQuery.of(dialogCtx).size.width * 0.9,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameCtrl,
                    labelText: 'Product Name',
                    validator: (val) => val!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: descCtrl,
                    labelText: 'Description',
                    validator: (val) =>
                        val!.isEmpty ? 'Description required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: priceCtrl,
                          labelText: 'Price (\$)',
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              val!.isEmpty ? 'Price required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: discountCtrl,
                          labelText: 'Discount (%)',
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              val!.isEmpty ? 'Discount required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: skuCtrl,
                          labelText: 'SKU Code',
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'SKU required';
                            final skuExists = state.products.any(
                              (p) =>
                                  p.sku.trim().toLowerCase() ==
                                      val.trim().toLowerCase() &&
                                  p.id != product.id,
                            );
                            if (skuExists) return 'SKU already exists';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: barcodeCtrl,
                          labelText: 'Barcode',
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Barcode required';
                            final barcodeExists = state.products.any(
                              (p) =>
                                  p.barcode.trim().toLowerCase() ==
                                      val.trim().toLowerCase() &&
                                  p.id != product.id,
                            );
                            if (barcodeExists) return 'Barcode already exists';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                    ),
                    items: state.categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      selectedCategoryId = val;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await context.read<AdminCubit>().editProduct(
                      ProductEntity(
                        id: product.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: double.parse(priceCtrl.text),
                        discount: double.parse(discountCtrl.text),
                        categoryId: selectedCategoryId!,
                        stock: product.stock,
                        sku: skuCtrl.text.trim(),
                        barcode: barcodeCtrl.text.trim(),
                        images: product.images,
                        variants: product.variants,
                        ratings: product.ratings,
                        reviews: product.reviews,
                        isEnabled: product.isEnabled,
                      ),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Product "${nameCtrl.text.trim()}" updated successfully!',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              width: 100,
              height: 40,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  void _handleBarcodeScanned(BuildContext context, String barcode) {
    final search = barcode.trim().toLowerCase();
    final products = context.read<AdminCubit>().state.products;

    ProductEntity? product;
    try {
      product = products.firstWhere(
        (p) =>
            p.barcode.trim().toLowerCase() == search ||
            p.sku.trim().toLowerCase() == search,
      );
    } catch (_) {}

    if (product == null) {
      setState(() {
        _scannedProduct = null;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Product Not Found'),
          content: Text('No product found for this barcode:\n\n$barcode'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _scannedProduct = product;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product match found: ${product.name}')),
      );
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
            Tab(text: 'Stock Management'),
            Tab(text: 'Low Stock Alerts'),
            Tab(text: 'Transaction History'),
          ],
        ),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Stock Management
              _buildStockManagementTab(state, metrics, theme),

              // Tab 2: Low Stock Alerts
              _buildLowStockTab(state, metrics, theme),

              // Tab 3: Transaction History
              _buildTransactionHistoryTab(state, metrics, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockManagementTab(
    AdminState state,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    // Keep scanned product in sync with state changes
    ProductEntity? scannedProduct;
    if (_scannedProduct != null) {
      try {
        scannedProduct = state.products.firstWhere(
          (p) => p.id == _scannedProduct!.id,
        );
      } catch (_) {
        scannedProduct = _scannedProduct;
      }
    }

    // Local manual search filtering
    final query = _searchQuery.trim().toLowerCase();
    final filteredProducts = state.products.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.all(metrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field & Scan Barcode trigger row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  hintText: 'Search Name, SKU, or Barcode...',
                  prefixIcon: Icons.search,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.radius12),
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () async {
                    final barcode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen(),
                      ),
                    );

                    if (!context.mounted) return;
                    if (barcode == null || barcode.isEmpty) return;

                    _handleBarcodeScanned(context, barcode);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scanned Product Match details card
          if (scannedProduct != null) ...[
            _buildScannedMatchCard(scannedProduct, state, metrics, theme),
            const SizedBox(height: 16),
          ],

          // Search results
          Expanded(
            child: filteredProducts.isEmpty
                ? const EmptyView(
                    title: 'No Products Found',
                    message:
                        'No product matched your search query in this catalog.',
                    icon: Icons.search_off_outlined,
                  )
                : ListView.separated(
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prod = filteredProducts[index];
                      final category = state.categories.firstWhere(
                        (c) => c.id == prod.categoryId,
                        orElse: () => const CategoryEntity(
                          id: '',
                          name: 'General',
                          icon: '',
                        ),
                      );

                      return _buildProductCard(
                        prod,
                        category.name,
                        metrics,
                        theme,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedMatchCard(
    ProductEntity product,
    AdminState state,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    final category = state.categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => const CategoryEntity(id: '', name: 'General', icon: ''),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.radius16),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      color: theme.colorScheme.primaryContainer.withOpacity(0.15),
      child: Padding(
        padding: EdgeInsets.all(metrics.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SCANNED PRODUCT MATCH',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _scannedProduct = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(metrics.radius12),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey[200],
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Barcode: ${product.barcode}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Category: ${category.name}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price: \$${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(product.stock, metrics, theme),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(metrics.radius8),
                      ),
                    ),
                    onPressed: () => _showStockUpdateDialog(
                      context,
                      product,
                      isRestock: false,
                    ),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Reduce Stock',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(metrics.radius8),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () => _showStockUpdateDialog(
                      context,
                      product,
                      isRestock: true,
                    ),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Restock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    ProductEntity product,
    String categoryName,
    AppMetrics metrics,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.space12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(metrics.radius8),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey[200],
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.barcode_reader,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Barcode: ${product.barcode}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          _buildStatusBadge(product.stock, metrics, theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _showViewDetailsDialog(context, product, categoryName),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => _showEditProductDialog(context, product),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.radius8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () =>
                      _showStockUpdateDialog(context, product, isRestock: true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Restock', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int stock, AppMetrics metrics, ThemeData theme) {
    String text;
    Color color;
    if (stock <= 0) {
      text = 'Out of Stock';
      color = Colors.red;
    } else if (stock <= 5) {
      text = 'Low Stock ($stock)';
      color = Colors.orange;
    } else {
      text = 'In Stock ($stock)';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(metrics.radius8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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

    final colors = theme.extension<AppColorsExtension>();

    return ListView.separated(
      padding: EdgeInsets.all(metrics.space16),
      itemCount: state.lowStockProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prod = state.lowStockProducts[index];
        final category = state.categories.firstWhere(
          (c) => c.id == prod.categoryId,
          orElse: () => const CategoryEntity(id: '', name: 'General', icon: ''),
        );

        return Card(
          color: (colors?.warning ?? Colors.amber).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.radius12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            title: Text(
              prod.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'SKU: ${prod.sku} • Stock: ${prod.stock} units remaining',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () =>
                      _showViewDetailsDialog(context, prod, category.name),
                ),
                CustomButton(
                  text: 'Restock',
                  onPressed: () =>
                      _showStockUpdateDialog(context, prod, isRestock: true),
                  width: 80,
                  height: 36,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistoryTab(
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = state.stockLogs[index];
        final change = log['change'] as int? ?? 0;
        final isDeduction = change < 0;
        final type = log['type']?.toString().toLowerCase() ?? '';

        final String actionLabel;
        final Color accentColor;
        final IconData logIcon;

        if (type == 'create' || type == 'creation') {
          actionLabel = 'Creation';
          accentColor = Colors.blue;
          logIcon = Icons.add_to_photos_outlined;
        } else if (isDeduction || type == 'deduction') {
          actionLabel = 'Deduction';
          accentColor = Colors.red;
          logIcon = Icons.arrow_downward_outlined;
        } else {
          actionLabel = 'Restock';
          accentColor = Colors.green;
          logIcon = Icons.arrow_upward_outlined;
        }

        final changeSign = change >= 0 ? '+' : '';
        final date =
            DateTime.tryParse(log['date']?.toString() ?? '') ?? DateTime.now();

        // Safe historical mappings
        final prevStock = log['previousStock'] ?? 0;
        final nextStock = log['updatedStock'] ?? (prevStock + change);
        final notes = log['notes']?.toString() ?? 'Initial seed stock loading';
        final user = log['user']?.toString() ?? 'System';
        final barcode = log['barcode']?.toString() ?? 'N/A';
        final productName = log['productName']?.toString() ?? 'Unknown Product';
        final sku = log['sku']?.toString() ?? 'N/A';

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.radius12),
            side: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(metrics.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(logIcon, color: accentColor, size: 18),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                              metrics.radius4,
                            ),
                          ),
                          child: Text(
                            actionLabel.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$changeSign$change units',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SKU: $sku',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Barcode: $barcode',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock: $prevStock → $nextStock',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '${date.day}/${date.month}/${date.year} ${date.hour.pad()}:${date.minute.pad()}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  'Notes: "$notes"',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'By: $user',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on int {
  String pad() => toString().padLeft(2, '0');
}
