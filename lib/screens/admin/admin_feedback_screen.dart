import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<MealFeedback> _feedbacks = [];
  bool _isLoading = true;

  double _avgFoodQuality = 0;
  double _avgTaste = 0;
  double _avgService = 0;
  double _avgOverall = 0;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final messId = userDoc.data()?['messId'];

        if (messId != null && messId.toString().isNotEmpty) {
          final pollsSnapshot = await FirebaseFirestore.instance.collection('polls').where('messId', isEqualTo: messId).get();
          final pollIds = pollsSnapshot.docs.map((e) => e.id).toList();

          if (pollIds.isNotEmpty) {
            final feedbackRes = await FirebaseFirestore.instance.collection('feedbacks').get();
            
            final filteredDocs = feedbackRes.docs.where((doc) {
              final pid = doc.data()['pollId'] as String?;
              return pid != null && pollIds.contains(pid);
            }).toList();

            double totalFood = 0;
            double totalTaste = 0;
            double totalService = 0;
            List<MealFeedback> list = [];

            for (var doc in filteredDocs) {
              final data = doc.data();
              data['id'] = doc.id;
              
              if (data['submittedAt'] is Timestamp) {
                data['submittedAt'] = (data['submittedAt'] as Timestamp).toDate().toIso8601String();
              }

              final sUser = await FirebaseFirestore.instance.collection('users').doc(data['userId']).get();
              data['userName'] = sUser.data()?['name'] ?? 'Unknown';

              final fb = MealFeedback.fromJson(data);
              list.add(fb);

              totalFood += fb.foodQuality;
              totalTaste += fb.taste;
              totalService += fb.service;
            }

            if (list.isNotEmpty) {
              _avgFoodQuality = totalFood / list.length;
              _avgTaste = totalTaste / list.length;
              _avgService = totalService / list.length;
              _avgOverall = (_avgFoodQuality + _avgTaste + _avgService) / 3;
            }

            list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
            _feedbacks = list;
          }
        }
      }
    } catch (e) {
      print('Fetch feedback error: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchFeedbacks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Student Feedback'),
          const SizedBox(height: 16),
          
          if (_isLoading)
             const Center(child: CircularProgressIndicator())
          else ...[
            if (_feedbacks.isNotEmpty) ...[
              // Summary card
              MessCard(
                color: AppColors.primary.withOpacity(0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Feedback Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RatingSummary(label: 'Food Quality', rating: _avgFoodQuality),
                        _RatingSummary(label: 'Taste', rating: _avgTaste),
                        _RatingSummary(label: 'Service', rating: _avgService),
                        _RatingSummary(label: 'Overall', rating: _avgOverall, isHighlight: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Based on ${_feedbacks.length} review${_feedbacks.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Improve menu suggestion
              MessCard(
                color: AppColors.success.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Improvement Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _avgTaste < 4 ? '⚠️ Taste rating is below 4. Consider improving recipes or seasoning.' :
                            _avgService < 4 ? '⚠️ Service needs improvement. Check serving timings.' :
                            '✅ Excellent feedback! Keep up the great work!',
                            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_feedbacks.isEmpty)
              const EmptyState(message: 'No feedback received yet.', icon: Icons.feedback_outlined)
            else ...[
              const SectionHeader(title: 'All Reviews'),
              const SizedBox(height: 12),
              ..._feedbacks.map((f) => _FeedbackCard(feedback: f)),
            ],
          ],
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final String label;
  final double rating;
  final bool isHighlight;

  const _RatingSummary({required this.label, required this.rating, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    final color = isHighlight ? AppColors.primary : AppColors.accent;
    return Column(
      children: [
        Text(rating.toStringAsFixed(1),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Icon(Icons.star, size: 14, color: color),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight), textAlign: TextAlign.center),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final MealFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('d MMM, h:mm a').format(feedback.submittedAt);

    return MessCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(feedback.userName.isNotEmpty ? feedback.userName.substring(0, 1) : 'U',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 16),
                  Text(feedback.averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniRating(label: 'Quality', rating: feedback.foodQuality),
              const SizedBox(width: 12),
              _MiniRating(label: 'Taste', rating: feedback.taste),
              const SizedBox(width: 12),
              _MiniRating(label: 'Service', rating: feedback.service),
            ],
          ),
          if (feedback.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(child: Text(feedback.comment, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRating extends StatelessWidget {
  final String label;
  final int rating;
  const _MiniRating({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star : Icons.star_border,
            size: 10,
            color: AppColors.accent,
          )),
        ),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
      ],
    );
  }
}
