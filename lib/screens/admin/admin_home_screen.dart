import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/poll_provider.dart';
import '../../providers/mess_provider.dart';
import 'create_poll_screen.dart';
import 'poll_analysis_screen.dart';
import 'kitchen_order_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_profile_screen.dart';
import '../notifications_screen.dart';
import '../../providers/notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _AdminDashboard(onRefresh: () => setState(() {})),
      PollAnalysisScreen(onRefresh: () => setState(() {})),
      const KitchenOrderScreen(),
      const AdminFeedbackScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchAdminPolls(status: 'active');
      Provider.of<MessProvider>(context, listen: false).fetchStudents();
      _fetchNotifs();
    });
  }

  void _fetchNotifs() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final previousCount = provider.unreadCount;
    await provider.fetchNotifications();
    if (provider.unreadCount > previousCount && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 You have new notifications!'), backgroundColor: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN PANEL'),
        actions: [
          // Removed Notifications icon
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppColors.primary), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary), label: 'Analysis'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen, color: AppColors.primary), label: 'Kitchen'),
          NavigationDestination(icon: Icon(Icons.feedback_outlined), selectedIcon: Icon(Icons.feedback, color: AppColors.primary), label: 'Feedback'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  final VoidCallback onRefresh;
  const _AdminDashboard({required this.onRefresh});

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  int _totalVotes = 0;
  double _avgRating = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final messId = userDoc.data()?['messId'];
        
        if (messId != null && messId.toString().isNotEmpty) {
          final feedbackRes = await FirebaseFirestore.instance.collection('feedbacks').get(); // Assuming we get all for now, to be optimized
          if (feedbackRes.docs.isNotEmpty) {
            double total = 0;
            for (var doc in feedbackRes.docs) {
              final d = doc.data();
              total += ((d['foodQuality'] ?? 0) + (d['taste'] ?? 0) + (d['service'] ?? 0)) / 3;
            }
            _avgRating = total / feedbackRes.docs.length;
          }
        }
      }
    } catch (e) {
      print('Fetch stats error: $e');
    }
    if (mounted) setState(() => _isLoadingStats = false);
  }

  Future<void> _refresh() async {
    await Provider.of<PollProvider>(context, listen: false).fetchAdminPolls(status: 'active');
    await Provider.of<MessProvider>(context, listen: false).fetchStudents();
    await _fetchStats();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final pollProvider = Provider.of<PollProvider>(context);
    final messProvider = Provider.of<MessProvider>(context);
    
    final activePolls = pollProvider.adminPolls.where((p) => p.isActive).toList();
    final totalStudents = messProvider.students.length;
    
    _totalVotes = activePolls.fold(0, (sum, p) => sum + p.totalVeg + p.totalNonVeg + p.totalFast);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _StatCard(icon: Icons.poll, label: 'Active Polls', value: '${activePolls.length}', color: AppColors.primary),
              _StatCard(icon: Icons.people, label: 'Students', value: '$totalStudents', color: AppColors.success),
              _StatCard(icon: Icons.how_to_vote, label: 'Total Votes (Active)', value: '$_totalVotes', color: AppColors.warning),
              _StatCard(icon: Icons.star, label: 'Avg Rating', value: _isLoadingStats ? '-' : _avgRating.toStringAsFixed(1), color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 20),

          // Active polls management
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Active Polls')),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Poll'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreatePollScreen()))
                    .then((_) => _refresh()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pollProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (activePolls.isEmpty)
            const MessCard(child: EmptyState(message: 'No active polls. Create one!', icon: Icons.add_circle_outline))
          else
            ...activePolls.map((poll) => _AdminPollCard(poll: poll, onFinalize: _refresh)),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Management'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRequestsScreen())).then((_) => _refresh()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Students & Requests', style: Theme.of(context).textTheme.titleLarge),
                        const Text('Manage active students and new join requests', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }
}

class _AdminPollCard extends StatelessWidget {
  final MealPoll poll;
  final VoidCallback onFinalize;
  const _AdminPollCard({required this.poll, required this.onFinalize});

  @override
  Widget build(BuildContext context) {
    final total = poll.totalVeg + poll.totalNonVeg + poll.totalFast;
    return MessCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    Text('${poll.mealTime} • $total votes',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: total == 0 ? null : () {
                  _confirmFinalize(context);
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Finalize', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CountChip(count: poll.totalVeg, label: 'Veg', color: AppColors.success, icon: Icons.eco),
              const SizedBox(width: 8),
              CountChip(count: poll.totalNonVeg, label: 'Non-Veg', color: AppColors.error, icon: Icons.set_meal),
              const SizedBox(width: 8),
              CountChip(count: poll.totalFast, label: 'Fast', color: AppColors.warning, icon: Icons.spa),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmFinalize(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize Poll?'),
        content: const Text('This will finalize the menu based on majority votes and send the order to the kitchen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final pollProvider = Provider.of<PollProvider>(context, listen: false);
              final success = await pollProvider.finalizePoll(poll.id);
              if (success) {
                onFinalize();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Poll finalized! Kitchen order sent.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to finalize poll.')),
                  );
                }
              }
            },
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }
}
