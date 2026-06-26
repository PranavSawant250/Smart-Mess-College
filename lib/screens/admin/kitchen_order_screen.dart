import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class KitchenOrderScreen extends StatefulWidget {
  const KitchenOrderScreen({super.key});

  @override
  State<KitchenOrderScreen> createState() => _KitchenOrderScreenState();
}

class _KitchenOrderScreenState extends State<KitchenOrderScreen> {
  List<KitchenOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final messId = userDoc.data()?['messId'];

        if (messId != null && messId.toString().isNotEmpty) {
          final snapshot = await FirebaseFirestore.instance.collection('kitchen_orders')
              .where('messId', isEqualTo: messId)
              .orderBy('sentAt', descending: true)
              .get();

          if (mounted) {
            setState(() {
              _orders = snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                if (data['date'] is Timestamp) data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
                if (data['sentAt'] is Timestamp) data['sentAt'] = (data['sentAt'] as Timestamp).toDate().toIso8601String();
                return KitchenOrder.fromJson(data);
              }).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Fetch kitchen orders error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Kitchen Orders'),
          const SizedBox(height: 4),
          const Text('Finalized meal counts sent to the kitchen.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_orders.isEmpty)
            const EmptyState(message: 'No kitchen orders yet.\nFinalize a poll to send orders.', icon: Icons.kitchen_outlined)
          else
            ..._orders.map((order) => _KitchenOrderCard(order: order)),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final KitchenOrder order;
  const _KitchenOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(order.date);
    final sentStr = DateFormat('h:mm a').format(order.sentAt);
    final total = order.vegCount + order.nonVegCount + order.fastCount;

    return MessCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.kitchen, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order.mealTime} Order', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    Text('$dateStr • Sent at $sentStr',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total Total',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const Divider(height: 20),

          // Menu + count
          _OrderRow(
            label: 'Veg', menu: order.finalVegMenu,
            count: order.vegCount, color: AppColors.success, icon: Icons.eco,
          ),
          const SizedBox(height: 8),
          _OrderRow(
            label: 'Non-Veg', menu: order.finalNonVegMenu,
            count: order.nonVegCount, color: AppColors.error, icon: Icons.set_meal,
          ),
          const SizedBox(height: 8),
          _OrderRow(
            label: 'Fast', menu: order.finalFastMenu,
            count: order.fastCount, color: AppColors.warning, icon: Icons.spa,
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Meals to Prepare', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$total servings',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String menu;
  final int count;
  final Color color;
  final IconData icon;

  const _OrderRow({required this.label, required this.menu, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        SizedBox(width: 60, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(child: Text(menu, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }
}
