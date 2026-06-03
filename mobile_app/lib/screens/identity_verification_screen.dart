import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

final String _kKycSubmitUrl = '$kApiBase/kyc/submit';
final String _kKycStatusUrl = '$kApiBase/kyc/status';

class IdentityVerificationScreen extends StatefulWidget {
  final String uid;

  const IdentityVerificationScreen({super.key, required this.uid});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> with TickerProviderStateMixin {
  // Step tracking
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;

  // Cloudinary
  static const String _cloudName = 'dnerpjzif';
  static const String _uploadPreset = 'profile_pictures';

  // Step 1 - Personal Information
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _nationality;
  bool _loadingUserData = true;

  // Step 2 - ID Document
  String? _selectedDocType;
  final _docNumberController = TextEditingController();
  DateTime? _docExpiryDate;
  Uint8List? _frontImageBytes;
  String? _frontImageUrl;
  Uint8List? _backImageBytes;
  String? _backImageUrl;
  bool _uploadingFront = false;
  bool _uploadingBack = false;

  // Step 3 - Selfie
  Uint8List? _selfieBytes;
  String? _selfieUrl;
  bool _uploadingSelfie = false;

  // Step 4 - Review & Submit
  bool _termsAccepted = false;
  bool _isSubmitting = false;

  // KYC status check
  bool _checkingKyc = true;
  Map<String, dynamic>? _existingKyc;

  static const List<String> _nationalities = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'South Korea',
    'India',
    'Brazil',
    'Nigeria',
    'South Africa',
    'Mexico',
    'Italy',
    'Spain',
    'Netherlands',
    'Singapore',
    'United Arab Emirates',
    'Saudi Arabia',
    'China',
  ];

  static const List<Map<String, dynamic>> _documentTypes = [
    {
      'type': 'Passport',
      'icon': Icons.menu_book_rounded,
      'desc': 'Biometric or standard passport',
    },
    {
      'type': "Driver's License",
      'icon': Icons.directions_car_rounded,
      'desc': 'Valid driving license with photo',
    },
    {
      'type': 'National ID',
      'icon': Icons.credit_card_rounded,
      'desc': 'Government-issued identity card',
    },
  ];

  static const List<Map<String, String>> _stepLabels = [
    {'label': 'Personal Info', 'icon': 'person'},
    {'label': 'ID Document', 'icon': 'id'},
    {'label': 'Selfie', 'icon': 'selfie'},
    {'label': 'Review', 'icon': 'review'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _updateProgressAnimation(0);
    _checkExistingKyc();
  }

  void _updateProgressAnimation(int step) {
    final double begin = _progressAnimController.value;
    final double end = (step + 1) / 4;
    _progressAnimation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut),
    );
    _progressAnimController.forward(from: 0);
  }

  // Returns the current auth token, or throws if not signed in.
  String _getToken() {
    final token = PbService.instance.authToken;
    if (token == null || token.isEmpty) throw Exception('Not signed in. Please log in again.');
    return token;
  }

  Future<void> _checkExistingKyc() async {
    try {
      final token = _getToken();
      final response = await http.get(
        Uri.parse(_kKycStatusUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final kyc = body['kyc'] as Map<String, dynamic>?;
        final profile = body['profile'] as Map<String, dynamic>? ?? {};

        // Pre-fill name from profile
        final name = profile['fullName'] as String? ?? '';
        if (name.isNotEmpty) _nameController.text = name;
        setState(() => _loadingUserData = false);

        if (kyc != null) {
          setState(() {
            _existingKyc = kyc;
            _checkingKyc = false;
          });
        } else {
          setState(() => _checkingKyc = false);
        }
      } else {
        // Non-200 — just let them fill the form
        setState(() {
          _checkingKyc = false;
          _loadingUserData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingKyc = false;
          _loadingUserData = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    // No-op: user data is now loaded inside _checkExistingKyc via /api/kyc/status
    if (mounted) setState(() => _loadingUserData = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 3) return;
    setState(() => _currentStep = step);
    _updateProgressAnimation(step);
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _nextStep() {
    if (_currentStep < 3) _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  // ─── Cloudinary Upload ───────────────────────────────────────────────────

  Future<String?> _uploadToCloudinary(Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: filename));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Image Picking ────────────────────────────────────────────────────────

  Future<void> _pickFrontImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _uploadingFront = true);
    final bytes = await xfile.readAsBytes();
    final url =
        await _uploadToCloudinary(bytes, 'kyc_front_${widget.uid}.jpg');
    setState(() {
      _frontImageBytes = bytes;
      _frontImageUrl = url;
      _uploadingFront = false;
    });
  }

  Future<void> _pickBackImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _uploadingBack = true);
    final bytes = await xfile.readAsBytes();
    final url =
        await _uploadToCloudinary(bytes, 'kyc_back_${widget.uid}.jpg');
    setState(() {
      _backImageBytes = bytes;
      _backImageUrl = url;
      _uploadingBack = false;
    });
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _uploadingSelfie = true);
    final bytes = await xfile.readAsBytes();
    final url =
        await _uploadToCloudinary(bytes, 'kyc_selfie_${widget.uid}.jpg');
    setState(() {
      _selfieBytes = bytes;
      _selfieUrl = url;
      _uploadingSelfie = false;
    });
  }

  // ─── Date Pickers ─────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 16),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryContainer,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _docExpiryDate ?? DateTime(now.year + 2),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryContainer,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _docExpiryDate = picked);
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submitVerification() async {
    if (!_termsAccepted) {
      _showError('Please confirm the information is accurate.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // ── Submit via Admin API ──────────────────────────────────────────────
      final token = _getToken();

      final payload = {
        'fullName': _nameController.text.trim(),
        'documentType': _selectedDocType,
        'documentNumber': _docNumberController.text.trim(),
        'documentExpiry': _docExpiryDate?.toIso8601String(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'nationality': _nationality,
        'address': _addressController.text.trim(),
        'documentFrontUrl': _frontImageUrl,
        'documentBackUrl': _backImageUrl,
        'selfieUrl': _selfieUrl,
      };

      final response = await http.post(
        Uri.parse(_kKycSubmitUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(responseData['error'] ?? 'Submission failed');
      }
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _existingKyc = {
          'status': 'pending',
          'fullName': _nameController.text.trim(),
          'submittedAt': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Submission failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checkingKyc) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      );
    }

    // If KYC already submitted, show status screen
    if (_existingKyc != null) {
      return _buildStatusScreen(_existingKyc!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onSurface, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KYC Status Screen ────────────────────────────────────────────────────

  Widget _buildStatusScreen(Map<String, dynamic> kyc) {
    final status = (kyc['status'] as String? ?? 'pending').toLowerCase();
    final submittedAt = kyc['submittedAt'];
    final rejectionReason =
        (kyc['rejectionReason'] as String? ?? '').trim();
    String dateStr = '';
    if (submittedAt is String) {
      final dt = DateTime.tryParse(submittedAt);
      if (dt != null) dateStr = DateFormat('MMM d, yyyy').format(dt);
    }

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    switch (status) {
      case 'approved':
      case 'verified':
        statusColor = AppColors.success;
        statusIcon = Icons.verified_rounded;
        statusTitle = 'Identity Verified';
        statusDesc =
            'Your identity has been verified successfully. You now have full access to all banking features.';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.warning_rounded;
        statusTitle = 'Verification Required';
        statusDesc = rejectionReason.isNotEmpty
            ? 'Your previous submission was rejected: $rejectionReason. Please resubmit with correct documents.'
            : 'Your verification was rejected. Please resubmit with correct documents.';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time_rounded;
        statusTitle = 'Under Review';
        statusDesc =
            'Your documents are under review by our team. This usually takes 1–3 business days.';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Rejection reason banner — shown prominently at top when rejected
            if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.error.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejection Reason',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rejectionReason,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 44),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusTitle.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            // Pending info card
            if (status == 'pending') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        color: AppColors.warning, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your documents are currently under review. You will be notified once the process is complete.',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Submitted: $dateStr',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 40),
            // Only show resubmit for rejected — approved and pending cannot resubmit
            if (status == 'rejected')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _existingKyc = null);
                  },
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text(
                    'Re-submit Verification',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (status == 'approved' || status == 'verified') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_open_rounded,
                        color: AppColors.success, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Full access to transfers, card creation, and all banking features is now enabled.',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Progress Header ──────────────────────────────────────────────────────

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerLow)),
      ),
      child: Column(
        children: [
          // Step labels row
          Row(
            children: List.generate(_stepLabels.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : isActive
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[i]['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimController,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryContainer),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Personal Information ─────────────────────────────────────────

  Widget _buildStep1() {
    if (_loadingUserData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information',
              style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Please provide your legal details as they appear on your ID.',
            style: TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          _buildLabel('Full Legal Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter your full legal name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          _buildLabel('Date of Birth'),
          const SizedBox(height: 8),
          _buildDatePickerField(
            date: _dateOfBirth,
            hint: 'Select your date of birth',
            onTap: _pickDob,
          ),
          const SizedBox(height: 20),
          _buildLabel('Nationality'),
          const SizedBox(height: 8),
          _buildNationalityDropdown(),
          const SizedBox(height: 20),
          _buildLabel('Residential Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressController,
            hint: 'Enter your full address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 36),
          _buildNavButtons(
            onNext: () {
              if (_nameController.text.trim().isEmpty) {
                _showError('Please enter your full legal name.');
                return;
              }
              if (_dateOfBirth == null) {
                _showError('Please select your date of birth.');
                return;
              }
              if (_nationality == null) {
                _showError('Please select your nationality.');
                return;
              }
              if (_addressController.text.trim().isEmpty) {
                _showError('Please enter your address.');
                return;
              }
              _nextStep();
            },
            showBack: false,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: ID Document ──────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ID Document',
              style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Select your document type and upload photos of it.',
            style: TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Document type selection
          _buildLabel('Document Type'),
          const SizedBox(height: 10),
          ..._documentTypes.map(_buildDocTypeCard),

          const SizedBox(height: 20),

          // Document number
          _buildLabel('Document Number'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _docNumberController,
            hint: 'Enter document number',
            icon: Icons.numbers_rounded,
          ),
          const SizedBox(height: 20),

          // Expiry date
          _buildLabel('Expiry Date'),
          const SizedBox(height: 8),
          _buildDatePickerField(
            date: _docExpiryDate,
            hint: 'Select expiry date',
            onTap: _pickExpiryDate,
          ),
          const SizedBox(height: 24),

          // Front photo
          _buildLabel('Front of Document'),
          const SizedBox(height: 8),
          _buildImageUploadBox(
            bytes: _frontImageBytes,
            isUploading: _uploadingFront,
            label: 'Upload Front',
            onTap: _pickFrontImage,
          ),
          const SizedBox(height: 16),

          // Back photo
          _buildLabel('Back of Document'),
          const SizedBox(height: 8),
          _buildImageUploadBox(
            bytes: _backImageBytes,
            isUploading: _uploadingBack,
            label: 'Upload Back',
            onTap: _pickBackImage,
          ),
          const SizedBox(height: 36),

          _buildNavButtons(
            onNext: () {
              if (_selectedDocType == null) {
                _showError('Please select a document type.');
                return;
              }
              if (_docNumberController.text.trim().isEmpty) {
                _showError('Please enter the document number.');
                return;
              }
              if (_docExpiryDate == null) {
                _showError('Please select the document expiry date.');
                return;
              }
              if (_frontImageBytes == null) {
                _showError('Please upload the front of your document.');
                return;
              }
              _nextStep();
            },
            onBack: _prevStep,
            showBack: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeCard(Map<String, dynamic> doc) {
    final bool isSelected = _selectedDocType == doc['type'];
    return GestureDetector(
      onTap: () => setState(() => _selectedDocType = doc['type'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLow,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withOpacity(0.15)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(doc['icon'] as IconData,
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc['type'] as String,
                      style: TextStyle(
                          color: isSelected
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(doc['desc'] as String,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primaryContainer
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadBox({
    required Uint8List? bytes,
    required bool isUploading,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: bytes != null
                ? AppColors.success.withOpacity(0.5)
                : AppColors.surfaceContainerHigh,
            width: 1.5,
          ),
        ),
        child: isUploading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryContainer, strokeWidth: 2.5),
              )
            : bytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(bytes,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Uploaded',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Change',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.onSurfaceVariant, size: 36),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('Tap to pick from gallery',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
      ),
    );
  }

  // ─── Step 3: Selfie ────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selfie Verification',
              style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Take a selfie or pick one from your gallery to verify your identity.',
            style: TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Selfie preview area
          GestureDetector(
            onTap: _uploadingSelfie ? null : _pickSelfie,
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selfieBytes != null
                      ? AppColors.success.withOpacity(0.5)
                      : AppColors.surfaceContainerHigh,
                  width: 1.5,
                ),
              ),
              child: _uploadingSelfie
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryContainer, strokeWidth: 2.5),
                    )
                  : _selfieBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.memory(_selfieBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Selfie Ready',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.face_rounded,
                                  color: AppColors.onSurfaceVariant, size: 40),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tap to select selfie',
                                style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            const Text('Pick from gallery',
                                style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 20),

          // Tips card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryContainer.withOpacity(0.12)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primaryContainer, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ensure your face is clearly visible, well-lit, and centered. Remove glasses or hats if possible.',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          if (_selfieBytes != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickSelfie,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retake Selfie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide(color: AppColors.surfaceContainerHigh),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 36),
          _buildNavButtons(
            onNext: () {
              if (_selfieBytes == null) {
                _showError('Please take or upload a selfie.');
                return;
              }
              _nextStep();
            },
            onBack: _prevStep,
            showBack: true,
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Review & Submit ───────────────────────────────────────────────

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Submit',
              style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Please review your information before submitting.',
            style: TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Personal info card
          _buildReviewSection('Personal Information', [
            _ReviewItem('Full Name', _nameController.text),
            _ReviewItem(
              'Date of Birth',
              _dateOfBirth != null
                  ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                  : 'Not provided',
            ),
            _ReviewItem('Nationality', _nationality ?? 'Not provided'),
            _ReviewItem('Address', _addressController.text),
          ]),
          const SizedBox(height: 14),

          // Document card
          _buildReviewSection('ID Document', [
            _ReviewItem('Type', _selectedDocType ?? 'Not selected'),
            _ReviewItem('Number', _docNumberController.text.isEmpty
                ? 'Not provided'
                : _docNumberController.text),
            _ReviewItem(
              'Expiry',
              _docExpiryDate != null
                  ? DateFormat('MMMM d, yyyy').format(_docExpiryDate!)
                  : 'Not provided',
            ),
          ]),
          const SizedBox(height: 14),

          // Photos summary
          _buildPhotosSummary(),
          const SizedBox(height: 24),

          // Terms checkbox
          GestureDetector(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _termsAccepted
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    border: Border.all(
                      color: _termsAccepted
                          ? AppColors.primaryContainer
                          : AppColors.onSurfaceVariant,
                      width: 1.5,
                    ),
                  ),
                  child: _termsAccepted
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'I confirm all information is accurate and the document provided is genuine and belongs to me.',
                    style: TextStyle(
                        color: AppColors.onSurface, fontSize: 14, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Submit Verification',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _prevStep,
              child: const Text('Go Back',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotosSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uploaded Photos',
              style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPhotoThumb('Front', _frontImageBytes),
              const SizedBox(width: 10),
              _buildPhotoThumb('Back', _backImageBytes),
              const SizedBox(width: 10),
              _buildPhotoThumb('Selfie', _selfieBytes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String label, Uint8List? bytes) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: bytes != null
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.surfaceContainerHigh,
              ),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(bytes, fit: BoxFit.cover,
                        width: double.infinity),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.onSurfaceVariant, size: 24),
                  ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<_ReviewItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerLow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final item = entry.value;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(item.label,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        item.value.isEmpty ? 'Not provided' : item.value,
                        style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Divider(
                    color: AppColors.onSurface.withOpacity(0.05),
                    height: 18,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.onSurface.withOpacity(0.25)),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: AppColors.onSurface.withOpacity(0.35), size: 20)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: maxLines > 1
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surfaceContainerLow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surfaceContainerLow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primaryContainer, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceContainerLow),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppColors.onSurface.withOpacity(0.35), size: 20),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? DateFormat('MMMM d, yyyy').format(date)
                  : hint,
              style: TextStyle(
                color: date != null
                    ? AppColors.onSurface
                    : AppColors.outlineVariant,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNationalityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerLow),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _nationality,
          hint: Text('Select nationality',
              style: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.25),
                  fontSize: 15)),
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurface.withOpacity(0.35)),
          style: const TextStyle(
              color: AppColors.onSurface, fontSize: 15),
          items: _nationalities.map((country) {
            return DropdownMenuItem(value: country, child: Text(country));
          }).toList(),
          onChanged: (val) => setState(() => _nationality = val),
        ),
      ),
    );
  }

  Widget _buildNavButtons({
    required VoidCallback onNext,
    VoidCallback? onBack,
    required bool showBack,
  }) {
    return Row(
      children: [
        if (showBack && onBack != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.surfaceContainerHigh),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Classes ────────────────────────────────────────────────────────────

class _ReviewItem {
  final String label;
  final String value;
  const _ReviewItem(this.label, this.value);
}
