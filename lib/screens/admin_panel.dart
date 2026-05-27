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
        const SnackBar(content: Text('Drink saved successfully!')),
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
      builder: (context) => AlertDialog(
        title: const Text("Delete Drink"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('drinks').delete().eq('id', id);
      _fetchDrinks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel - Manage Menu"),
        backgroundColor: const Color(0xFFFF69B4),
      ),
      body: Column(
        children: [
          // Image Picker
          Card(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: kIsWeb
                          ? Image.network(_selectedImage!.path, height: 150)
                          : Image.file(File(_selectedImage!.path), height: 150))
                else if (_existingImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      _existingImageUrl!,
                      height: 150,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick Image"),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: "Drink Name"),
                        validator: (v) => v!.isEmpty ? "Required" : null),
                    TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: "Description")),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _priceSmallController,
                                decoration: const InputDecoration(
                                    labelText: "Small Price"),
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextFormField(
                                controller: _priceMediumController,
                                decoration: const InputDecoration(
                                    labelText: "Medium Price"),
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextFormField(
                                controller: _priceLargeController,
                                decoration: const InputDecoration(
                                    labelText: "Large Price"),
                                keyboardType: TextInputType.number)),
                      ],
                    ),
                    SwitchListTile(
                        title: const Text("Mark as NEW"),
                        value: _isNew,
                        onChanged: (val) => setState(() => _isNew = val)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveDrink,
                      child: Text(_editingDrinkId == null
                          ? "ADD DRINK"
                          : "UPDATE DRINK"),
                    ),
                    if (_editingDrinkId != null)
                      TextButton(
                          onPressed: _clearForm, child: const Text("Cancel")),
                  ],
                ),
              ),
            ),
          ),

          // Drinks List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: drinks.length,
                    itemBuilder: (context, index) {
                      final drink = drinks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: drink.imageUrl != null
                                ? NetworkImage(drink.imageUrl!)
                                : null,
                            child: drink.imageUrl == null
                                ? const Icon(Icons.coffee)
                                : null,
                          ),
                          title: Text(drink.name),
                          subtitle: Text(
                              "S:${drink.priceSmall} M:${drink.priceMedium} L:${drink.priceLarge}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _editDrink(drink)),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteDrink(drink.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
