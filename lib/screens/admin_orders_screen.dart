import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> orders = [];
  bool isLoading = true;
  String selectedFilter = "All"; // All, Pending, Received

  final List<String> filters = ["All", "Pending", "Received"];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      var query = Supabase.instance.client.from('orders').select().order('created_at', ascending: false);

      // if (selectedFilter == "Pending") {
      //   query = query?.eq('status', 'pending');
      // } else if (selectedFilter == "Received") {
      //   query = query.eq('status', 'received');
      // }

      final response = await query;
      setState(() {
        orders = (response as List).map((e) => Order.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await Supabase.instance.client.from('orders').update({'status': newStatus}).eq('id', orderId);
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Orders"),
        backgroundColor: const Color(0xFFFF69B4),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: filters.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedFilter = filter);
                      _fetchOrders();
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFFFF69B4),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text("No orders found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final isPending = order.status == 'pending';

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM yyyy • hh:mm').format(order.createdAt)),
                                      Text("${order.total.toStringAsFixed(2)} EGP",
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("📍 ${order.location ?? 'No location'}"),
                                  const Divider(),
                                  ...order.items.map((item) => Text(
                                        "• ${item['name']} (${item['size']}) x${item['quantity']}",
                                      )),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isPending
                                              ? () => _updateStatus(order.id, 'received')
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isPending ? Colors.green : Colors.grey,
                                          ),
                                          child: Text(isPending ? "Mark as Received" : "Received"),
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
        ],
      ),
    );
  }
}