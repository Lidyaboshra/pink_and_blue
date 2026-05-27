// whatsapp_helper.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class WhatsAppHelper {
  static const String _phoneNumber = "+201275036476"; // Your number

  static Future<void> sendOrderWithLocation(
    BuildContext context,
    CartProvider cart,
    String customerPhone,
    String locationOrPickup,
    String notes,
  ) async {
    if (cart.items.isEmpty) return;

    // 1. Save order to database FIRST
    bool saved = await _saveOrderToDatabase(
      cart, 
      customerPhone, 
      locationOrPickup, 
      notes
    );

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Generate beautiful message
    String message = _generateOrderMessage(
      cart, 
      customerPhone, 
      locationOrPickup, 
      notes
    );

    // 3. Open WhatsApp
    String encodedMessage = Uri.encodeComponent(message);
    String whatsappUrl = "https://wa.me/$_phoneNumber?text=$encodedMessage";

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        
        cart.clearCart(); // Clear cart after successful send
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<bool> _saveOrderToDatabase(
    CartProvider cart,
    String customerPhone,
    String locationOrPickup,
    String notes,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      final List<Map<String, dynamic>> itemsJson = cart.items.map((item) {
        double price = _getItemPrice(item);
        return {
          'name': item.drink.name,
          'size': item.size,
          'quantity': item.quantity,
          'price': price,
        };
      }).toList();

      await Supabase.instance.client.from('orders').insert({
        'user_id': user?.id,
        'items': itemsJson,
        'total': cart.total,
        'location': locationOrPickup,
        'phone': customerPhone,
        'notes': notes.isEmpty ? null : notes,
        'status': 'pending',
      });

      print("✅ Order saved successfully to Supabase");
      return true;
    } catch (e) {
      print("❌ Error saving order: $e");
      return false;
    }
  }

  static String _generateOrderMessage(
    CartProvider cart,
    String customerPhone,
    String locationOrPickup,
    String notes,
  ) {
    StringBuffer buffer = StringBuffer();
    
    buffer.writeln('🛍️ *NEW ORDER RECEIVED* 🛍️');
    buffer.writeln('━' * 30);
    buffer.writeln();
    
    buffer.writeln('📞 *Customer Phone:* $customerPhone');
    buffer.writeln();
    
    if (locationOrPickup.toLowerCase() == 'pickup') {
      buffer.writeln('📦 *Order Type:* PICKUP');
    } else {
      buffer.writeln('🚚 *Delivery Address:*');
      buffer.writeln(locationOrPickup);
    }
    buffer.writeln();
    
    buffer.writeln('━' * 30);
    buffer.writeln('🛒 *ORDER DETAILS*');
    buffer.writeln('━' * 30);
    buffer.writeln();
    
    for (int i = 0; i < cart.items.length; i++) {
      final item = cart.items[i];
      double price = _getItemPrice(item);
      double totalPrice = price * item.quantity;
      
      buffer.writeln('${i + 1}. *${item.drink.name}*');
      buffer.writeln('   Size: ${item.size}');
      buffer.writeln('   Quantity: ${item.quantity}');
      buffer.writeln('   Price: ${price.toStringAsFixed(2)} EGP');
      buffer.writeln('   Subtotal: ${totalPrice.toStringAsFixed(2)} EGP');
      buffer.writeln();
    }
    
    buffer.writeln('━' * 30);
    buffer.writeln('💰 *TOTAL: ${cart.total.toStringAsFixed(2)} EGP*');
    buffer.writeln('━' * 30);
    buffer.writeln();
    
    if (notes.isNotEmpty) {
      buffer.writeln('📝 *Special Notes:*');
      buffer.writeln(notes);
      buffer.writeln();
    }
    
    buffer.writeln('━' * 30);
    buffer.writeln('⏰ *Order Time:* ${DateTime.now().toString()}');
    buffer.writeln('✅ *Please confirm this order*');
    buffer.writeln();
    buffer.writeln('Thank you! 🙏');
    
    return buffer.toString();
  }

  static double _getItemPrice(CartItem item) {
    switch (item.size) {
      case 'Small':
        return item.drink.priceSmall ?? 0;
      case 'Medium':
        return item.drink.priceMedium ?? 0;
      case 'Large':
        return item.drink.priceLarge ?? 0;
      default:
        return 0;
    }
  }
}