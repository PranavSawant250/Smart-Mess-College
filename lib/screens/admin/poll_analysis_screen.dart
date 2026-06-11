import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/poll_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class PollAnalysisScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const PollAnalysisScreen({super.key, required this.onRefresh});

  @override
  State<PollAnalysisScreen> createState() => _PollAnalysisScreenState();
}

class _PollAnalysisScreenState extends State<PollAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchAdminPolls();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<PollProvider>(context, listen: false).fetchAdminPolls();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final pollProvider = Provider.of<PollProvider>(context);
    final polls = pollProvider.adminPolls;
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Poll & Attendance Analysis'),
          const SizedBox(height: 4),
          const Text('Track voting and attendance data for each meal.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 16),
          if (pollProvider.isLoading)
             const Center(child: CircularProgressIndicator())
          else if (polls.isEmpty)
            const EmptyState(message: 'No polls yet.', icon: Icons.bar_chart)
          else
            ...polls.map((poll) => _PollAnalysisCard(poll: poll, onRefresh: _refresh)),
        ],
      ),
    );
  }
}

class _PollAnalysisCard extends StatelessWidget {
  final MealPoll poll;
  final VoidCallback onRefresh;
  const _PollAnalysisCard({required this.poll, required this.onRefresh});

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
                child: Text(poll.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: poll.isActive ? AppColors.success.withOpacity(0.1) : AppColors.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  poll.isFinalized ? 'Finalized' : poll.isActive ? 'Active' : 'Closed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: poll.isFinalized ? AppColors.textLight : poll.isActive ? AppColors.success : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${poll.mealTime} • Total: $total participants',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          
          // Attendance Mini-Stats
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 4),
                    Text('Present: $total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.cancel, color: AppColors.error, size: 16),
                    const SizedBox(width: 4),
                    Text('Absent: ${poll.totalNotComing}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Vote bars
          _VoteBar(label: 'Veg', count: poll.totalVeg, total: total, color: AppColors.success, icon: Icons.eco),
          const SizedBox(height: 8),
          _VoteBar(label: 'Non-Veg', count: poll.totalNonVeg, total: total, color: AppColors.error, icon: Icons.set_meal),
          const SizedBox(height: 8),
          _VoteBar(label: 'Fast', count: poll.totalFast, total: total, color: AppColors.warning, icon: Icons.spa),

          const SizedBox(height: 14),

          // Top options
          ...['veg', 'nonVeg', 'fast'].map((type) {
            List<MealOption> options;
            Color color;
            if (type == 'veg') { options = List.from(poll.vegOptions); color = AppColors.success; }
            else if (type == 'nonVeg') { options = List.from(poll.nonVegOptions); color = AppColors.error; }
            else { options = List.from(poll.fastOptions); color = AppColors.warning; }

            if (options.isEmpty) return const SizedBox.shrink();
            options.sort((a, b) => b.votes.compareTo(a.votes));
            final top = options.first;
            if (top.votes == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text('Top ${type == 'veg' ? 'Veg' : type == 'nonVeg' ? 'Non-Veg' : 'Fast'}: ',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                  Text(top.name, style: const TextStyle(fontSize: 12)),
                  Text(' (${top.votes} votes)', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            );
          }),

          if (poll.isActive && total > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pollProvider = Provider.of<PollProvider>(context, listen: false);
                  final success = await pollProvider.finalizePoll(poll.id);
                  if (success) {
                    onRefresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Poll finalized! Kitchen order sent.'), backgroundColor: AppColors.success),
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
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Finalize & Send to Kitchen'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _VoteBar({required this.label, required this.count, required this.total, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
