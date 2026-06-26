import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/auth_provider.dart';
import 'join_mess_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _hostelCtrl;
  String? _selectedBranch;
  String? _selectedPassoutYear;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _hostelCtrl = TextEditingController(text: user?.hostelName ?? '');
    _selectedBranch = user?.branch.isNotEmpty == true ? user?.branch : null;
    _selectedPassoutYear = user?.passoutYear.isNotEmpty == true ? user?.passoutYear : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _hostelCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      rollNumber: '', // Keep empty string for API compatibility
      branch: _selectedBranch ?? '',
      passoutYear: _selectedPassoutYear ?? '',
      hostelName: _hostelCtrl.text.trim(),
    );

    setState(() => _isSaving = false);
    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameCtrl.text = user.name;
                  _phoneCtrl.text = user.phone;
                  _hostelCtrl.text = user.hostelName;
                  _selectedBranch = user.branch.isNotEmpty ? user.branch : null;
                  _selectedPassoutYear = user.passoutYear.isNotEmpty ? user.passoutYear : null;
                });
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              
              if (_isEditing) ...[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedBranch,
                  decoration: const InputDecoration(labelText: 'Branch', prefixIcon: Icon(Icons.book)),
                  items: const [
                    DropdownMenuItem(value: 'CSE', child: Text('Computer Science (CSE)')),
                    DropdownMenuItem(value: 'IT', child: Text('Information Technology (IT)')),
                    DropdownMenuItem(value: 'ENTC', child: Text('Electronics & Telecommunication (ENTC)')),
                    DropdownMenuItem(value: 'MECH', child: Text('Mechanical (MECH)')),
                    DropdownMenuItem(value: 'CIVIL', child: Text('Civil (CIVIL)')),
                    DropdownMenuItem(value: 'ELEC', child: Text('Electrical (ELEC)')),
                  ],
                  onChanged: (val) => setState(() => _selectedBranch = val),
                  validator: (v) => v == null ? 'Select branch' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedPassoutYear,
                  decoration: const InputDecoration(labelText: 'Passout Year', prefixIcon: Icon(Icons.calendar_today)),
                  items: const [
                    DropdownMenuItem(value: '2026', child: Text('2026')),
                    DropdownMenuItem(value: '2027', child: Text('2027')),
                    DropdownMenuItem(value: '2028', child: Text('2028')),
                    DropdownMenuItem(value: '2029', child: Text('2029')),
                    DropdownMenuItem(value: '2030', child: Text('2030')),
                  ],
                  onChanged: (val) => setState(() => _selectedPassoutYear = val),
                  validator: (v) => v == null ? 'Select passout year' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hostelCtrl,
                  decoration: const InputDecoration(labelText: 'Hostel Name', prefixIcon: Icon(Icons.home)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter hostel name' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE CHANGES'),
                  ),
                ),
              ] else ...[
                _buildProfileItem(Icons.phone, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                _buildProfileItem(Icons.numbers, 'PRN (Non-Editable)', user.prn.isNotEmpty ? user.prn : 'Not provided'),
                _buildProfileItem(Icons.book, 'Branch', user.branch.isNotEmpty ? user.branch : 'Not provided'),
                _buildProfileItem(Icons.calendar_today, 'Passout Year', user.passoutYear.isNotEmpty ? user.passoutYear : 'Not provided'),
                _buildProfileItem(Icons.home, 'Hostel Name', user.hostelName.isNotEmpty ? user.hostelName : 'Not provided'),
                _buildProfileItem(Icons.apartment, 'Current Mess ID', user.messId.isNotEmpty ? user.messId : 'None'),
                _buildProfileItem(Icons.format_list_numbered, 'Mess Student ID', user.messStudentId != null ? user.messStudentId.toString() : 'Not Assigned'),
              ],
              
              const SizedBox(height: 40),
              if (!_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const JoinMessScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change Mess (Join Another)'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
