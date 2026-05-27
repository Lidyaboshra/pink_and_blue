import 'package:flutter/material.dart';
import '../models/drink.dart';

class CartItem {
  final Drink drink;
  final String size;
  int quantity;

  CartItem({
    required this.drink,
    required this.size,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(Drink drink, String size) {
    // Check if same drink + same size already exists
    final existingItem = _items.firstWhere(
      (item) => item.drink.id == drink.id && item.size == size,
      orElse: () => CartItem(drink: drink, size: size, quantity: 0),
    );

    if (existingItem.quantity > 0) {
      existingItem.quantity++;
    } else {
      _items.add(CartItem(drink: drink, size: size));
    }
    notifyListeners();
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  double get total {
    return _items.fold(0, (sum, item) {
      double price = 0;
      if (item.size == 'Small') price = item.drink.priceSmall ?? 0;
      else if (item.size == 'Medium') price = item.drink.priceMedium ?? 0;
      else price = item.drink.priceLarge ?? 0;
      return sum + (price * item.quantity);
    });
  }

  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}