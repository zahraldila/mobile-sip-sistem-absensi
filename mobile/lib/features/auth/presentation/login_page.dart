import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await AuthState.instance.login(
      identifier: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      _showSnackbar('Username atau Password salah.');
      return;
    }

    context.go(AuthState.instance.redirectLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Selamat Datang!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/logo awal.png',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 200,
                      width: 260,
                      child: CustomPaint(
                        painter: _LoginIllustrationPainter(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C0F172A),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Log in',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mohon login untuk melanjutkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan email anda disini',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan password',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF64748B),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF64748B),
                                            width: 1.5,
                                          ),
                                          activeColor: const Color(0xFF2563EB),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ingat Saya',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _showSnackbar(
                                        'Silakan hubungi IT Support untuk reset kata sandi.');
                                  },
                                  child: Text(
                                    'Lupa Kata Sandi?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2F70F2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: const Color(0xFF93C5FD),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Log In',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                  children: [
                                    const TextSpan(text: 'Butuh bantuan akses? '),
                                    TextSpan(
                                      text: 'Hubungi IT Support',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginIllustrationPainter extends CustomPainter {
  const _LoginIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 270.0;
    canvas.save();
    canvas.scale(scale);

    // 1. Soft puddle/cloud splash at the bottom
    final puddlePaint1 = Paint()
      ..color = const Color(0xFFE5F0FC)
      ..style = PaintingStyle.fill;
    final puddlePath1 = Path()
      ..moveTo(90, 160)
      ..cubicTo(70, 175, 100, 195, 140, 190)
      ..cubicTo(160, 188, 170, 175, 160, 162)
      ..close();
    canvas.drawPath(puddlePath1, puddlePaint1);

    final puddlePaint2 = Paint()
      ..color = const Color(0xFFD6E7FA)
      ..style = PaintingStyle.fill;
    final puddlePath2 = Path()
      ..moveTo(105, 175)
      ..cubicTo(90, 185, 120, 205, 148, 198)
      ..cubicTo(160, 195, 155, 180, 135, 175)
      ..close();
    canvas.drawPath(puddlePath2, puddlePaint2);

    // Sparkles
    _drawSparkle(canvas, const Offset(92, 162), 6, const Color(0xFF93C5FD));
    _drawSparkle(canvas, const Offset(205, 150), 7, const Color(0xFF93C5FD));
    _drawSparkle(canvas, const Offset(215, 80), 8, const Color(0xFF93C5FD));

    // 2. Tablet Board Background
    final tabletRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 16, 175, 138),
      const Radius.circular(16),
    );
    final tabletFill = Paint()..color = const Color(0xFFF5F8FE);
    final tabletBorder = Paint()
      ..color = const Color(0xFFBAC8F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawRRect(tabletRect, tabletFill);
    canvas.drawRRect(tabletRect, tabletBorder);

    // Header divider line on tablet
    final linePaint = Paint()
      ..color = const Color(0xFFCBD7F7)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(38, 38), const Offset(209, 38), linePaint);

    // Top cards on tablet
    final cardBg = Paint()..color = const Color(0xFFE2EDFC);

    // Card 1 (with X mark)
    final card1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 22, 22, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(card1, cardBg);
    final xPaint = Paint()
      ..color = const Color(0xFFA5B4FC)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(54, 25), const Offset(60, 31), xPaint);
    canvas.drawLine(const Offset(60, 25), const Offset(54, 31), xPaint);

    // Card 2 (with waveform & clock)
    final card2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(74, 22, 42, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(card2, cardBg);
    final wavePaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final wavePath = Path()
      ..moveTo(78, 28)
      ..quadraticBezierTo(80, 25, 82, 28)
      ..quadraticBezierTo(84, 31, 86, 28)
      ..lineTo(92, 28);
    canvas.drawPath(wavePath, wavePaint);

    final clockPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(106, 28), 4, clockPaint);
    final clockHand = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(106, 28), const Offset(106, 25.5), clockHand);
    canvas.drawLine(const Offset(106, 28), const Offset(108, 28), clockHand);

    // Notification bell icon badge
    final bellBg = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(const Offset(136, 28), 9, bellBg);
    final bellPaint = Paint()..color = Colors.white;
    final bellPath = Path()
      ..moveTo(136, 23)
      ..cubicTo(133.5, 23, 133, 26, 132, 29)
      ..lineTo(140, 29)
      ..cubicTo(139, 26, 138.5, 23, 136, 23)
      ..close();
    canvas.drawPath(bellPath, bellPaint);
    canvas.drawCircle(const Offset(136, 30.5), 1.2, bellPaint);

    // Middle cards
    // Card with message envelope
    final msgCard = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 50, 48, 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(msgCard, cardBg);
    final msgHeader = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 50, 48, 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(msgHeader, Paint()..color = const Color(0xFF818CF8));
    final msgEnv = RRect.fromRectAndRadius(
      const Rect.fromLTWH(68, 60, 16, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(msgEnv, Paint()..color = Colors.white);
    final envLine = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(68, 60), const Offset(76, 65), envLine);
    canvas.drawLine(const Offset(84, 60), const Offset(76, 65), envLine);

    // Small cards
    final midCard2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(100, 50, 22, 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(midCard2, cardBg);
    canvas.drawCircle(const Offset(111, 61), 5, Paint()..color = const Color(0xFFBFDBFE));

    final botCard1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 80, 22, 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(botCard1, cardBg);

    // Checklist Clipboard
    final clipRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(92, 72, 42, 54),
      const Radius.circular(6),
    );
    canvas.drawRRect(clipRect, Paint()..color = const Color(0xFF93C5FD));
    final clipTop = RRect.fromRectAndRadius(
      const Rect.fromLTWH(104, 68, 18, 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(clipTop, Paint()..color = const Color(0xFF60A5FA));
    final clipPaper = RRect.fromRectAndRadius(
      const Rect.fromLTWH(95, 77, 36, 46),
      const Radius.circular(4),
    );
    canvas.drawRRect(clipPaper, Paint()..color = const Color(0xFFF8FAFC));

    final checkLinePaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = 92.0 + (i * 10);
      canvas.drawCircle(Offset(102, y), 2.5, Paint()..color = const Color(0xFF3B82F6));
      canvas.drawLine(Offset(108, y), Offset(124, y), checkLinePaint);
    }

    // 3. Sitting Character
    // Head & Hair
    final skinPaint = Paint()..color = const Color(0xFFFFD5C0);
    final hairPaint = Paint()..color = const Color(0xFF0F172A);

    // Neck
    canvas.drawRect(const Rect.fromLTWH(164, 58, 8, 10), skinPaint);

    // Head
    canvas.drawCircle(const Offset(168, 50), 12, skinPaint);

    // Hair path
    final hairPath = Path()
      ..moveTo(158, 48)
      ..cubicTo(158, 38, 172, 36, 178, 42)
      ..cubicTo(182, 45, 180, 52, 176, 52)
      ..cubicTo(174, 46, 166, 44, 160, 48)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Ear
    canvas.drawCircle(const Offset(160, 52), 3, skinPaint);

    // Face details
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(164, 49), const Offset(167, 50), eyePaint);
    final smilePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final smilePath = Path()
      ..moveTo(164, 54)
      ..quadraticBezierTo(166, 57, 170, 55);
    canvas.drawPath(smilePath, smilePaint);

    // Shirt & Torso
    final shirtPaint = Paint()..color = const Color(0xFF818CF8);
    final torsoPath = Path()
      ..moveTo(156, 68)
      ..lineTo(180, 68)
      ..lineTo(184, 98)
      ..lineTo(152, 98)
      ..close();
    canvas.drawPath(torsoPath, shirtPaint);

    // Tie
    final tiePaint = Paint()..color = const Color(0xFF000865);
    final tiePath = Path()
      ..moveTo(167, 68)
      ..lineTo(170, 68)
      ..lineTo(172, 88)
      ..lineTo(168.5, 93)
      ..lineTo(165, 88)
      ..close();
    canvas.drawPath(tiePath, tiePaint);

    // Dark Tablet held in hands
    final tabPaint = Paint()..color = const Color(0xFF000865);
    final heldTablet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(142, 62, 28, 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(heldTablet, tabPaint);

    // Arms
    final armPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(156, 70), const Offset(144, 74), armPaint);
    canvas.drawLine(const Offset(180, 70), const Offset(168, 74), armPaint);

    // Hands
    canvas.drawCircle(const Offset(143, 74), 4, skinPaint);
    canvas.drawCircle(const Offset(168, 74), 4, skinPaint);

    // Pants & Legs (Dark Navy)
    final pantsPaint = Paint()
      ..color = const Color(0xFF000865)
      ..style = PaintingStyle.fill;

    // Left leg (bent up)
    final leftLeg = Path()
      ..moveTo(148, 92)
      ..lineTo(124, 102)
      ..lineTo(128, 142)
      ..lineTo(142, 142)
      ..lineTo(140, 114)
      ..lineTo(156, 104)
      ..close();
    canvas.drawPath(leftLeg, pantsPaint);

    // Right leg (crossing down)
    final rightLeg = Path()
      ..moveTo(164, 94)
      ..lineTo(188, 118)
      ..lineTo(176, 158)
      ..lineTo(162, 156)
      ..lineTo(172, 122)
      ..lineTo(152, 104)
      ..close();
    canvas.drawPath(rightLeg, pantsPaint);

    // Shoes (Bright Yellow & Amber)
    final shoePaint = Paint()..color = const Color(0xFFFBBF24);
    final solePaint = Paint()..color = const Color(0xFFD97706);

    // Left Shoe
    final leftShoe = Path()
      ..moveTo(128, 140)
      ..lineTo(112, 144)
      ..lineTo(112, 152)
      ..lineTo(144, 152)
      ..lineTo(144, 140)
      ..close();
    canvas.drawPath(leftShoe, shoePaint);
    canvas.drawRect(const Rect.fromLTWH(112, 149, 32, 4), solePaint);

    // Right Shoe
    final rightShoe = Path()
      ..moveTo(162, 154)
      ..lineTo(154, 168)
      ..lineTo(164, 174)
      ..lineTo(188, 160)
      ..lineTo(176, 152)
      ..close();
    canvas.drawPath(rightShoe, shoePaint);
    canvas.drawLine(
      const Offset(154, 168),
      const Offset(188, 160),
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
