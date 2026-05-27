import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Drink>> getDrinks() async {
    final response = await supabase
        .from('drinks')
        .select('*, categories(name)')
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Drink.fromJson(e)).toList();
  }

  Future<void> addDrink(Drink drink) async {
    await supabase.from('drinks').insert({
      'name': drink.name,
      'category_id': 1, // You can make category selection
      'description': drink.description,
      'image_url': drink.imageUrl,
      'price_small': drink.priceSmall,
      'price_medium': drink.priceMedium,
      'price_large': drink.priceLarge,
      'is_new': drink.isNew,
    });
  }

  // Add update and delete methods similarly
}