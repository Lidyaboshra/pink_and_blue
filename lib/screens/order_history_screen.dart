import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        orders = (response as List).map((e) => Order.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      _fetchOrders(); // Refresh list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order marked as $newStatus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
  }

  Future<void> _reorder(Order order) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reorder feature coming soon")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: const Color(0xFFFF69B4),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text("No orders yet", style: TextStyle(fontSize: 18)))
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isPending = order.status == 'pending';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "${order.total.toStringAsFixed(2)} EGP",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF69B4)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Status
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPending ? Colors.orange[100] : Colors.green[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isPending ? Colors.orange[800] : Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 20),
                              
                              // Order Items
                              ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Text(
                                      "• ${item['name']} (${item['size']}) ×${item['quantity']}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  )),

                              if (order.location != null) ...[
                                const SizedBox(height: 8),
                                Text("📍 ${order.location}", style: const TextStyle(color: Colors.grey)),
                              ],

                              const SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                children: [
                                  // Reorder Button (for all users)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.replay),
                                      label: const Text("Reorder"),
                                      onPressed: () => _reorder(order),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Admin Only: Mark as Received
                                  if (isAdmin)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text("Mark Received"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPending ? const Color(0xFFFF69B4) : Colors.grey,
                                        ),
                                        onPressed: isPending
                                            ? () => _updateOrderStatus(order.id, 'received')
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}