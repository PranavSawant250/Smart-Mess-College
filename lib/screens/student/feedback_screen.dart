import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FeedbackScreen extends StatefulWidget {
  final MealPoll poll;
  const FeedbackScreen({super.key, required this.poll});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _foodQuality = 0;
  int _taste = 0;
  int _service = 0;
  final _commentCtrl = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_foodQuality == 0 || _taste == 0 || _service == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all three categories.')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance.collection('feedbacks').doc('${widget.poll.id}_${user.uid}').set({
        'pollId': widget.poll.id,
        'userId': user.uid,
        'foodQuality': _foodQuality,
        'taste': _taste,
        'service': _service,
        'comment': _commentCtrl.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) setState(() { _submitted = true; _isLoading = false; });
      _showSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.favorite, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Thank You!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your feedback helps us improve the mess quality!',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessAppBar(title: 'Submit Feedback'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poll info
            MessCard(
              color: AppColors.primary.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.poll.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Finalized Menu:', style: Theme.of(context).textTheme.bodyMedium),
                        if (widget.poll.finalizedVeg != null)
                          Text('🥗 ${widget.poll.finalizedVeg}', style: const TextStyle(fontSize: 13, color: AppColors.success)),
                        if (widget.poll.finalizedNonVeg != null)
                          Text('🍗 ${widget.poll.finalizedNonVeg}', style: const TextStyle(fontSize: 13, color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Rate Your Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Your honest feedback helps improve the mess.', style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 16),

            _RatingRow(
              label: 'Food Quality',
              icon: Icons.restaurant,
              rating: _foodQuality,
              onChanged: (v) => setState(() => _foodQuality = v),
            ),
            const Divider(height: 24),
            _RatingRow(
              label: 'Taste',
              icon: Icons.local_dining,
              rating: _taste,
              onChanged: (v) => setState(() => _taste = v),
            ),
            const Divider(height: 24),
            _RatingRow(
              label: 'Service',
              icon: Icons.room_service_outlined,
              rating: _service,
              onChanged: (v) => setState(() => _service = v),
            ),
            const SizedBox(height: 20),

            // Overall
            if (_foodQuality > 0 && _taste > 0 && _service > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${((_foodQuality + _taste + _service) / 3).toStringAsFixed(1)}/5',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            const Text('Comments (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts about today\'s meal...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitted || _isLoading ? null : _submit,
                icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                label: Text(_isLoading ? 'SUBMITTING...' : 'SUBMIT FEEDBACK'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingRow({
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ),
        StarRating(initialRating: rating, onRatingChanged: onChanged, size: 28),
      ],
    );
  }
}
