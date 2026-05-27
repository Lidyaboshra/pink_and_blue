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
  List<Drink> filteredDrinks = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // Responsive breakpoints
  bool get _isMobileWidth => MediaQuery.of(context).size.width < 600;
  bool get _isTabletWidth => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool get _isDesktopWidth => MediaQuery.of(context).size.width >= 1200;
  
  int get _crossAxisCount {
    if (_isDesktopWidth) return 4;
    if (_isTabletWidth) return 3;
    return 2;
  }
  
  double get _childAspectRatio {
    if (_isDesktopWidth) return 1.4;
    if (_isTabletWidth) return 1.5;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _fetchDrinks();
    _searchController.addListener(_filterDrinks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        filteredDrinks = drinks;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching drinks: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load menu')),
        );
      }
    }
  }

  void _filterDrinks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredDrinks = drinks;
      } else {
        filteredDrinks = drinks.where((drink) {
          return drink.name.toLowerCase().contains(query) ||
              (drink.category?.toLowerCase().contains(query) ?? false) ||
              (drink.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _fetchDrinks,
        color: const Color(0xFFFF69B4),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading delicious drinks...",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
            : filteredDrinks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: _isMobileWidth ? 60 : 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? "No drinks available yet"
                              : "No matching drinks found",
                          style: TextStyle(
                            fontSize: _isMobileWidth ? 16 : 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          const SizedBox(height: 8),
                        if (_searchController.text.isNotEmpty)
                          Text(
                            "Try a different search term",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(_isMobileWidth ? 12 : 16),
                    child: Column(
                      children: [
                        // Search bar - visible on all screens
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        // Results count
                        _buildResultsCount(),
                        const SizedBox(height: 12),
                        // Grid view
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _crossAxisCount,
                            childAspectRatio: _childAspectRatio,
                            crossAxisSpacing: _isMobileWidth ? 12 : 16,
                            mainAxisSpacing: _isMobileWidth ? 12 : 16,
                          ),
                          itemCount: filteredDrinks.length,
                          itemBuilder: (context, index) {
                            final drink = filteredDrinks[index];
                            return _buildDrinkCard(drink, cartProvider);
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(

      backgroundColor: const Color(0xFFFF69B4),
      elevation: 0,
      centerTitle: _isMobileWidth,
     
      bottom: _isMobileWidth ? PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSearchBar(),
        ),
      ) : null,
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: _isMobileWidth ? "Search drinks..." : "Search by name, category, or description...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF69B4)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterDrinks();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: _isMobileWidth ? 12 : 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultsCount() {
    if (_searchController.text.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF69B4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 14, color: Color(0xFFFF69B4)),
          const SizedBox(width: 6),
          Text(
            "Found ${filteredDrinks.length} ${filteredDrinks.length == 1 ? 'result' : 'results'}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFF69B4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkCard(Drink drink, CartProvider cart) {
    final drinkItems = cart.items.where((item) => item.drink.id == drink.id).toList();
    final totalQuantityForDrink = drinkItems.fold(0, (sum, item) => sum + item.quantity);
    
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_isMobileWidth ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_isMobileWidth ? 16 : 20),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section - Reduced height
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_isMobileWidth ? 16 : 20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: drink.imageUrl ??
                          'https://via.placeholder.com/400x300?text=No+Image',
                      height: _isMobileWidth ? 110 : 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: _isMobileWidth ? 110 : 120,
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF69B4)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: _isMobileWidth ? 110 : 120,
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: _isMobileWidth ? 25 : 30, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                            Text(
                              "No Image",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (drink.isNew)
                    Positioned(
                      top: _isMobileWidth ? 6 : 8,
                      right: _isMobileWidth ? 6 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _isMobileWidth ? 6 : 8, 
                            vertical: _isMobileWidth ? 3 : 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF69B4), Color(0xFFFF8CC8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "NEW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isMobileWidth ? 9 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (totalQuantityForDrink > 0)
                    Positioned(
                      top: _isMobileWidth ? 6 : 8,
                      left: _isMobileWidth ? 6 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _isMobileWidth ? 6 : 8, 
                            vertical: _isMobileWidth ? 3 : 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF69B4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                        child: Text(
                          "$totalQuantityForDrink",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _isMobileWidth ? 11 : 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Details Section - More compact
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_isMobileWidth ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drink.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _isMobileWidth ? 13 : 14,
                          color: const Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Category tag
                      if (drink.category != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: _isMobileWidth ? 5 : 6, 
                              vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF69B4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            drink.category!,
                            style: TextStyle(
                              fontSize: _isMobileWidth ? 8 : 9,
                              color: const Color(0xFFFF69B4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Price Row - Compact
                      Wrap(
                        spacing: _isMobileWidth ? 4 : 6,
                        runSpacing: 4,
                        children: [
                          if (drink.priceSmall != null)
                            _buildPriceChip("S", drink.priceSmall!),
                          if (drink.priceMedium != null)
                            _buildPriceChip("M", drink.priceMedium!),
                          if (drink.priceLarge != null)
                            _buildPriceChip("L", drink.priceLarge!),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (totalQuantityForDrink > 0)
                        // Quantity Controls - Compact
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red, 
                                  size: _isMobileWidth ? 22 : 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final itemToDecrease = cart.items.lastWhere(
                                  (item) => item.drink.id == drink.id,
                                  orElse: () => cart.items.firstWhere(
                                      (item) => item.drink.id == drink.id),
                                );
                                cart.decreaseQuantity(itemToDecrease);
                              },
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                "$totalQuantityForDrink",
                                style: TextStyle(
                                    fontSize: _isMobileWidth ? 14 : 16, 
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: const Color(0xFFFF69B4),
                                  size: _isMobileWidth ? 22 : 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showSizeSelector(drink, cart),
                            ),
                          ],
                        )
                      else
                        // Add to Cart Button - Compact
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showSizeSelector(drink, cart),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF69B4),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  vertical: _isMobileWidth ? 8 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, 
                                    size: _isMobileWidth ? 14 : 16),
                                SizedBox(width: _isMobileWidth ? 4 : 6),
                                Text(
                                  "Add",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: _isMobileWidth ? 11 : 12,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(String size, num price) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: _isMobileWidth ? 6 : 8, 
          vertical: _isMobileWidth ? 2 : 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        "$size: ${price.toInt()}",
        style: TextStyle(
          fontSize: _isMobileWidth ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _showSizeSelector(Drink drink, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: _isMobileWidth ? 45 : 50,
                    height: _isMobileWidth ? 45 : 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: drink.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(drink.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[100],
                    ),
                    child: drink.imageUrl == null
                        ? Icon(Icons.local_cafe, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drink.name,
                          style: TextStyle(
                            fontSize: _isMobileWidth ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        if (drink.category != null)
                          Text(
                            drink.category!,
                            style: TextStyle(
                              fontSize: _isMobileWidth ? 12 : 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (drink.priceSmall != null)
                      _buildSizeOption(
                        size: "Small",
                        price: drink.priceSmall!,
                        onTap: () {
                          cart.addToCart(drink, "Small");
                          Navigator.pop(context);
                          _showAddedToCartSnackbar(context);
                        },
                      ),
                    if (drink.priceMedium != null)
                      _buildSizeOption(
                        size: "Medium",
                        price: drink.priceMedium!,
                        onTap: () {
                          cart.addToCart(drink, "Medium");
                          Navigator.pop(context);
                          _showAddedToCartSnackbar(context);
                        },
                      ),
                    if (drink.priceLarge != null)
                      _buildSizeOption(
                        size: "Large",
                        price: drink.priceLarge!,
                        onTap: () {
                          cart.addToCart(drink, "Large");
                          Navigator.pop(context);
                          _showAddedToCartSnackbar(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption({
    required String size,
    required num price,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: _isMobileWidth ? 16 : 20, 
            vertical: _isMobileWidth ? 12 : 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: _isMobileWidth ? 35 : 40,
                  height: _isMobileWidth ? 35 : 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    size == "Small"
                        ? Icons.coffee_outlined
                        : size == "Medium"
                            ? Icons.coffee
                            : Icons.coffee_maker_outlined,
                    color: const Color(0xFFFF69B4),
                    size: _isMobileWidth ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  size,
                  style: TextStyle(
                    fontSize: _isMobileWidth ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: _isMobileWidth ? 12 : 16, 
                  vertical: _isMobileWidth ? 6 : 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF69B4), Color(0xFFFF8CC8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${price.toInt()} EGP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _isMobileWidth ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddedToCartSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Added to cart!"),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}