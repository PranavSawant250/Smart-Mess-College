import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import 'student_home_screen.dart';

class JoinMessScreen extends StatefulWidget {
  const JoinMessScreen({super.key});

  @override
  State<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends State<JoinMessScreen> {
  final _messIdController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingRequest();
    });
  }

  Future<void> _checkExistingRequest() async {
    final messProvider = Provider.of<MessProvider>(context, listen: false);
    await messProvider.fetchMyRequests();
    if (!mounted) return;

    if (messProvider.myRequests.isNotEmpty) {
      final latest = messProvider.myRequests.last;
      if (latest.status == 'pending') {
        setState(() {
          _statusMessage = 'You have a pending request to join mess ${latest.messId}. Please wait for admin approval.';
        });
      } else if (latest.status == 'rejected') {
        setState(() {
          _statusMessage = 'Your previous request to join mess ${latest.messId} was rejected. Try a different mess.';
        });
      } else if (latest.status == 'approved') {
        _refreshUserAndNavigate();
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_messIdController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final messProvider = Provider.of<MessProvider>(context, listen: false);
    
    // Attempt to search for the mess by name to get its ID, or just send the ID directly if backend supports searching by ID.
    // In our backend `api/mess/join-request` expects `messId`. Since students type "messName", we should ideally use search.
    // But for simplicity, assuming they type the exact ObjectId or the backend resolves it:
    final success = await messProvider.sendJoinRequest(_messIdController.text.trim());
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _statusMessage = 'Request sent to ${_messIdController.text.trim()}! Please wait for admin approval.';
          _messIdController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request. Mess might not exist.')));
        }
      });
    }
  }

  Future<void> _refreshUserAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser(); // Refresh user data to get updated messId
    if (!mounted) return;
    
    if (authProvider.currentUser != null && authProvider.currentUser!.messId.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Still pending approval or not joined yet.')));
    }
  }

  @override
  void dispose() {
    _messIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Mess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/'); 
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.apartment, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Smart Mess',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to join a mess before you can start participating in polls and giving feedback.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 32),
              
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_statusMessage!, style: const TextStyle(color: AppColors.textDark)),
                      ),
                    ],
                  ),
                ),

              TextField(
                controller: _messIdController,
                decoration: const InputDecoration(
                  labelText: 'Mess ID',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitRequest(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('REQUEST TO JOIN'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _refreshUserAndNavigate,
                child: const Text('I have been approved (Refresh)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
