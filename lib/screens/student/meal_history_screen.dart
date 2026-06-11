import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/poll_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'feedback_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchPollHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pollProvider = Provider.of<PollProvider>(context);
    final pastPolls = pollProvider.pollHistory;

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<PollProvider>(context, listen: false).fetchPollHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Finalized Menus'),
          const SizedBox(height: 4),
          const Text('View past meal decisions and kitchen orders.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 16),
          if (pollProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (pastPolls.isEmpty)
            const EmptyState(message: 'No past meals yet.', icon: Icons.history)
          else
            ...pastPolls.map((poll) => _HistoryCard(
              poll: poll,
              onRefresh: () async {
                await Provider.of<PollProvider>(context, listen: false).fetchPollHistory();
              },
            )),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final MealPoll poll;
  final VoidCallback onRefresh;
  const _HistoryCard({required this.poll, required this.onRefresh});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _canGiveFeedback = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkFeedbackStatus();
  }

  Future<void> _checkFeedbackStatus() async {
    try {
      final response = await ApiService.get(ApiConfig.feedbackStatus(widget.poll.id));
      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _canGiveFeedback = !response['hasSubmitted'] && response['windowOpen'];
          });
        }
      }
    } catch (e) {
      print('Check feedback status error: $e');
    }
    if (mounted) {
      setState(() { _isLoadingStatus = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.poll.date);
    final total = widget.poll.totalVeg + widget.poll.totalNonVeg + widget.poll.totalFast;
    
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
                    Text(widget.poll.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    Text('$dateStr • $total participants',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Finalized', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (widget.poll.finalizedVeg != null)
            _MenuLine(type: 'Veg', menu: widget.poll.finalizedVeg!, count: widget.poll.totalVeg, color: AppColors.success, icon: Icons.eco),
          if (widget.poll.finalizedNonVeg != null)
            _MenuLine(type: 'Non-Veg', menu: widget.poll.finalizedNonVeg!, count: widget.poll.totalNonVeg, color: AppColors.error, icon: Icons.set_meal),
          if (widget.poll.finalizedFast != null)
            _MenuLine(type: 'Fast', menu: widget.poll.finalizedFast!, count: widget.poll.totalFast, color: AppColors.warning, icon: Icons.spa),
            
          if (_isLoadingStatus)
             const Padding(
               padding: EdgeInsets.only(top: 16.0),
               child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
             )
          else if (_canGiveFeedback) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => FeedbackScreen(poll: widget.poll))
                  ).then((_) {
                    _checkFeedbackStatus();
                    widget.onRefresh();
                  });
                },
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: const Text('Give Feedback'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  final String type;
  final String menu;
  final int count;
  final Color color;
  final IconData icon;

  const _MenuLine({required this.type, required this.menu, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text('$type: ', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(menu, style: const TextStyle(fontSize: 13))),
          Text('$count pax', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
