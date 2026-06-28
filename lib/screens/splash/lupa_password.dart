import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_logo.dart';
import '../../services/auth_service.dart';

// ═══════════════════════════════════════════════════════════
// STEP ENUM
// ═══════════════════════════════════════════════════════════
enum ResetStep { inputEmail, verifyOtp, inputPassword }

class LupaPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LupaPasswordScreen({super.key, required this.onBack});

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen>
    with SingleTickerProviderStateMixin {
  // 🔥 CONTROLLERS
  final _loginController = TextEditingController();  // NISN/identifier
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 🔥 STATE
  ResetStep _currentStep = ResetStep.inputEmail;
  bool _isLoading = false;
  bool _isCheckingEmail = false; // realtime email check debounce
  String? _errorMessage;
  String? _successMessage;
  String? _emailStatus; // null | 'valid' | 'invalid'

  // OTP State
  bool _otpSent = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  Timer? _emailDebounce;

  // Password visibility
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 🔥 ANIMATIONS
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailDebounce?.cancel();
    _animController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 REALTIME EMAIL CHECK (DEBOUNCE 600ms)
  // ═══════════════════════════════════════════════════════════
  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (_emailStatus != null) setState(() => _emailStatus = null);
    if (value.isEmpty || _loginController.text.trim().isEmpty) return;

    _emailDebounce = Timer(const Duration(milliseconds: 600), () {
      _checkEmailBinding();
    });
  }

  Future<void> _checkEmailBinding() async {
    final login = _loginController.text.trim();
    final email = _emailController.text.trim();

    if (login.isEmpty || email.isEmpty) return;
    if (!email.contains('@')) return;

    setState(() => _isCheckingEmail = true);

    // Panggil send-otp untuk validasi email binding (backend cek otomatis)
    // Kita gunakan endpoint check-user dari ResetPasswordController
    // Backend akan return 403 jika email tidak cocok, 404 jika user tidak ada
    // Di sini kita hanya preview UI-nya saja tanpa kirim OTP
    // Real check terjadi saat tombol "Kirim OTP" ditekan
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isCheckingEmail = false;
        // Hanya tampilkan visual ready state
        _emailStatus = 'ready';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 STEP 1: KIRIM OTP
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleSendOtp() async {
    final login = _loginController.text.trim();
    final email = _emailController.text.trim();

    if (login.isEmpty) {
      setState(() => _errorMessage = 'Masukkan NISN / Identifier terlebih dahulu');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = email.isEmpty
            ? 'Email wajib diisi'
            : 'Masukkan email yang valid';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.sendOtp(login, email);

      if (!mounted) return;

      if (result != null && result['message'] == 'OTP berhasil dikirim') {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _currentStep = ResetStep.verifyOtp;
          _successMessage = 'Kode OTP dikirim ke $email';
          _errorMessage = null;
        });
        _startCountdown();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result?['message'] ?? 'Gagal mengirim OTP';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 STEP 2: VERIFIKASI OTP
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleVerifyOtp() async {
    final login = _loginController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.verifyOtp(login, otp);

      if (!mounted) return;

      if (result != null && result['message'] == 'OTP valid') {
        _countdownTimer?.cancel();
        setState(() {
          _isLoading = false;
          _currentStep = ResetStep.inputPassword;
          _successMessage = 'OTP terverifikasi! Buat password baru.';
          _errorMessage = null;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result?['message'] ?? 'OTP tidak valid atau sudah expired';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 STEP 3: RESET PASSWORD
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleResetPassword() async {
    final login = _loginController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.resetPassword(login, newPassword);

      if (!mounted) return;

      if (result != null && result['message'] == 'Password berhasil diubah') {
        HapticFeedback.heavyImpact();
        _showSuccessDialog();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result?['message'] ?? 'Gagal reset password';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Password Berhasil Diubah!',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login menggunakan password baru Anda.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onBack();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Kembali ke Login',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COUNTDOWN TIMER
  // ═══════════════════════════════════════════════════════════
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // STEP INDICATOR
  // ═══════════════════════════════════════════════════════════
  Widget _buildStepIndicator() {
    final steps = [
      {'label': 'Email', 'icon': Icons.email_outlined},
      {'label': 'Verifikasi', 'icon': Icons.confirmation_number_outlined},
      {'label': 'Password', 'icon': Icons.lock_outline_rounded},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isDone = _currentStep.index > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFE2E8F0),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = _currentStep.index == stepIndex;
        final isDone = _currentStep.index > stepIndex;

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF1D4ED8)
                : isActive
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isActive || isDone
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Icon(
                    steps[stepIndex]['icon'] as IconData,
                    size: 16,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                  ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ═══════════════════════════════════════════════════
                // HEADER BACK BUTTON
                // ═══════════════════════════════════════════════════
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════
                // LOGO SEKOLAH
                // ═══════════════════════════════════════════════════
                Hero(
                  tag: 'logo_sekolah',
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          const Color(0xFFF1F5F9),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF1D4ED8).withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          AppLogo.appLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.school_rounded,
                              size: 32,
                              color: Color(0xFF1D4ED8),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Reset Password',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Ikuti langkah berikut untuk membuat password baru',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════
                // STEP INDICATOR
                // ═══════════════════════════════════════════════════
                _buildStepIndicator(),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════
                // ERROR / SUCCESS BANNER
                // ═══════════════════════════════════════════════════
                if (_errorMessage != null)
                  _buildBanner(
                    _errorMessage!,
                    isError: true,
                  ),
                if (_successMessage != null)
                  _buildBanner(
                    _successMessage!,
                    isError: false,
                  ),

                // ═══════════════════════════════════════════════════
                // KONTEN STEP
                // ═══════════════════════════════════════════════════
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD STEP CONTENT
  // ═══════════════════════════════════════════════════════════
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ResetStep.inputEmail:
        return _buildStepEmail();
      case ResetStep.verifyOtp:
        return _buildStepOtp();
      case ResetStep.inputPassword:
        return _buildStepPassword();
    }
  }

  // ─────────────────────────────────────────────
  // STEP 1: INPUT EMAIL + KIRIM OTP
  // ─────────────────────────────────────────────
  Widget _buildStepEmail() {
    return Column(
      key: const ValueKey('step_email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NISN / Identifier
        _buildTextField(
          controller: _loginController,
          label: 'NISN / Identifier',
          hint: 'Masukkan NISN Anda',
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(20),
          ],
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),

        const SizedBox(height: 12),

        // EMAIL dengan realtime indicator
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Terdaftar',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) {
                _onEmailChanged(val);
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'nama@smkn8medan.sch.id',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _isCheckingEmail
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      )
                    : _emailStatus == 'ready'
                        ? const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: Color(0xFF22C55E),
                          )
                        : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _emailStatus == 'ready'
                        ? const Color(0xFF22C55E).withOpacity(0.5)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1D4ED8),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // TOMBOL KIRIM OTP
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _buildPrimaryButton(
            label: 'Kirim OTP ke Email',
            isLoading: _isLoading,
            onTap: _handleSendOtp,
            icon: Icons.send_rounded,
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: VERIFIKASI OTP
  // ─────────────────────────────────────────────
  Widget _buildStepOtp() {
    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFO EMAIL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF86EFAC),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: Color(0xFF16A34A),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'OTP dikirim ke ${_emailController.text.trim()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // OTP INPUT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kode OTP (6 digit)',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D4ED8),
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFCBD5E1),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1D4ED8),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // RESEND OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdown > 0
                  ? 'Kirim ulang dalam '
                  : 'Tidak menerima kode? ',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
            if (_countdown > 0)
              Text(
                '${_countdown}s',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D4ED8),
                ),
              )
            else
              GestureDetector(
                onTap: _isLoading ? null : _handleSendOtp,
                child: Text(
                  'Kirim Ulang',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // TOMBOL VERIFIKASI
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _buildPrimaryButton(
            label: 'Verifikasi OTP',
            isLoading: _isLoading,
            onTap: _handleVerifyOtp,
            icon: Icons.verified_outlined,
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 3: INPUT PASSWORD BARU
  // ─────────────────────────────────────────────
  Widget _buildStepPassword() {
    return Column(
      key: const ValueKey('step_password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFO
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF93C5FD),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF1D4ED8),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Identitas terverifikasi. Buat password baru untuk akun ${_loginController.text.trim()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // PASSWORD BARU
        _buildPasswordField(
          controller: _newPasswordController,
          label: 'Password Baru',
          hint: 'Minimal 6 karakter',
          isVisible: _isNewPasswordVisible,
          onToggle: () =>
              setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
        ),

        const SizedBox(height: 12),

        // KONFIRMASI PASSWORD
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: 'Ulangi password baru',
          isVisible: _isConfirmPasswordVisible,
          onToggle: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),

        const SizedBox(height: 12),

        // PANDUAN KEAMANAN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1D4ED8).withOpacity(0.05),
                const Color(0xFF3B82F6).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1D4ED8).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Panduan Keamanan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildGuideItem('Minimal 6 karakter'),
              _buildGuideItem('Kombinasi huruf & angka'),
              _buildGuideItem('Hindari password mudah ditebak'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // TOMBOL GANTI PASSWORD
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _buildPrimaryButton(
            label: 'Ganti Password',
            isLoading: _isLoading,
            onTap: _handleResetPassword,
            icon: Icons.lock_reset_rounded,
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildBanner(String message, {required bool isError}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 18,
              color: const Color(0xFF64748B),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1D4ED8),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            suffixIcon: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  key: ValueKey<bool>(isVisible),
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1D4ED8),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}