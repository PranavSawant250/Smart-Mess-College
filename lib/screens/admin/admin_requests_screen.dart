import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/mess_provider.dart';
import '../../models/models.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messProvider = Provider.of<MessProvider>(context, listen: false);
      messProvider.fetchAdminRequests();
      messProvider.fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = Provider.of<MessProvider>(context);
    
    final pendingRequests = messProvider.adminRequests
        .where((req) => req.status == 'pending')
        .toList();
    final activeStudents = messProvider.students;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Students & Requests'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Active Students'),
            ],
          ),
        ),
        body: messProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRequestsTab(pendingRequests, messProvider),
                  _buildStudentsTab(activeStudents, messProvider),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestsTab(List<JoinRequest> requests, MessProvider provider) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('No pending requests.', style: TextStyle(color: AppColors.textLight)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Email: ${req.userEmail}', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                if (req.userPhone.isNotEmpty)
                  Text('Phone: ${req.userPhone}', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final success = await provider.rejectRequest(req.id);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await provider.approveRequest(req.id);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student approved!')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab(List<User> students, MessProvider provider) {
    if (students.isEmpty) {
      return const Center(
        child: Text('No active students yet.', style: TextStyle(color: AppColors.textLight)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return ListTile(
          leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(s.email),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
            onPressed: () => _confirmRemove(s.id, provider),
          ),
        );
      },
    );
  }

  void _confirmRemove(String studentId, MessProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student?'),
        content: const Text('Are you sure you want to remove this student from your mess?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.removeStudent(studentId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student removed.')));
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
