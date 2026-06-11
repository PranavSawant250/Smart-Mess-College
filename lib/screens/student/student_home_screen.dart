import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poll_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'vote_screen.dart';
import 'meal_history_screen.dart';
import 'student_profile_screen.dart';
import '../notifications_screen.dart';
import '../../providers/notification_provider.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchActivePolls();
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
    final user = Provider.of<AuthProvider>(context).currentUser;

    final pages = [
      _HomeTab(onRefresh: () async {
        await Provider.of<PollProvider>(context, listen: false).fetchActivePolls();
      }),
      const MealHistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMART MESS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                            .then((_) => _fetchNotifs());
                      },
                    ),
                    if (provider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text('${provider.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen()));
              },
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  user?.name != null && user!.name.isNotEmpty
                      ? user.name.substring(0, 1)
                      : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final pollProvider = Provider.of<PollProvider>(context);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          MessCard(
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${user.name.split(' ').first}! 👋',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (user.messId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Text('Current Mess: ${user.messId}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      const Text('Vote for your meal and share feedback!',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.restaurant, size: 48, color: Colors.white30),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Polls
          const SectionHeader(title: 'Active Meal Polls'),
          const SizedBox(height: 12),
          if (pollProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (pollProvider.activePolls.isEmpty)
            const MessCard(child: EmptyState(message: 'No active polls right now.\nCheck back later!', icon: Icons.poll_outlined))
          else
            ...pollProvider.activePolls.map((poll) => _PollCard(poll: poll, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VoteScreen(poll: poll)))
                  .then((_) => onRefresh());
            })),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PollCard extends StatefulWidget {
  final MealPoll poll;
  final VoidCallback onTap;
  const _PollCard({required this.poll, required this.onTap});

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  bool _hasVoted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVoteStatus();
  }

  Future<void> _checkVoteStatus() async {
    try {
      final response = await ApiService.get('${ApiConfig.myVote}?pollId=${widget.poll.id}');
      if (response['success'] == true && response['vote'] != null) {
        if (mounted) setState(() { _hasVoted = true; });
      }
    } catch (e) {
      print('Check vote status error: $e');
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.poll.totalVeg + widget.poll.totalNonVeg + widget.poll.totalFast;

    return MessCard(
      onTap: _hasVoted ? null : widget.onTap,
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
                    Text(widget.poll.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(widget.poll.mealTime, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 12),
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text('$total votes', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else if (_hasVoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Voted', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  child: const Text('Vote Now', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CountChip(count: widget.poll.totalVeg, label: 'Veg', color: AppColors.success, icon: Icons.eco),
              const SizedBox(width: 8),
              CountChip(count: widget.poll.totalNonVeg, label: 'Non-Veg', color: AppColors.error, icon: Icons.set_meal),
              const SizedBox(width: 8),
              CountChip(count: widget.poll.totalFast, label: 'Fast', color: AppColors.warning, icon: Icons.spa),
            ],
          ),
        ],
      ),
    );
  }
}
