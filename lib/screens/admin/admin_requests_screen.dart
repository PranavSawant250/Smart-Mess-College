import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/mess_provider.dart';
import '../../models/models.dart';
import 'admin_student_profile_detail_screen.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedBranch;

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters(MessProvider provider) {
    provider.fetchStudents(
      search: _searchCtrl.text.trim(),
      branch: _selectedBranch,
    );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(req.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PENDING', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text('Email: ${req.userEmail}', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                if (req.userPhone.isNotEmpty)
                  Text('Phone: ${req.userPhone}', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminStudentProfileDetailScreen(
                                studentId: req.userId,
                                studentName: req.userName,
                                isPending: true,
                                requestId: req.id,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            provider.fetchAdminRequests();
                            provider.fetchStudents();
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('PREVIEW PROFILE & PAYMENT'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    )
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
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search by Name/Email/PRN',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => _applyFilters(provider),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedBranch,
                      decoration: const InputDecoration(labelText: 'Branch', prefixIcon: Icon(Icons.book)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Branches')),
                        DropdownMenuItem(value: 'CSE', child: Text('CSE')),
                        DropdownMenuItem(value: 'IT', child: Text('IT')),
                        DropdownMenuItem(value: 'ENTC', child: Text('ENTC')),
                        DropdownMenuItem(value: 'MECH', child: Text('MECH')),
                        DropdownMenuItem(value: 'CIVIL', child: Text('CIVIL')),
                        DropdownMenuItem(value: 'ELEC', child: Text('ELEC')),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedBranch = val);
                        _applyFilters(provider);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        
        // Student list
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? const Center(child: Text('No active students found.', style: TextStyle(color: AppColors.textLight)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${s.branch} • PRN: ${s.prn}\nID: ${s.messStudentId ?? "N/A"}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: AppColors.primary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminStudentProfileDetailScreen(
                                          studentId: s.id,
                                          studentName: s.name,
                                          isPending: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                  onPressed: () => _confirmRemove(s.id, provider),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminStudentProfileDetailScreen(
                                    studentId: s.id,
                                    studentName: s.name,
                                    isPending: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        )
      ],
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
                _applyFilters(provider);
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
