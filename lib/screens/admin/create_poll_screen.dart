import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/poll_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String _mealTime = 'Lunch';
  bool _isLoading = false;

  final List<TextEditingController> _vegCtrls = [TextEditingController(text: 'Dal Tadka + Rice')];
  final List<TextEditingController> _nonVegCtrls = [TextEditingController(text: 'Chicken Curry + Rice')];
  final List<TextEditingController> _fastCtrls = [TextEditingController(text: 'Sabudana Khichdi')];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = "Today's ${_mealTime} Poll";
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in [..._vegCtrls, ..._nonVegCtrls, ..._fastCtrls]) c.dispose();
    super.dispose();
  }

  void _addOption(List<TextEditingController> list) {
    setState(() => list.add(TextEditingController()));
  }

  void _removeOption(List<TextEditingController> list, int index) {
    if (list.length <= 1) return;
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    int id = 0;
    List<MealOption> makeOptions(List<TextEditingController> ctrls, String prefix) {
      return ctrls
          .where((c) => c.text.isNotEmpty)
          .map((c) => MealOption(id: '$prefix${++id}', name: c.text.trim()))
          .toList();
    }

    final pollProvider = Provider.of<PollProvider>(context, listen: false);
    final success = await pollProvider.createPoll(
      title: _titleCtrl.text.trim(),
      mealTime: _mealTime,
      vegOptions: makeOptions(_vegCtrls, 'nv_'),
      nonVegOptions: makeOptions(_nonVegCtrls, 'nnv_'),
      fastOptions: makeOptions(_fastCtrls, 'nf_'),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Poll created successfully!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create poll.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessAppBar(title: 'Create Meal Poll'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'Poll Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Poll Title',
                prefixIcon: Icon(Icons.title, color: AppColors.primary),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealTime,
              decoration: const InputDecoration(
                labelText: 'Meal Time',
                prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
              ),
              items: ['Breakfast', 'Lunch', 'Dinner']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() {
                _mealTime = v!;
                _titleCtrl.text = "Today's $_mealTime Poll";
              }),
            ),
            const SizedBox(height: 20),

            _OptionsSection(
              title: 'Veg Options',
              color: AppColors.success,
              icon: Icons.eco,
              controllers: _vegCtrls,
              onAdd: () => _addOption(_vegCtrls),
              onRemove: (i) => _removeOption(_vegCtrls, i),
            ),
            const SizedBox(height: 16),

            _OptionsSection(
              title: 'Non-Veg Options',
              color: AppColors.error,
              icon: Icons.set_meal,
              controllers: _nonVegCtrls,
              onAdd: () => _addOption(_nonVegCtrls),
              onRemove: (i) => _removeOption(_nonVegCtrls, i),
            ),
            const SizedBox(height: 16),

            _OptionsSection(
              title: 'Fast Options',
              color: AppColors.warning,
              icon: Icons.spa,
              controllers: _fastCtrls,
              onAdd: () => _addOption(_fastCtrls),
              onRemove: (i) => _removeOption(_fastCtrls, i),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _create,
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.publish),
              label: Text(_isLoading ? 'PUBLISHING...' : 'PUBLISH POLL'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _OptionsSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              const Spacer(),
              TextButton.icon(
                icon: Icon(Icons.add, size: 16, color: color),
                label: Text('Add', style: TextStyle(color: color, fontSize: 13)),
                onPressed: onAdd,
              ),
            ],
          ),
          ...List.generate(controllers.length, (i) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      hintText: 'Option ${i + 1}',
                      prefixIcon: Icon(Icons.fiber_manual_record, size: 10, color: color),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (v) => i == 0 && (v == null || v.isEmpty) ? 'At least one option required' : null,
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: color),
                    onPressed: () => onRemove(i),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
