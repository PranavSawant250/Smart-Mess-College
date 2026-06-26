import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class StudentTransactionHistoryScreen extends StatefulWidget {
  const StudentTransactionHistoryScreen({super.key});

  @override
  State<StudentTransactionHistoryScreen> createState() => _StudentTransactionHistoryScreenState();
}

class _StudentTransactionHistoryScreenState extends State<StudentTransactionHistoryScreen> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  String _filter = 'All'; // 'All', 'This Month'

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      var query = FirebaseFirestore.instance.collection('transactions')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('paymentDate', descending: true);

      if (_filter == 'This Month') {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        query = query.where('paymentDate', isGreaterThanOrEqualTo: firstDayOfMonth);
      }
      
      final snapshot = await query.get();
      
      if (mounted) {
        setState(() {
          _transactions = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            if (data['paymentDate'] is Timestamp) {
              data['paymentDate'] = (data['paymentDate'] as Timestamp).toDate().toIso8601String();
            }
            return Transaction.fromJson(data);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fetch transactions error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProofImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Payment Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (url.startsWith('http'))
                Image.network(url, fit: BoxFit.contain)
              else
                Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 60, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(url, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Text('(Mock Image)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        icon: const Icon(Icons.filter_list, size: 16, color: AppColors.primary),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filter = val);
                            _fetchTransactions();
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Time')),
                          DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No transactions found', style: TextStyle(color: AppColors.textLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final t = _transactions[index];
                            final statusColor = t.paymentStatus == 'APPROVED' 
                                ? AppColors.success 
                                : (t.paymentStatus == 'REJECTED' ? AppColors.error : AppColors.warning);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Rs. ${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Text(t.paymentStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                                                  const SizedBox(width: 4),
                                                  Text(DateFormat('MMM dd, yyyy • hh:mm a').format(t.paymentDate), style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.payment, size: 14, color: AppColors.textLight),
                                                  const SizedBox(width: 4),
                                                  Text('Mode: ${t.paymentMode}', style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.numbers, size: 14, color: AppColors.textLight),
                                                  const SizedBox(width: 4),
                                                  Text('Txn ID: ${t.transactionId}', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (t.paymentScreenshot.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _showProofImage(t.paymentScreenshot),
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.divider),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: t.paymentScreenshot.startsWith('http')
                                                    ? Image.network(t.paymentScreenshot, fit: BoxFit.cover)
                                                    : const Center(child: Icon(Icons.image, color: Colors.grey)),
                                              ),
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
      ),
    );
  }
}
