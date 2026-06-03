import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/models/user_model.dart';
import 'package:real_banking/services/auth_service.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/screens/settings_screen.dart';
import 'package:real_banking/screens/card_management_screen.dart';
import 'package:real_banking/screens/identity_verification_screen.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';

const _kCloudinaryCloud = 'dnerpjzif';
const _kCloudinaryPreset = 'profile_pictures';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  // Edit controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // State flags
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  // Editable personal info fields
  bool _editingName = false;
  bool _editingPhone = false;
  bool _editingAddress = false;
  DateTime? _selectedDob;

  // Stats loaded from PocketBase
  int _totalTransactions = 0;
  double _totalSent = 0;
  double _totalReceived = 0;
  int _linkedCardsCount = 0;
  bool _statsLoaded = false;

  // User record state
  RecordModel? _userRecord;
  bool _userLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _userLoading = true);
    try {
      final record = await PbService.instance.pb.collection('users').getOne(widget.uid);
      if (mounted) setState(() { _userRecord = record; _userLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _userLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final pb = PbService.instance.pb;
      // Load transaction stats
      final txRecords = await pb.collection('transactions')
          .getFullList(filter: 'userId="${widget.uid}"');

      int total = 0;
      double sent = 0;
      double received = 0;

      for (final r in txRecords) {
        final data = r.data;
        final amount = (data['amount'] ?? 0).toDouble();
        final isCredit = data['isCredit'] == true ||
            data['type'] == 'credit' ||
            data['type'] == 'Credit';
        final status = (data['status'] ?? '').toString();
        if (status == 'Failed') continue;
        total++;
        if (isCredit) {
          received += amount;
        } else {
          sent += amount;
        }
      }

      // Load virtual cards count
      final cardRecords = await pb.collection('virtual_cards')
          .getFullList(filter: 'userId="${widget.uid}"');

      if (mounted) {
        setState(() {
          _totalTransactions = total;
          _totalSent = sent;
          _totalReceived = received;
          _linkedCardsCount = cardRecords.length;
          _statsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  // ─── Photo upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_kCloudinaryCloud/image/upload');
      final imageBytes = await picked.readAsBytes();
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _kCloudinaryPreset
        ..fields['folder'] = 'profile_pictures'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: picked.name,
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.statusCode}');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final imageUrl = data['secure_url'] as String;

      await PbService.instance.pb.collection('users')
          .update(widget.uid, body: {'profilePicUrl': imageUrl});
      _loadUser();

      if (mounted) _showSnack('Profile photo updated', success: true);
    } catch (e) {
      if (mounted) _showSnack('Failed to upload photo', success: false);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ─── Save personal info ────────────────────────────────────────────────────
  Future<void> _saveField(
      String field, String value, VoidCallback onDone) async {
    if (value.trim().isEmpty) {
      onDone();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final update = <String, dynamic>{field: value.trim()};
      if (field == 'dateOfBirth' && _selectedDob != null) {
        update['dateOfBirth'] = _selectedDob!.toIso8601String();
      }
      await PbService.instance.pb.collection('users')
          .update(widget.uid, body: update);
      _loadUser();
      if (mounted) _showSnack('Saved', success: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to save', success: false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        onDone();
      }
    }
  }

  Future<void> _saveChanges(UserModel user) async {
    final Map<String, dynamic> updates = {};
    if (_nameController.text.trim().isNotEmpty &&
        _nameController.text.trim() != user.fullName) {
      updates['fullName'] = _nameController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      updates['phone'] = _phoneController.text.trim();
    }
    if (_addressController.text.trim().isNotEmpty) {
      updates['address'] = _addressController.text.trim();
    }
    if (_selectedDob != null) {
      updates['dateOfBirth'] = _selectedDob!.toIso8601String();
    }
    if (updates.isEmpty) {
      _showSnack('No changes to save', success: false);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await PbService.instance.pb.collection('users')
          .update(widget.uid, body: updates);
      _loadUser();
      if (mounted) _showSnack('Changes saved', success: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to save changes', success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _editingName = false;
          _editingPhone = false;
          _editingAddress = false;
        });
      }
    }
  }

  // ─── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out',
                style: TextStyle(
                    color: AppColors.onSurface, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _authService.signOut();
  }

  // ─── Close account ─────────────────────────────────────────────────────────
  Future<void> _confirmCloseAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Close Account',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Closing your account is permanent and cannot be undone. All data and funds will be affected. Please contact support before proceeding.',
          style: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Close Account',
                  style: TextStyle(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _showSnack(
          'Account closure requested. Our team will contact you within 24 hours.',
          success: true);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? AppColors.successDim : AppColors.errorContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack('$label copied', success: true);
  }

  // ─── DOB Picker ────────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryContainer,
            surface: AppColors.surfaceContainerHighest,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Builder(builder: (context) {
          if (_userLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryContainer, strokeWidth: 2.5),
            );
          }
          if (_userRecord == null) {
            return const Center(
              child: Text('Profile not found',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            );
          }
          {
            final user = UserModel.fromRecord(_userRecord!);
            final data = _userRecord!.data;
            final kycStatus =
                (data['kycStatus'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString();
            final address = (data['address'] ?? '').toString();
            final referralCode = widget.uid.length >= 6
                ? widget.uid
                    .substring(widget.uid.length - 6)
                    .toUpperCase()
                : widget.uid.toUpperCase();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _buildHeroHeader(context, user, kycStatus, data)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildAccountStatsRow(),
                        const SizedBox(height: 24),
                        _buildPersonalInfoSection(
                            user, phone, address, data['dateOfBirth'] as String?),
                        const SizedBox(height: 16),
                        _buildAccountInfoSection(user),
                        const SizedBox(height: 16),
                        _buildLinkedCardsSection(user),
                        const SizedBox(height: 16),
                        _buildReferralSection(referralCode),
                        const SizedBox(height: 16),
                        _buildSection(
                          label: 'SECURITY',
                          children: [
                            _buildInfoRow(
                              icon: Icons.swap_horiz_rounded,
                              iconColor: user.canTransact
                                  ? AppColors.success
                                  : AppColors.error,
                              title: 'Transaction Ability',
                              value: user.canTransact
                                  ? 'Enabled'
                                  : 'Disabled',
                              valueColor: user.canTransact
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            _buildInfoRow(
                              icon: Icons.pin_rounded,
                              iconColor: AppColors.primary,
                              title: 'TCC Code',
                              value: user.tccCode.isNotEmpty
                                  ? '•' * user.tccCode.length
                                  : 'Not set',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          label: 'PREFERENCES',
                          children: [
                            _buildNavRow(
                              icon: Icons.settings_rounded,
                              iconColor: AppColors.onSurfaceVariant,
                              title: 'Settings',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SettingsScreen(uid: widget.uid),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildSignOutButton(),
                        const SizedBox(height: 12),
                        _buildDangerZone(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // ─── Hero header ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader(
      BuildContext context, UserModel user, String kycStatus,
      Map<String, dynamic> rawData) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.onSurface,
                          size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 28),

              // Avatar with gradient ring border
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                  children: [
                    // Gradient ring
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryContainer,
                            AppColors.primary,
                            Color(0xFF7B61FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: user.profilePicUrl.isNotEmpty
                            ? Image.network(
                                user.profilePicUrl,
                                width: 102,
                                height: 102,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(user),
                              )
                            : _avatarFallback(user),
                      ),
                    ),
                    // Camera overlay
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.primaryContainer,
                            AppColors.primary,
                          ]),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceContainerLow,
                              width: 2),
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimaryFixed,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                size: 16,
                                color: AppColors.onPrimaryFixed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Name
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                user.email.isNotEmpty ? user.email : 'Guest Account',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Masked account number
              Text(
                'Acct ••••${(user.accountNumber ?? '').length >= 4 ? (user.accountNumber!).substring((user.accountNumber!).length - 4) : '----'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Member since row
              if (user.createdAt != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11,
                        color: AppColors.onSurfaceVariant.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(user.createdAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // KYC status card (4-state)
              _buildKycStatusCard(context, kycStatus, rawData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(UserModel user) {
    return Container(
      width: 102,
      height: 102,
      color: AppColors.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.onSecondaryContainer,
          fontSize: 42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── KYC Status Card (4-state) ─────────────────────────────────────────────
  Widget _buildKycStatusCard(
      BuildContext context, String kycStatus, Map<String, dynamic> rawData) {
    final rejectionReason =
        (rawData['rejectionReason'] ?? '').toString().trim();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData statusIcon;
    String badgeLabel;
    String subtitleText;
    Widget? trailingAction;

    switch (kycStatus) {
      case 'approved':
        bgColor = AppColors.success.withOpacity(0.10);
        borderColor = AppColors.success.withOpacity(0.30);
        iconColor = AppColors.success;
        statusIcon = Icons.verified_rounded;
        badgeLabel = 'Identity Verified';
        subtitleText = 'Your identity has been successfully verified.';
        trailingAction = null;
        break;
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.10);
        borderColor = AppColors.warning.withOpacity(0.30);
        iconColor = AppColors.warning;
        statusIcon = Icons.access_time_rounded;
        badgeLabel = 'Verification Pending';
        subtitleText = 'Your documents are under review.';
        trailingAction = null;
        break;
      case 'rejected':
        bgColor = AppColors.error.withOpacity(0.10);
        borderColor = AppColors.error.withOpacity(0.30);
        iconColor = AppColors.error;
        statusIcon = Icons.warning_rounded;
        badgeLabel = 'Verification Required';
        subtitleText = rejectionReason.isNotEmpty
            ? 'Your verification was rejected: $rejectionReason. Please resubmit.'
            : 'Your verification was rejected. Please resubmit.';
        trailingAction = GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IdentityVerificationScreen(uid: widget.uid),
            ),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.4), width: 1),
            ),
            child: Text(
              'Resubmit',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        break;
      default: // not_submitted or unknown
        bgColor = AppColors.surfaceContainerHigh.withOpacity(0.6);
        borderColor = AppColors.outlineVariant.withOpacity(0.4);
        iconColor = AppColors.onSurfaceVariant;
        statusIcon = Icons.shield_outlined;
        badgeLabel = 'Not Verified';
        subtitleText = 'Complete identity verification to unlock all features.';
        trailingAction = GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IdentityVerificationScreen(uid: widget.uid),
            ),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                AppColors.primaryContainer,
                AppColors.primary,
              ]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verify Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 12),
              ],
            ),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null) ...[
            const SizedBox(width: 8),
            trailingAction,
          ],
        ],
      ),
    );
  }

  // ─── Account Stats row ─────────────────────────────────────────────────────
  Widget _buildAccountStatsRow() {
    final currFmt = NumberFormat.compact(locale: 'en_US');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'ACTIVITY OVERVIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                label: 'Transactions',
                value: _statsLoaded
                    ? '$_totalTransactions'
                    : '—',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                label: 'Total Sent',
                value: _statsLoaded
                    ? '\$${currFmt.format(_totalSent)}'
                    : '\$0',
                icon: Icons.north_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                label: 'Received',
                value: _statsLoaded
                    ? '\$${currFmt.format(_totalReceived)}'
                    : '\$0',
                icon: Icons.south_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Personal Information section ─────────────────────────────────────────
  Widget _buildPersonalInfoSection(
      UserModel user, String phone, String address, String? dobRaw) {
    final dobParsed = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
    final dobStr = _selectedDob != null
        ? DateFormat('MMM d, yyyy').format(_selectedDob!)
        : dobParsed != null
            ? DateFormat('MMM d, yyyy').format(dobParsed)
            : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'PERSONAL INFORMATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Full Name
              _buildEditableRow(
                icon: Icons.person_rounded,
                iconColor: AppColors.primaryContainer,
                label: 'Full Name',
                isEditing: _editingName,
                displayValue: user.fullName,
                controller: _nameController,
                onEditTap: () {
                  _nameController.text = user.fullName;
                  setState(() => _editingName = true);
                },
                onSaveTap: () =>
                    _saveField('fullName', _nameController.text, () {
                  setState(() => _editingName = false);
                }),
                onCancelTap: () => setState(() => _editingName = false),
              ),
              _buildDivider(),

              // Phone
              _buildEditableRow(
                icon: Icons.phone_rounded,
                iconColor: AppColors.success,
                label: 'Phone Number',
                isEditing: _editingPhone,
                displayValue: phone.isNotEmpty ? phone : 'Not set',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onEditTap: () {
                  _phoneController.text = phone;
                  setState(() => _editingPhone = true);
                },
                onSaveTap: () =>
                    _saveField('phone', _phoneController.text, () {
                  setState(() => _editingPhone = false);
                }),
                onCancelTap: () => setState(() => _editingPhone = false),
              ),
              _buildDivider(),

              // Date of Birth
              _buildDateOfBirthRow(dobStr),
              _buildDivider(),

              // Address
              _buildEditableRow(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.warning,
                label: 'Address',
                isEditing: _editingAddress,
                displayValue: address.isNotEmpty ? address : 'Not set',
                controller: _addressController,
                maxLines: 2,
                onEditTap: () {
                  _addressController.text = address;
                  setState(() => _editingAddress = true);
                },
                onSaveTap: () =>
                    _saveField('address', _addressController.text, () {
                  setState(() => _editingAddress = false);
                }),
                onCancelTap: () =>
                    setState(() => _editingAddress = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Save Changes button
        if (_editingName || _editingPhone || _editingAddress ||
            _selectedDob != null)
          GestureDetector(
            onTap: _isSaving
                ? null
                : () async {
                    if (_userRecord != null) {
                      _saveChanges(UserModel.fromRecord(_userRecord!));
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  AppColors.primaryContainer,
                  AppColors.primary,
                ]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.save_rounded,
                        color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isEditing,
    required String displayValue,
    required TextEditingController controller,
    required VoidCallback onEditTap,
    required VoidCallback onSaveTap,
    required VoidCallback onCancelTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(
                        color: AppColors.onSurfaceVariant
                            .withOpacity(0.6),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: displayValue == 'Not set'
                              ? AppColors.onSurfaceVariant
                                  .withOpacity(0.4)
                              : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          if (isEditing) ...[
            GestureDetector(
              onTap: onSaveTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onCancelTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 16),
              ),
            ),
          ] else
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.edit_rounded,
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    size: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthRow(String dobStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cake_rounded,
                color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dobStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dobStr == 'Not set'
                        ? AppColors.onSurfaceVariant.withOpacity(0.4)
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.edit_calendar_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  size: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Account Information section (read-only) ───────────────────────────────
  Widget _buildAccountInfoSection(UserModel user) {
    return _buildSection(
      label: 'ACCOUNT INFORMATION',
      children: [
        _buildInfoRow(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.primaryContainer,
          title: 'Account Type',
          value: user.accountTypeDisplay,
        ),
        _buildDivider(),
        _buildCopyableRow(
          icon: Icons.fingerprint_rounded,
          iconColor: AppColors.primary,
          title: 'Account Number',
          value: user.accountNumber ?? '',
          displayValue: user.accountNumber ?? 'N/A',
        ),
        _buildDivider(),
        _buildCopyableRow(
          icon: Icons.route_rounded,
          iconColor: AppColors.success,
          title: 'Routing Number',
          value: UserModel.routingNumber,
          displayValue: UserModel.routingNumber,
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.warning,
          title: 'Member Since',
          value: user.createdAt != null
              ? DateFormat('MMMM d, yyyy')
                  .format(user.createdAt!)
              : 'N/A',
        ),
      ],
    );
  }

  Widget _buildCopyableRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String displayValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.onSurfaceVariant.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value, title),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primaryContainer.withOpacity(0.2),
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded,
                      size: 12, color: AppColors.primaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Linked Cards section ──────────────────────────────────────────────────
  Widget _buildLinkedCardsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'VIRTUAL CARDS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: AppColors.primaryContainer, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Virtual Cards',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statsLoaded
                          ? '$_linkedCardsCount card${_linkedCardsCount == 1 ? '' : 's'} linked'
                          : 'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.onSurfaceVariant.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardManagementScreen(
                        uid: widget.uid, userName: user.fullName),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.primaryContainer,
                      AppColors.primary,
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Referral Code section ─────────────────────────────────────────────────
  Widget _buildReferralSection(String referralCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'REFERRAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.success.withOpacity(0.15), width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Referral Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Share with friends & earn rewards',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                      width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      referralCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _copyToClipboard(referralCode, 'Referral code'),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded,
                                color: AppColors.onSurface, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Copy Code',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final msg =
                            'Join me on STCU! Use my referral code: $referralCode to sign up and get started. Download the app at stcu.app';
                        Clipboard.setData(ClipboardData(text: msg));
                        _showSnack('Share message copied to clipboard',
                            success: true);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.success,
                            AppColors.successDim,
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Share',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Section ───────────────────────────────────────────────────────────────
  Widget _buildSection(
      {required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.outlineVariant.withOpacity(0.15),
      indent: 70,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.onSurfaceVariant.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Sign out button ───────────────────────────────────────────────────────
  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: _confirmSignOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.error.withOpacity(0.2), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Danger Zone ──────────────────────────────────────────────────────────
  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'DANGER ZONE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.error.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
        ),
        GestureDetector(
          onTap: _confirmCloseAccount,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dangerous_rounded,
                    color: AppColors.error.withOpacity(0.8), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Close Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
