import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../models/models.dart';
import 'student_home_screen.dart';

class JoinMessScreen extends StatefulWidget {
  const JoinMessScreen({super.key});

  @override
  State<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends State<JoinMessScreen> {
  final _messIdSearchController = TextEditingController();
  final _transactionIdController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  Mess? _searchedMess;
  String _paymentMode = 'Online';

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
          _statusMessage = 'Your previous request to join mess was rejected. Try searching a different mess.';
        });
      } else if (latest.status == 'approved') {
        _refreshUserAndNavigate();
      }
    }
  }

  Future<void> _searchMess() async {
    final messId = _messIdSearchController.text.trim();
    if (messId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchedMess = null;
    });

    final messProvider = Provider.of<MessProvider>(context, listen: false);
    final mess = await messProvider.getMessById(messId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (mess != null) {
          _searchedMess = mess;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${messProvider.lastError ?? "Not found"}'), duration: const Duration(seconds: 10)),
          );
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_searchedMess == null) return;

    setState(() => _isLoading = true);

    final messProvider = Provider.of<MessProvider>(context, listen: false);
    final success = await messProvider.sendJoinRequest(
      _searchedMess!.id, 
      _paymentMode, 
      _paymentMode == 'Online' ? _transactionIdController.text.trim() : ''
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _statusMessage = 'Request sent to ${_searchedMess!.messName}! Please wait for admin approval.';
          _searchedMess = null;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send request.')),
          );
        }
      });
    }
  }

  Future<void> _refreshUserAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser(); 
    if (!mounted) return;
    
    if (authProvider.currentUser != null && authProvider.currentUser!.messId.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still pending approval or not joined yet.')),
      );
    }
  }

  @override
  void dispose() {
    _messIdSearchController.dispose();
    _transactionIdController.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_statusMessage!, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _statusMessage = null;
                        });
                      },
                      child: const Text('Try Another Mess'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Icon(Icons.apartment, size: 60, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Find Your Mess',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the Mess ID provided by your mess admin to make payment and request to join.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messIdSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Mess ID (e.g. MS1234)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _searchMess,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.arrow_forward),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (_searchedMess != null) ...[
              // Mess Details Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _searchedMess!.messName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Rs. ${_searchedMess!.monthlyFee}/mo',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.accent,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('📍 ${_searchedMess!.address}', style: const TextStyle(color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text(_searchedMess!.description, style: const TextStyle(color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
              // Payment Options
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Online'),
                              value: 'Online',
                              groupValue: _paymentMode,
                              onChanged: (val) => setState(() => _paymentMode = val!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Cash (COD)'),
                              value: 'COD',
                              groupValue: _paymentMode,
                              onChanged: (val) => setState(() => _paymentMode = val!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      if (_paymentMode == 'Online') ...[
                        const SizedBox(height: 16),
                        if (_searchedMess!.qrCodeImage.isNotEmpty) ...[
                          const Text('Scan to Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _searchedMess!.qrCodeImage.contains(',') 
                                      ? Uri.parse(_searchedMess!.qrCodeImage).data!.contentAsBytes() 
                                      : Uri.parse('data:image/jpeg;base64,${_searchedMess!.qrCodeImage}').data!.contentAsBytes(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Center(child: Text('Invalid QR', style: TextStyle(color: Colors.red))),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _transactionIdController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Transaction ID',
                            prefixIcon: Icon(Icons.receipt_long),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Send Request Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !_isLoading ? _submitRequest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SEND JOIN REQUEST'),
                ),
              ),
            ],

            const SizedBox(height: 32),
            TextButton(
              onPressed: _refreshUserAndNavigate,
              child: const Text('I have been approved (Refresh)'),
            ),
          ],
        ),
      ),
    );
  }
}
