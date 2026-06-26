import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/poll_provider.dart';

class VoteScreen extends StatefulWidget {
  final MealPoll poll;
  const VoteScreen({super.key, required this.poll});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> with SingleTickerProviderStateMixin {
  String _selectedMealType = '';
  List<String> _selectedOptionIds = [];
  late TabController _tabCtrl;
  bool _submitted = false;
  bool _isEating = true;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Veg', 'key': 'veg', 'icon': Icons.eco, 'color': AppColors.success},
    {'label': 'Non-Veg', 'key': 'nonVeg', 'icon': Icons.set_meal, 'color': AppColors.error},
    {'label': 'Fast', 'key': 'fast', 'icon': Icons.spa, 'color': AppColors.warning},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        if (_isEating) {
          _selectedMealType = _tabs[_tabCtrl.index]['key'];
          _selectedOptionIds = [];
        }
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<MealOption> _optionsForTab(int index) {
    switch (index) {
      case 0: return widget.poll.vegOptions;
      case 1: return widget.poll.nonVegOptions;
      case 2: return widget.poll.fastOptions;
      default: return [];
    }
  }

  Future<void> _submitVote() async {
    if (_isEating && _selectedOptionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food option before voting.')),
      );
      return;
    }
    
    final pollProvider = Provider.of<PollProvider>(context, listen: false);
    bool success = false;
    
    if (_isEating) {
      final mealType = _tabs[_tabCtrl.index]['key'] as String;
      success = await pollProvider.castVote(widget.poll.id, mealType, _selectedOptionIds, true);
    } else {
      success = await pollProvider.castVote(widget.poll.id, 'skip', [], false);
    }
    
    if (success && mounted) {
      setState(() => _submitted = true);
      _showSuccess();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cast vote. Please try again.')),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Vote Submitted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your vote has been recorded successfully.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MessAppBar(title: 'Vote for Meal'),
      body: Column(
        children: [
          // Poll info banner
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.poll.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${widget.poll.mealTime} • Choose your meal type and food option',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          // Attendance Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Will you be having this meal?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('YES')),
                    ButtonSegment(value: false, label: Text('NO')),
                  ],
                  selected: {_isEating},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isEating = newSelection.first;
                      if (!_isEating) {
                        _selectedOptionIds = [];
                        _selectedMealType = '';
                      } else {
                        _selectedMealType = _tabs[_tabCtrl.index]['key'];
                      }
                    });
                  },
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),

          // Step 1: Choose meal type
          IgnorePointer(
            ignoring: !_isEating,
            child: Opacity(
              opacity: _isEating ? 1.0 : 0.4,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: _tabs.map((t) => Tab(
                  icon: Icon(t['icon'] as IconData, size: 20),
                  text: t['label'] as String,
                )).toList(),
              ),
            ),
          ),

          Expanded(
            child: IgnorePointer(
              ignoring: !_isEating,
              child: Opacity(
                opacity: _isEating ? 1.0 : 0.4,
                child: TabBarView(
              controller: _tabCtrl,
              children: List.generate(3, (tabIndex) {
                final options = _optionsForTab(tabIndex);
                final tabKey = _tabs[tabIndex]['key'] as String;
                final color = _tabs[tabIndex]['color'] as Color;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Choose your food preferences (Multi-select):',
                        style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    ...options.map((opt) => _OptionCard(
                          option: opt,
                          isSelected: _selectedOptionIds.contains(opt.id) && _selectedMealType == tabKey,
                          color: color,
                          onTap: () => setState(() {
                            _selectedMealType = tabKey;
                            if (_selectedOptionIds.contains(opt.id)) {
                              _selectedOptionIds.remove(opt.id);
                            } else {
                              _selectedOptionIds.add(opt.id);
                            }
                          }),
                        )),
                    if (options.isEmpty)
                      const EmptyState(message: 'No options available for this meal type.'),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEating && _selectedOptionIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text('Selected: ${_tabs[_tabCtrl.index]['label']} meal',
                          style: const TextStyle(color: AppColors.success, fontSize: 13)),
                    ],
                  ),
                ),
              if (!_isEating)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error, size: 16),
                      SizedBox(width: 6),
                      Text('Selected: Not having this meal',
                          style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitted ? null : _submitVote,
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('SUBMIT VOTE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final MealOption option;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? color : AppColors.divider, width: 2),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isSelected ? color : AppColors.textDark,
                          )),
                      if (option.description.isNotEmpty)
                        Text(option.description,
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: color),
                    Text('${option.votes}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
