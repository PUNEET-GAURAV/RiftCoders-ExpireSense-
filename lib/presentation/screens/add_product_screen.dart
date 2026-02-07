import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expiresense/data/models/product.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/core/utils/date_utils.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final String? initialDate;
  final String? initialName; // New field

  const AddProductScreen({super.key, this.imagePath, this.initialDate, this.initialName});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _expiryDate;
  String _selectedCategory = "Groceries";

  final List<String> _categories = [
    "Groceries",
    "Medicine", 
    "Beauty", 
    "Household",
    "Other"
  ];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName); // Pre-fill name
    
    // Parse Initial Date from AI
    if (widget.initialDate != null && widget.initialDate != "null" && widget.initialDate != "NOT_FOUND") {
        _expiryDate = AppDateUtils.parse(widget.initialDate);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)), // Allow past dates (maybe bought earlier)
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _saveProduct() {
      if (_formKey.currentState!.validate() && _expiryDate != null) {
          final product = Product(
              name: _nameController.text,
              expiryDate: _expiryDate!,
              addedDate: DateTime.now(),
              imagePath: widget.imagePath,
              category: _selectedCategory,
          );
          
          ref.read(productListProvider.notifier).addProduct(product);
          
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product Saved!")),
              );
              context.go('/'); // Back to home
          }
      } else if (_expiryDate == null) {
           ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an expiry date")),
          );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    if (widget.imagePath != null)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: kIsWeb 
                                    ? Image.network(
                                        widget.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                    )
                                    : Image.file(
                                        File(widget.imagePath!),
                                        fit: BoxFit.cover,
                                    ),
                            )
                        ),
                    const SizedBox(height: 24),
                    TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: "Product Name",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? "Provide a name" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
                      onChanged: (val) => setState(() => _selectedCategory = val ?? "Other"),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: "Expiry Date",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                                _expiryDate != null 
                                ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
                                : "Select Date",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _expiryDate == null ? Colors.grey : null
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                        onPressed: _saveProduct,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Save Item"),
                    )
                ],
            ),
        ),
      ),
    );
  }
}
