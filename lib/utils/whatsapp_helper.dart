import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class WhatsAppHelper {
  static const String whatsappNumber = "201275036476"; // ← CHANGE THIS TO YOUR NUMBER

  static Future<void> sendOrder(BuildContext context, CartProvider cart) async {
    if (cart.items.isEmpty) return;

    String message = "🛍️ *New Order from Pink & Blue Coffee Shop*\n\n";

    for (var item in cart.items) {
      double price = 0;
      if (item.size == 'Small') price = item.drink.priceSmall ?? 0;
      else if (item.size == 'Medium') price = item.drink.priceMedium ?? 0;
      else price = item.drink.priceLarge ?? 0;

      message += "• ${item.drink.name} (${item.size}) ×${item.quantity} - ${price} EGP\n";
    }

    message += "\n💰 *Total: ${cart.total.toStringAsFixed(2)} EGP*";
    message += "\n\n📍 Location: Customer in Cairo";
    message += "\n⏰ Time: ${DateTime.now().toString().substring(0, 16)}";

    final encodedMessage = Uri.encodeComponent(message);
    final url = "https://wa.me/$whatsappNumber?text=$encodedMessage";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }
}