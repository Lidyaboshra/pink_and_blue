// whatsapp_helper.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class WhatsAppHelper {
  static const String _phoneNumber = "+201275036476"; // Replace with your WhatsApp number
  
  static Future<void> sendOrderWithLocation(
    BuildContext context,
    CartProvider cart,
    String customerPhone,
    String locationOrPickup,
    String notes,
  ) async {
    // Generate order message
    String message = _generateOrderMessage(cart, customerPhone, locationOrPickup, notes);
    
    // Encode message for URL
    String encodedMessage = Uri.encodeComponent(message);
    
    // Create WhatsApp URL
    String whatsappUrl = "https://wa.me/$_phoneNumber?text=$encodedMessage";
    
    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
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
      rethrow;
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
    
    // Add each item
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