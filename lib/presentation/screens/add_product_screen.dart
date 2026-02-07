import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expiresense/data/models/product.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/primary_button.dart';
import 'package:expiresense/presentation/widgets/glass_box.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';
import 'package:expiresense/core/utils/date_utils.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final dynamic initialDate; // String or DateTime
  final String? initialName;
  final String? barcode;
  final Product? productToEdit;

  const AddProductScreen({
      super.key, 
      this.imagePath, 
      this.initialDate, 
      this.initialName, 
      this.barcode,
      this.productToEdit
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _expiryDate;
  DateTime? _customReminderDate;
  String _selectedCategory = "Groceries";

  List<String> _categories = [
    "Groceries", "Medicine", "Beauty", "Household", "Other"
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Edit Mode Setup
    if (widget.productToEdit != null) {
        final p = widget.productToEdit!;
        _nameController = TextEditingController(text: p.name);
        _expiryDate = p.expiryDate;
        _selectedCategory = _categories.contains(p.category) ? p.category! : "Other";
        _customReminderDate = p.customReminderDate;
        // If category is custom, add it to list implicitly for now or just set it
        if (!_categories.contains(p.category) && p.category != null) {
             _categories.insert(_categories.length - 1, p.category!);
             _selectedCategory = p.category!;
        }
    } else {
        // New Product Setup
        _nameController = TextEditingController(text: widget.initialName);
        
        // Parse Initial Date (Handle both String from AI and DateTime from ML Kit)
        if (widget.initialDate != null) {
            if (widget.initialDate is DateTime) {
                _expiryDate = widget.initialDate;
            } else if (widget.initialDate is String && widget.initialDate != "null" && widget.initialDate != "NOT_FOUND") {
                _expiryDate = AppDateUtils.parse(widget.initialDate);
            }
        }
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
      firstDate: now.subtract(const Duration(days: 365)), 
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    
    // Ensure lastDate is valid (must be >= now/firstDate)
    DateTime lastDate = (_expiryDate != null && _expiryDate!.isAfter(now)) 
        ? _expiryDate! 
        : now.add(const Duration(days: 365 * 5));

    // Ensure initialDate is valid
    DateTime initialDate = _customReminderDate ?? now.add(const Duration(days: 1));
    if (initialDate.isBefore(now)) initialDate = now;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    // 1. Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now, 
      lastDate: lastDate,
      helpText: "SET REMINDER DATE",
      builder: (context, child) => _datePickerTheme(child),
    );

    if (pickedDate != null) {
        // 2. Pick Time
        final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_customReminderDate ?? DateTime(now.year, now.month, now.day, 9, 0)),
            builder: (context, child) => _datePickerTheme(child),
            helpText: "SET REMINDER TIME",
        );

        if (pickedTime != null) {
            setState(() {
                _customReminderDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                );
            });
        }
    }
  }

  Theme _datePickerTheme(Widget? child) {
      return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonCyan,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
                backgroundColor: AppTheme.surfaceDark,
                hourMinuteTextColor: AppTheme.neonCyan,
                dayPeriodTextColor: Colors.white70,
                dialHandColor: AppTheme.neonCyan,
                dialBackgroundColor: Colors.white10,
                entryModeIconColor: AppTheme.neonCyan,
                helpTextStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
            ),
          ),
          child: child!,
      );
  }

  void _saveProduct() {
      if (_formKey.currentState!.validate() && _expiryDate != null) {
          HapticFeedback.mediumImpact();
          
          if (widget.productToEdit != null) {
              // EDIT MODE
               final newProduct = Product(
                   id: widget.productToEdit!.id,
                   name: _nameController.text,
                   expiryDate: _expiryDate!,
                   addedDate: widget.productToEdit!.addedDate,
                   imagePath: widget.imagePath ?? widget.productToEdit!.imagePath,
                   category: _selectedCategory,
                   barcode: widget.barcode ?? widget.productToEdit!.barcode,
                   isConsumed: widget.productToEdit!.isConsumed,
                   customReminderDate: _customReminderDate
               );
               
               ref.read(productListProvider.notifier).updateProduct(widget.productToEdit!.key, newProduct);
               
               if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated!", style: GoogleFonts.orbitron(color: Colors.black)), backgroundColor: AppTheme.neonCyan));
                    context.go('/');
               }
          } else {
              // CREATE MODE
              final product = Product(
                  name: _nameController.text,
                  expiryDate: _expiryDate!,
                  addedDate: DateTime.now(),
                  imagePath: widget.imagePath,
                  category: _selectedCategory,
                  barcode: widget.barcode,
                  customReminderDate: _customReminderDate
              );
              ref.read(productListProvider.notifier).addProduct(product);
              
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Item Logged", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                        backgroundColor: AppTheme.neonCyan,
                      ),
                  );
                  context.go('/'); 
              }
          }
      } else if (_expiryDate == null) {
           HapticFeedback.heavyImpact();
           ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please select an expiry date", style: GoogleFonts.outfit(color: Colors.white)), backgroundColor: AppTheme.errorRed),
          );
      }
  }

  // ... (Add Category Dialog - same as before) ...
  Future<String?> _showAddCategoryDialog() {
      final controller = TextEditingController();
      return showDialog<String>(
          context: context, 
          builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
              title: Text("New Category", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "e.g. Snacks", 
                    hintStyle: TextStyle(color: Colors.white30),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
                  ),
                  style: const TextStyle(color: Colors.white),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                      child: const Text("Add"),
                  ),
              ],
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null || (widget.productToEdit?.imagePath != null);
    final displayImagePath = widget.imagePath ?? widget.productToEdit?.imagePath;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? "EDIT ITEM" : "LOG ITEM", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (hasImage && displayImagePath != null)
             _buildImage(displayImagePath)
          else
             const TechBackground(child: SizedBox.expand()),
            
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   SizedBox(height: hasImage ? 100 : 20),
                   
                   GlassBox(
                    opacity: 0.05,
                    blur: 20,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(24.0),
                    border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: AppTheme.neonCyan.withOpacity(0.1), blurRadius: 15)],
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           Text("DETAILS", style: GoogleFonts.orbitron(fontSize: 12, color: AppTheme.neonCyan, letterSpacing: 2, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 20),
                           
                           // Name
                           TextFormField(
                               controller: _nameController,
                               style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                               decoration: _inputDecoration("PRODUCT NAME", Icons.shopping_bag_outlined),
                               validator: (value) => value == null || value.isEmpty ? "Required" : null,
                           ),
                           const SizedBox(height: 16),
                           
                           // Category
                           DropdownButtonFormField<String>(
                            value: _categories.contains(_selectedCategory) ? _selectedCategory : "Other",
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("CATEGORY", Icons.category_outlined),
                            items: [
                                ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit()))),
                                DropdownMenuItem(value: "custom", child: Text("+ Add New", style: GoogleFonts.orbitron(color: AppTheme.neonCyan, fontSize: 12))),
                            ], 
                            onChanged: (val) async {
                                if (val == "custom") {
                                    final newCat = await _showAddCategoryDialog();
                                    if (newCat != null && newCat.isNotEmpty) {
                                        setState(() {
                                            if (!_categories.contains(newCat)) _categories.insert(_categories.length - 1, newCat);
                                            _selectedCategory = newCat;
                                        });
                                    }
                                } else {
                                    setState(() => _selectedCategory = val ?? "Other");
                                }
                            },
                           ),
                           const SizedBox(height: 16),
                           
                           // Dates Row
                           Row(
                               children: [
                                   Expanded(child: _buildDatePicker(
                                       label: "EXPIRY DATE",
                                       date: _expiryDate,
                                       icon: Icons.calendar_today,
                                       color: Colors.greenAccent,
                                       onTap: _pickDate
                                   )),
                                   const SizedBox(width: 12),
                                   Expanded(child: _buildDatePicker(
                                       label: "REMINDER",
                                       date: _customReminderDate,
                                       icon: Icons.notifications_active,
                                       color: Colors.amberAccent,
                                       onTap: _pickReminderDate,
                                       placeholder: "Set Custom"
                                   )),
                               ],
                           ),
                           
                           const SizedBox(height: 40),
                           
                           PrimaryButton(
                               text: widget.productToEdit != null ? "UPDATE ITEM" : "CONFIRM LOG",
                               icon: widget.productToEdit != null ? Icons.update : Icons.save_alt,
                               onPressed: () {
                                   if (widget.productToEdit != null) {
                                       // Update Logic
                                       final newProduct = Product(
                                           id: widget.productToEdit!.id,
                                           name: _nameController.text,
                                           expiryDate: _expiryDate!,
                                           addedDate: widget.productToEdit!.addedDate,
                                           imagePath: displayImagePath,
                                           category: _selectedCategory,
                                           barcode: widget.productToEdit!.barcode,
                                           isConsumed: widget.productToEdit!.isConsumed,
                                           customReminderDate: _customReminderDate
                                       );
                                       
                                       ref.read(productListProvider.notifier).updateProduct(widget.productToEdit!.key, newProduct);
                                       
                                        if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated!", style: GoogleFonts.orbitron(color: Colors.black)), backgroundColor: AppTheme.neonCyan));
                                            context.go('/');
                                       }
                                   } else {
                                       // Create Logic
                                       _saveProduct();
                                   }
                               }
                           ),
                        ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
                      ),
                    ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    return Hero(
      tag: path,
      child: (path.startsWith('http')) 
        ? CachedNetworkImage(
            imageUrl: path,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.7),
            colorBlendMode: BlendMode.darken,
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.7),
            colorBlendMode: BlendMode.darken,
          ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
      return InputDecoration(
           labelText: label,
           labelStyle: GoogleFonts.orbitron(color: Colors.white54, fontSize: 10, letterSpacing: 1),
           prefixIcon: Icon(icon, color: AppTheme.neonCyan),
           enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
           focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.neonCyan), borderRadius: BorderRadius.circular(12)),
           filled: true,
           fillColor: Colors.white.withOpacity(0.05),
      );
  }

  Widget _buildDatePicker({required String label, required DateTime? date, required IconData icon, required Color color, required VoidCallback onTap, String placeholder = "Tap to Select"}) {
      return Material(
          color: Colors.transparent, 
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: date == null ? Colors.white.withOpacity(0.1) : color.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(label, style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 9, letterSpacing: 1))]),
                        const SizedBox(height: 6),
                        Text(
                            date != null 
                            ? (label == "REMINDER" ? DateFormat('MMM d, h:mm a').format(date) : DateFormat('MMM d, yyyy').format(date))
                            : placeholder,
                            style: GoogleFonts.orbitron(
                                color: date != null ? Colors.white : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                ],
            ),
          ),
      ));
  }
}
