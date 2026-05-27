import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pink_and_blue/screens/menu_screen.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/whatsapp_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  bool _isPlacingOrder = false;
  String? _selectedLocationType = 'delivery';

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _phoneFocusNode.dispose();
    _locationFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  // Function to unfocus all fields (important for web)
  void _unfocusAllFields() {
    _phoneFocusNode.unfocus();
    _locationFocusNode.unfocus();
    _notesFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    // Unfocus all fields to prevent web pointer errors
    _unfocusAllFields();

    // Small delay to ensure focus is removed
    await Future.delayed(const Duration(milliseconds: 100));

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location
    if (_selectedLocationType == 'delivery' &&
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Phone number validation
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // Send order via WhatsApp
      await WhatsAppHelper.sendOrderWithLocation(
        context,
        cart,
        _phoneController.text,
        _selectedLocationType == 'delivery'
            ? _locationController.text
            : 'Pickup',
        _notesController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order placed successfully! Thank you for your order.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Clear cart after successful order
        cart.clearCart();

        // Clear form fields
        _locationController.clear();
        _phoneController.clear();
        _notesController.clear();
        _selectedLocationType = 'delivery';

        // Navigate back after delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Your Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF69B4),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _unfocusAllFields();
                setState(() {});
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: GestureDetector(
        // Tap anywhere to unfocus fields (helps with web pointer issues)
        onTap: _unfocusAllFields,
        child: cart.items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Your cart is empty 🍵",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildCartItemsList(cart),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildOrderForm(cart),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCartItemsList(cart),
                            const SizedBox(height: 24),
                            _buildOrderForm(cart),
                          ],
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildCartItemsList(CartProvider cart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFF69B4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Order Items",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${cart.items.length} items",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              double price = item.size == 'Small'
                  ? (item.drink.priceSmall ?? 0)
                  : item.size == 'Medium'
                      ? (item.drink.priceMedium ?? 0)
                      : (item.drink.priceLarge ?? 0);

              return Dismissible(
                key: Key('${item.drink.id}_${item.size}_${index}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  cart.removeItem(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item removed from cart'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.coffee,
                        color: Color(0xFFFF69B4),
                      ),
                    ),
                    title: Text(
                      item.drink.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "${item.size} ×${item.quantity}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${(price * item.quantity).toStringAsFixed(2)} EGP",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFFF69B4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _unfocusAllFields();
                                cart.decreaseQuantity(item);
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.quantity.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _unfocusAllFields();
                                cart.increaseQuantity(item);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${cart.total.toStringAsFixed(2)} EGP",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF69B4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm(CartProvider cart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Order Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),

              // Order Type Selection
              const Text(
                "Order Type",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'delivery',
                      label: Text('Delivery'),
                      icon: Icon(Icons.delivery_dining)),
                  ButtonSegment(
                      value: 'pickup',
                      label: Text('Pickup'),
                      icon: Icon(Icons.store)),
                ],
                selected: {_selectedLocationType!},
                onSelectionChanged: (Set<String> selection) {
                  _unfocusAllFields();
                  setState(() {
                    _selectedLocationType = selection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFFF69B4);
                    }
                    return Colors.grey[100];
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.grey[700];
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              const Text(
                "Phone Number *",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF69B4)),
                  hintText: "Enter your phone number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF69B4), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onFieldSubmitted: (_) {
                  if (_selectedLocationType == 'delivery') {
                    _locationFocusNode.requestFocus();
                  } else {
                    _notesFocusNode.requestFocus();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Location Section (only for delivery)
              if (_selectedLocationType == 'delivery') ...[
                const Text(
                  "Delivery Address *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  focusNode: _locationFocusNode,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_selectedLocationType == 'delivery' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your delivery address';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.location_on, color: Color(0xFFFF69B4)),
                    hintText: "Enter your full address",
                    helperText:
                        "Street name, Building number, Floor, Apartment, Landmark",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFFF69B4), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onFieldSubmitted: (_) {
                    _notesFocusNode.requestFocus();
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Make sure to enter your complete address for accurate delivery",
                          style:
                              TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes Field
              const Text(
                "Special Notes (Optional)",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.note, color: Color(0xFFFF69B4)),
                  hintText:
                      "Any special requests? (e.g., extra sugar, no ice, etc.)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF69B4), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onFieldSubmitted: (_) {
                  _unfocusAllFields();
                },
              ),
              const SizedBox(height: 24),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF69B4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal:",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "${cart.total.toStringAsFixed(2)} EGP",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      _isPlacingOrder ? null : () => _placeOrder(context, cart),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              "PLACE ORDER VIA WHATSAPP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
