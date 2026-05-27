import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/drink.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<Drink> drinks = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceSmallController = TextEditingController();
  final _priceMediumController = TextEditingController();
  final _priceLargeController = TextEditingController();

  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isNew = false;
  String? _editingDrinkId;

  final ImagePicker _picker = ImagePicker();
  
  // Responsive breakpoints
  bool get _isMobileWidth => MediaQuery.of(context).size.width < 600;
  bool get _isTabletWidth => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool get _isDesktopWidth => MediaQuery.of(context).size.width >= 1200;
  
  double get _formMaxWidth {
    if (_isDesktopWidth) return 800;
    if (_isTabletWidth) return 600;
    return double.infinity;
  }

  @override
  void initState() {
    super.initState();
    _fetchDrinks();
  }

  Future<void> _fetchDrinks() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('drinks')
          .select('*, categories(name)')
          .order('created_at', ascending: false);

      setState(() {
        drinks = (response as List).map((e) => Drink.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _existingImageUrl;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _selectedImage!.readAsBytes();

      await Supabase.instance.client.storage
          .from('drink-images')
          .uploadBinary(fileName, bytes);

      final imageUrl = Supabase.instance.client.storage
          .from('drink-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _saveDrink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final imageUrl = await _uploadImage();

      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image_url': imageUrl,
        'price_small': double.tryParse(_priceSmallController.text),
        'price_medium': double.tryParse(_priceMediumController.text),
        'price_large': double.tryParse(_priceLargeController.text),
        'is_new': _isNew,
        'category_id': 1,
      };

      if (_editingDrinkId != null) {
        await Supabase.instance.client
            .from('drinks')
            .update(data)
            .eq('id', _editingDrinkId!);
      } else {
        await Supabase.instance.client.from('drinks').insert(data);
      }

      _clearForm();
      _fetchDrinks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Drink saved successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF2C3E50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editDrink(Drink drink) {
    setState(() {
      _editingDrinkId = drink.id;
      _nameController.text = drink.name;
      _descriptionController.text = drink.description ?? '';
      _existingImageUrl = drink.imageUrl;
      _priceSmallController.text = drink.priceSmall?.toString() ?? '';
      _priceMediumController.text = drink.priceMedium?.toString() ?? '';
      _priceLargeController.text = drink.priceLarge?.toString() ?? '';
      _isNew = drink.isNew;
      _selectedImage = null;
    });
  }

  void _clearForm() {
    _editingDrinkId = null;
    _nameController.clear();
    _descriptionController.clear();
    _existingImageUrl = null;
    _selectedImage = null;
    _priceSmallController.clear();
    _priceMediumController.clear();
    _priceLargeController.clear();
    _isNew = false;
  }

  Future<void> _deleteDrink(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _isDesktopWidth ? 400 : double.infinity,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Drink",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to delete this drink? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      await Supabase.instance.client.from('drinks').delete().eq('id', id);
      await _fetchDrinks();
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Drink deleted successfully'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF69B4),
        elevation: 0,
        centerTitle: _isMobileWidth,
        actions: [
          if (_editingDrinkId != null)
            TextButton.icon(
              onPressed: _clearForm,
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text("Cancel Edit", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: _isDesktopWidth ? 1400 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.all(_isMobileWidth ? 12 : 20),
                  child: _isDesktopWidth
                      ? _buildDesktopLayout(constraints)
                      : _buildMobileTabletLayout(constraints),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form Section on the left
        Expanded(
          flex: 1,
          child: Container(
            constraints: BoxConstraints(maxWidth: _formMaxWidth),
            child: _buildFormSection(),
          ),
        ),
        const SizedBox(width: 24),
        // Drinks List on the right
        Expanded(
          flex: 2,
          child: _buildDrinksList(),
        ),
      ],
    );
  }
  
  Widget _buildMobileTabletLayout(BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: _formMaxWidth),
            child: _buildFormSection(),
          ),
        ),
        const SizedBox(height: 16),
        _buildDrinksList(),
      ],
    );
  }
  
  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isMobileWidth ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF69B4), Color(0xFFFF8CC8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _editingDrinkId == null ? Icons.add : Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _editingDrinkId == null ? "Add New Drink" : "Edit Drink",
                      style: TextStyle(
                        fontSize: _isMobileWidth ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Image Picker Section
              _buildImagePickerSection(),
              const SizedBox(height: 6),
              
              // Form Fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Drink Name",
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.coffee, color: Color(0xFFFF69B4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF69B4), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFFF69B4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF69B4), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: _isMobileWidth ? 2 : 3,
              ),
              const SizedBox(height: 16),
              
              // Pricing Section
              const Text(
                "Pricing",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              _isMobileWidth
                  ? Column(
                      children: [
                        _buildPriceField("Small", "S", _priceSmallController),
                        const SizedBox(height: 12),
                        _buildPriceField("Medium", "M", _priceMediumController),
                        const SizedBox(height: 12),
                        _buildPriceField("Large", "L", _priceLargeController),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildPriceField("Small", "S", _priceSmallController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPriceField("Medium", "M", _priceMediumController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPriceField("Large", "L", _priceLargeController)),
                      ],
                    ),
              const SizedBox(height: 16),
              
              // New Badge Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isNew ? const Color(0xFFFF69B4).withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isNew ? const Color(0xFFFF69B4) : Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.new_releases,
                          color: _isNew ? const Color(0xFFFF69B4) : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Mark as NEW",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isNew,
                      onChanged: (val) => setState(() => _isNew = val),
                      activeColor: const Color(0xFFFF69B4),
                      activeTrackColor: const Color(0xFFFF69B4).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveDrink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                        padding: EdgeInsets.symmetric(vertical: _isMobileWidth ? 12 : 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_editingDrinkId == null ? Icons.add : Icons.update, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _editingDrinkId == null ? "ADD DRINK" : "UPDATE DRINK",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_editingDrinkId != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: _isMobileWidth ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text("CANCEL"),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImagePickerSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (_selectedImage != null || _existingImageUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage?.path ?? _existingImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Failed to load image",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(_selectedImage?.path ?? _existingImageUrl!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Failed to load image",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _existingImageUrl = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: (_selectedImage != null || _existingImageUrl != null) ? 60 : 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 35,
                      color: const Color(0xFFFF69B4),
                    ),
                    Text(
                      (_selectedImage != null || _existingImageUrl != null)
                          ? "Change Image"
                          : "Tap to select an image",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrinksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Menu Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF69B4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${drinks.length} items",
                  style: const TextStyle(
                    color: Color(0xFFFF69B4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
                      ),
                      SizedBox(height: 16),
                      Text("Loading menu items..."),
                    ],
                  ),
                ),
              )
            : drinks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No drinks added yet",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add your first drink using the form above",
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : _isDesktopWidth
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: drinks.length,
                        itemBuilder: (context, index) {
                          final drink = drinks[index];
                          return _buildDrinkCard(drink);
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: drinks.length,
                        itemBuilder: (context, index) {
                          final drink = drinks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDrinkCard(drink),
                          );
                        },
                      ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildDrinkCard(Drink drink) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _editDrink(drink),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(_isDesktopWidth ? 16 : 12),
            child: _isDesktopWidth
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section for desktop grid view
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[100],
                          child: drink.imageUrl != null && drink.imageUrl!.isNotEmpty
                              ? Image.network(
                                  drink.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.coffee, size: 40, color: Colors.grey[400]);
                                  },
                                )
                              : Icon(Icons.coffee, size: 40, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              drink.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (drink.isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF69B4), Color(0xFFFF8CC8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "NEW",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (drink.priceSmall != null)
                            _buildPriceTag("S", drink.priceSmall!),
                          if (drink.priceMedium != null)
                            _buildPriceTag("M", drink.priceMedium!),
                          if (drink.priceLarge != null)
                            _buildPriceTag("L", drink.priceLarge!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF69B4), size: 20),
                            onPressed: () => _editDrink(drink),
                            tooltip: "Edit",
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteDrink(drink.id),
                            tooltip: "Delete",
                          ),
                        ],
                      ),
                    ],
                  )
                : ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                        child: drink.imageUrl != null && drink.imageUrl!.isNotEmpty
                            ? Image.network(
                                drink.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.coffee, size: 30, color: Colors.grey[400]);
                                },
                              )
                            : Icon(Icons.coffee, size: 30, color: Colors.grey[400]),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            drink.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        if (drink.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF69B4), Color(0xFFFF8CC8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "NEW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (drink.priceSmall != null)
                            _buildPriceTag("S", drink.priceSmall!),
                          if (drink.priceMedium != null)
                            _buildPriceTag("M", drink.priceMedium!),
                          if (drink.priceLarge != null)
                            _buildPriceTag("L", drink.priceLarge!),
                        ],
                      ),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF69B4)),
                            onPressed: () => _editDrink(drink),
                            tooltip: "Edit",
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteDrink(drink.id),
                            tooltip: "Delete",
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPriceField(String label, String prefix, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: "Price",
        prefixText: "$prefix: ",
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF69B4), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: TextInputType.number,
    );
  }
  
  Widget _buildPriceTag(String size, num price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF69B4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$size: $price EGP",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFF69B4),
        ),
      ),
    );
  }
}