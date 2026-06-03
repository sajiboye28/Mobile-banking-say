import 'package:flutter/material.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class SubmitTicketScreen extends StatefulWidget {
  final String uid;
  final String userName;
  final String userEmail;
  const SubmitTicketScreen(
      {super.key,
      required this.uid,
      required this.userName,
      required this.userEmail});

  @override
  State<SubmitTicketScreen> createState() => _SubmitTicketScreenState();
}

class _SubmitTicketScreenState extends State<SubmitTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Account';
  bool _isLoading = false;

  final _categories = [
    'Account',
    'Transaction',
    'Technical',
    'Security',
    'Other'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await PbService.instance.pb.collection('support_tickets').create(body: {
        'userId': widget.uid,
        'userName': widget.userName,
        'userEmail': widget.userEmail,
        'subject': _subjectController.text.trim(),
        'category': _category,
        'message': _descriptionController.text.trim(),
        'status': 'open',
        'priority': 'medium',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Ticket submitted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to submit ticket'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Submit Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subject
                    _label('Subject'),
                    TextFormField(
                      controller: _subjectController,
                      style:
                          const TextStyle(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Brief description of your issue',
                        prefixIcon: const Icon(
                            Icons.title_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Category
                    _label('Category'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceContainerHigh,
                          style: const TextStyle(
                              color: AppColors.onSurface, fontSize: 14),
                          icon: const Icon(Icons.expand_more_rounded,
                              color: AppColors.onSurfaceVariant),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _label('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      style:
                          const TextStyle(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'Describe your issue in detail...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    GestureDetector(
                      onTap: _isLoading ? null : _submit,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Text(
                                  'Submit Ticket',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );
}
