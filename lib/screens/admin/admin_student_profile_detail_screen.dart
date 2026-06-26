import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/mess_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentProfileDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isPending;
  final String? requestId; // only passed if pending

  const AdminStudentProfileDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.isPending,
    this.requestId,
  });

  @override
  State<AdminStudentProfileDetailScreen> createState() => _AdminStudentProfileDetailScreenState();
}

class _AdminStudentProfileDetailScreenState extends State<AdminStudentProfileDetailScreen> {
  bool _isLoading = true;
  String? _error;
  
  User? _student;

  DateTime? _joinDate;
  DateTime? _lastActivity;
  double _attendancePercentage = 0.0;

  bool _isActioning = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.studentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        
        setState(() {
          _student = User.fromJson(data);
          _joinDate = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null;
          _lastActivity = null; 
          _attendancePercentage = 0.0; 
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Student not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }


  Future<void> _approve() async {
    if (widget.requestId == null) return;
    setState(() => _isActioning = true);
    final messProvider = Provider.of<MessProvider>(context, listen: false);
    final success = await messProvider.approveRequest(widget.requestId!);
    setState(() => _isActioning = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved successfully!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to approve request')));
    }
  }

  Future<void> _reject() async {
    if (widget.requestId == null) return;
    setState(() => _isActioning = true);
    final messProvider = Provider.of<MessProvider>(context, listen: false);
    final success = await messProvider.rejectRequest(widget.requestId!);
    setState(() => _isActioning = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reject request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      
                      // Academic Profile
                      _buildSectionTitle('Academic Profile'),
                      const SizedBox(height: 8),
                      _buildAcademicCard(),
                      const SizedBox(height: 20),
                      


                      // Approve / Reject Actions if Pending
                      if (widget.isPending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isActioning ? null : _reject,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('REJECT REQUEST'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isActioning ? null : _approve,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isActioning
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                                    : const Text('APPROVE & REGISTER'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ]
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_student?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_student?.email ?? '', style: const TextStyle(color: AppColors.textLight)),
                  if (_student?.phone.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(_student!.phone, style: const TextStyle(color: AppColors.textLight)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Attendance: ${_attendancePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_lastActivity != null)
                        Text(
                          'Active: ${_lastActivity!.day}/${_lastActivity!.month}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow('PRN', _student?.prn.isNotEmpty == true ? _student!.prn : 'Not Provided'),
            _buildDetailRow('Roll Number', _student?.rollNumber.isNotEmpty == true ? _student!.rollNumber : 'Not Provided'),
            _buildDetailRow('Branch', _student?.branch.isNotEmpty == true ? _student!.branch : 'Not Provided'),
            _buildDetailRow('Passout Year', _student?.passoutYear.isNotEmpty == true ? _student!.passoutYear : 'Not Provided'),
            _buildDetailRow('Hostel Name', _student?.hostelName.isNotEmpty == true ? _student!.hostelName : 'Not Provided'),
            if (_joinDate != null)
              _buildDetailRow('Registration Date', '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}'),
          ],
        ),
      ),
    );
  }



  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
