import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/whatsapp_helper.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "Your Cart",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text("Your cart is empty 🍵", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      double price = item.size == 'Small'
                          ? (item.drink.priceSmall ?? 0)
                          : item.size == 'Medium'
                              ? (item.drink.priceMedium ?? 0)
                              : (item.drink.priceLarge ?? 0);

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.coffee, color: Color(0xFFFF69B4)),
                          title: Text(item.drink.name),
                          subtitle: Text("${item.size} ×${item.quantity}"),
                          trailing: Text("${price} EGP"),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty) ...[
            const Divider(),
            Text("Total: ${cart.total.toStringAsFixed(2)} EGP",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => WhatsAppHelper.sendOrder(context, cart),
                child: const Text(
                  "SEND ORDER VIA WHATSAPP",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}