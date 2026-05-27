import 'package:flutter/material.dart';
import 'package:pink_and_blue/models/drink.dart';

class CartItem {
  final Drink drink;
  final String size;
  final int quantity;

  CartItem({required this.drink, required this.size, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  void addToCart(Drink drink, String size) {
    _items.add(CartItem(drink: drink, size: size));
    notifyListeners();
  }

  double get total {
    return _items.fold(0, (sum, item) {
      double price = 0;
      if (item.size == 'Small') price = item.drink.priceSmall ?? 0;
      else if (item.size == 'Medium') price = item.drink.priceMedium ?? 0;
      else price = item.drink.priceLarge ?? 0;
      return sum + price * item.quantity;
    });
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}