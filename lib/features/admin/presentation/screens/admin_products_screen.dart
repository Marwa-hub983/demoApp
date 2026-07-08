import 'package:demo_app/features/products/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/state_views.dart';

import '../bloc/admin_cubit.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard();
  }

  void _showAddEditProductDialog(
    BuildContext context,
    ProductEntity? existingProduct,
  ) {
    final isEdit = existingProduct != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingProduct?.name);
    final descCtrl = TextEditingController(text: existingProduct?.description);
    final priceCtrl = TextEditingController(
      text: existingProduct?.price.toString(),
    );
    final discountCtrl = TextEditingController(
      text: existingProduct?.discount.toString(),
    );
    final stockCtrl = TextEditingController(
      text: existingProduct?.stock.toString(),
    );
    final skuCtrl = TextEditingController(text: existingProduct?.sku);
    final barcodeCtrl = TextEditingController(text: existingProduct?.barcode);

    String? selectedCategoryId = existingProduct?.categoryId;
    final state = context.read<AdminCubit>().state;
    if (selectedCategoryId == null && state.categories.isNotEmpty) {
      selectedCategoryId = state.categories.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final metrics =
            Theme.of(dialogCtx).extension<AppMetrics>() ??
            AppMetrics.standard();
        return AlertDialog(
          title: Text(isEdit ? 'Edit Catalog Product' : 'Add New Product'),
          content: Form(
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
                          // labelText: 'Price ($)',
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
                  if (!isEdit) ...[
                    CustomTextField(
                      controller: stockCtrl,
                      labelText: 'Initial Stock',
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val!.isEmpty ? 'Stock required' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: skuCtrl,
                          labelText: 'SKU Code',
                          validator: (val) =>
                              val!.isEmpty ? 'SKU required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: barcodeCtrl,
                          labelText: 'Barcode',
                          validator: (val) =>
                              val!.isEmpty ? 'Barcode required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for category
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Save',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (isEdit) {
                    context.read<AdminCubit>().editProduct(
                      ProductEntity(
                        id: existingProduct.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: double.parse(priceCtrl.text),
                        discount: double.parse(discountCtrl.text),
                        categoryId: selectedCategoryId!,
                        stock: existingProduct.stock,
                        sku: skuCtrl.text.trim(),
                        barcode: barcodeCtrl.text.trim(),
                        images: existingProduct.images,
                        variants: existingProduct.variants,
                        ratings: existingProduct.ratings,
                        reviews: existingProduct.reviews,
                        isEnabled: existingProduct.isEnabled,
                      ),
                    );
                  } else {
                    context.read<AdminCubit>().createProduct(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      price: double.parse(priceCtrl.text),
                      discount: double.parse(discountCtrl.text),
                      categoryId: selectedCategoryId!,
                      initialStock: int.parse(stockCtrl.text),
                      sku: skuCtrl.text.trim(),
                      barcode: barcodeCtrl.text.trim(),
                      images: const [],
                      variants: const {},
                    );
                  }
                  Navigator.pop(dialogCtx);
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
        title: const Text('Products Catalog CRUD'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () => _showAddEditProductDialog(context, null),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.products.isEmpty) {
            return const EmptyView(
              title: 'Empty Catalog',
              message: 'Add catalog products to get started.',
              icon: Icons.grid_off_outlined,
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(metrics.space16),
            itemCount: state.products.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final prod = state.products[index];
              return Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(metrics.radius8),
                      image: DecorationImage(
                        image: NetworkImage(prod.images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${prod.sku}',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 11,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${prod.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Active status switch
                            Switch.adaptive(
                              value: prod.isEnabled,
                              onChanged: (val) {
                                context.read<AdminCubit>().editProduct(
                                  ProductEntity(
                                    id: prod.id,
                                    name: prod.name,
                                    description: prod.description,
                                    price: prod.price,
                                    discount: prod.discount,
                                    categoryId: prod.categoryId,
                                    stock: prod.stock,
                                    sku: prod.sku,
                                    barcode: prod.barcode,
                                    images: prod.images,
                                    variants: prod.variants,
                                    ratings: prod.ratings,
                                    reviews: prod.reviews,
                                    isEnabled: val,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () =>
                            _showAddEditProductDialog(context, prod),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text(
                                'Are you sure you want to remove ${prod.name} from catalog?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<AdminCubit>().deleteProduct(
                                      prod.id,
                                    );
                                    Navigator.pop(confirmCtx);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
