import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Drink> drinks = [];
  bool isLoading = true;

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
      print('Error fetching drinks: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load menu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return RefreshIndicator(
      onRefresh: _fetchDrinks,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : drinks.isEmpty
              ? const Center(child: Text("No drinks available yet"))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: drinks.length,
                  itemBuilder: (context, index) {
                    final drink = drinks[index];
                    return _buildDrinkCard(drink, cartProvider);
                  },
                ),
    );
  }

  Widget _buildDrinkCard(Drink drink, CartProvider cart) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: drink.imageUrl ?? 'https://via.placeholder.com/400x300?text=No+Image',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: Colors.grey[200],
                    child: const Icon(Icons.coffee, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              if (drink.isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "NEW",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drink.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (drink.priceSmall != null) Text("S: ${drink.priceSmall} ", style: const TextStyle(fontSize: 14)),
                    if (drink.priceMedium != null) Text("M: ${drink.priceMedium} ", style: const TextStyle(fontSize: 14)),
                    if (drink.priceLarge != null) Text("L: ${drink.priceLarge}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showSizeSelector(drink, cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Add to Cart", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSizeSelector(Drink drink, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Choose Size - ${drink.name}", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (drink.priceSmall != null)
              ListTile(
                title: const Text("Small"),
                trailing: Text("${drink.priceSmall} EGP"),
                onTap: () {
                  cart.addToCart(drink, "Small");
                  Navigator.pop(context);
                },
              ),
            if (drink.priceMedium != null)
              ListTile(
                title: const Text("Medium"),
                trailing: Text("${drink.priceMedium} EGP"),
                onTap: () {
                  cart.addToCart(drink, "Medium");
                  Navigator.pop(context);
                },
              ),
            if (drink.priceLarge != null)
              ListTile(
                title: const Text("Large"),
                trailing: Text("${drink.priceLarge} EGP"),
                onTap: () {
                  cart.addToCart(drink, "Large");
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}